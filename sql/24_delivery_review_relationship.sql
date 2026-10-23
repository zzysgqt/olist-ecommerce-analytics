-- 延迟交付程度与评价表现。
--
-- 业务问题：订单延迟送达是否与较低的评价分数同时出现？
--
-- 统计口径：
-- 1. 只分析 order_status = 'delivered' 的订单。
-- 2. 订单必须同时具有实际送达时间和预计送达时间，才能判断是否延迟。
-- 3. order_reviews 可能一笔订单多行，连接前先聚合到一单一行。
-- 4. 低评分定义为一笔订单的平均评价分数不超过 2 分。
-- 5. 延迟与低评分同时出现只说明相关关系，不直接证明因果。

WITH review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        ROUND(AVG(review_score), 2) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),
delivery_orders AS (
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        r.review_count,
        r.avg_review_score,
        ROUND(
            julianday(o.order_delivered_customer_date)
            - julianday(o.order_purchase_timestamp),
            2
        ) AS delivery_days,
        ROUND(
            julianday(o.order_delivered_customer_date)
            - julianday(o.order_estimated_delivery_date),
            2
        ) AS delay_days,
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
                THEN 1
            ELSE 0
        END AS is_late
    FROM orders AS o
    LEFT JOIN review_summary AS r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
delivery_bucketed AS (
    SELECT
        *,
        CASE
            WHEN is_late = 0 THEN 'On time'
            WHEN delay_days <= 3 THEN 'Up to 3 days late'
            WHEN delay_days <= 7 THEN '4-7 days late'
            WHEN delay_days <= 14 THEN '8-14 days late'
            ELSE '15+ days late'
        END AS delay_bucket,
        CASE
            WHEN is_late = 0 THEN 1
            WHEN delay_days <= 3 THEN 2
            WHEN delay_days <= 7 THEN 3
            WHEN delay_days <= 14 THEN 4
            ELSE 5
        END AS delay_bucket_order
    FROM delivery_orders
)
SELECT
    delay_bucket,
    COUNT(*) AS order_count,
    COUNT(avg_review_score) AS reviewed_order_count,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(delay_days), 2) AS avg_delay_days,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    SUM(
        CASE WHEN avg_review_score <= 2 THEN 1 ELSE 0 END
    ) AS low_review_orders,
    ROUND(
        100.0 * SUM(
            CASE WHEN avg_review_score <= 2 THEN 1 ELSE 0 END
        ) / COUNT(avg_review_score),
        2
    ) AS low_review_rate_pct
FROM delivery_bucketed
GROUP BY delay_bucket, delay_bucket_order
ORDER BY delay_bucket_order;

