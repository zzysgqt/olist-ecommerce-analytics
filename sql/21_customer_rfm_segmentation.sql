-- RFM 客户分层。
--
-- 业务问题：综合最近购买时间、购买频次和累计金额，将客户划分为可运营的群体。
--
-- 评分原则：
-- 1. R 越近越好：recency_days 越小，R 分数越高。
-- 2. F 越高越好：frequency_orders 越大，F 分数越高。
-- 3. M 越高越好：monetary_value 越大，M 分数越高。
-- 4. 相同原始值应获得相同分数，避免 NTILE 把并列客户强行拆开。
-- 5. 约 97% 的客户只有一笔已送达订单，F 评分必须尊重这一实际分布。
-- 6. 涉及缺失支付记录的客户不参与完整 RFM 金额分层，但原始订单不删除。
--
-- 计划输出字段：
-- customer_unique_id 真实客户编号
-- recency_days       最近购买距快照日的天数
-- frequency_orders   已送达订单数
-- monetary_value     累计支付金额
-- r_score            最近购买评分
-- f_score            购买频次评分
-- m_score            累计金额评分
-- customer_segment   客户分层标签
--
-- 分层规则是根据本数据集频次高度偏斜的特点制定的运营启发式规则，
-- 并非通用行业标准；实际应用中应结合业务目标和实验结果迭代。

WITH payment_summary AS (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS payment_value
    FROM order_payments
    GROUP BY order_id
),
delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp AS purchase_at,
        p.payment_value
    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
    LEFT JOIN payment_summary AS p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
),
customer_rfm AS (
    SELECT
        customer_unique_id,
        CAST(
            julianday('2018-09-01')
            - julianday(DATE(MAX(purchase_at)))
            AS INTEGER
        ) AS recency_days,
        COUNT(*) AS frequency_orders,
        ROUND(SUM(payment_value), 2) AS monetary_value,
        SUM(
            CASE WHEN payment_value IS NULL
                 THEN 1 ELSE 0 END
        ) AS missing_payment_orders
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
),
complete_customer_rfm AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency_orders,
        monetary_value
    FROM customer_rfm
    WHERE missing_payment_orders = 0
),
frequency_scored AS (
    SELECT
        *,
        CASE
            WHEN frequency_orders = 1 THEN 1
            WHEN frequency_orders = 2 THEN 3
            ELSE 5
        END AS f_score
    FROM complete_customer_rfm
),
percentile_ranked AS (
    SELECT
        *,
        PERCENT_RANK() OVER (
            ORDER BY recency_days DESC
        ) AS r_percentile,
        PERCENT_RANK() OVER (
            ORDER BY monetary_value
        ) AS m_percentile
    FROM frequency_scored
),
rfm_scored AS (
    SELECT
        *,
        CASE
            WHEN r_percentile >= 0.8 THEN 5
            WHEN r_percentile >= 0.6 THEN 4
            WHEN r_percentile >= 0.4 THEN 3
            WHEN r_percentile >= 0.2 THEN 2
            ELSE 1
        END AS r_score,
        CASE
            WHEN m_percentile >= 0.8 THEN 5
            WHEN m_percentile >= 0.6 THEN 4
            WHEN m_percentile >= 0.4 THEN 3
            WHEN m_percentile >= 0.2 THEN 2
            ELSE 1
        END AS m_score
    FROM percentile_ranked
),
segmented_customers AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4
             AND f_score >= 3
             AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3
             AND f_score >= 3
                THEN 'Loyal Customers'
            WHEN r_score >= 4
             AND f_score = 1
             AND m_score >= 4
                THEN 'Recent High Spenders'
            WHEN r_score >= 4
             AND f_score = 1
                THEN 'Recent One-Time Buyers'
            WHEN r_score <= 2
             AND (f_score >= 3 OR m_score >= 4)
                THEN 'At Risk'
            WHEN r_score <= 2
             AND f_score = 1
                THEN 'Hibernating'
            ELSE 'Need Attention'
        END AS customer_segment
    FROM rfm_scored
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM segmented_customers),
        2
    ) AS customer_share_pct,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 2) AS avg_frequency_orders,
    ROUND(AVG(monetary_value), 2) AS avg_monetary_value,
    ROUND(SUM(monetary_value), 2) AS total_monetary_value
FROM segmented_customers
GROUP BY customer_segment
ORDER BY total_monetary_value DESC;
