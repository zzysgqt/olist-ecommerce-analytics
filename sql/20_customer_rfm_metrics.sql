-- 第二十关：客户 RFM 原始指标。
--
-- 业务问题：每位真实客户最近一次购买距分析日多久、购买多少次、累计支付多少？
--
-- RFM 含义：
-- R = Recency，距最近一次购买经过的天数，通常越小越好。
-- F = Frequency，观察窗口内的购买次数，通常越大越好。
-- M = Monetary，观察窗口内的累计支付金额，通常越大越好。
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 使用 customer_unique_id 识别真实客户。
-- 3. 使用每笔订单汇总后的 payment_value 作为客户实际支付金额。
-- 4. 分析快照日固定为 2018-09-01，不能使用今天的日期计算历史数据 Recency。
-- 5. 先把支付明细聚合到一笔订单一行，再与订单连接，避免多表连接膨胀。
-- 6. 暂时只计算原始指标，本关不急着给客户打分。
--
-- 计划输出字段：
-- customer_unique_id 真实客户编号
-- last_purchase_at   最近一次已送达订单的下单时间
-- recency_days       最近购买日至分析快照日的天数
-- frequency_orders   已送达订单数
-- monetary_value     已送达订单对应的累计支付金额
-- missing_payment_orders 缺少支付记录的已送达订单数
--
-- 请先完成概念练习，再开始编写 SQL。
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
        MAX(purchase_at) AS last_purchase_at,
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
)
SELECT
    COUNT(*) AS total_customers,
    SUM(
        CASE WHEN missing_payment_orders > 0
             THEN 1 ELSE 0 END
    ) AS customers_with_missing_payment,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(frequency_orders), 2) AS avg_frequency_orders,
    ROUND(
        AVG(
            CASE WHEN missing_payment_orders = 0
                 THEN monetary_value END
        ),
        2
    ) AS avg_monetary_value_complete_customers
FROM customer_rfm;


