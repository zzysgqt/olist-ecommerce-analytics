-- 控制订单结构后的延迟交付与评价关系。
--
-- 业务问题：在订单复杂程度相近的组内，延迟订单是否仍伴随更低评分？
--
-- 统计口径：
-- 1. 只分析具有实际和预计送达时间的 delivered 订单。
-- 2. 评价表与商品表均先聚合到一笔订单一行，再连接订单表。
-- 3. 订单按单商品、多商品单卖家、多卖家三种结构分层。
-- 4. 分层比较用于减少订单结构的干扰，不构成因果识别。

WITH review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        ROUND(AVG(review_score), 2) AS avg_review_score
    FROM order_reviews
    GROUP BY order_id
),
item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT seller_id) AS seller_count
    FROM order_items
    GROUP BY order_id
),
delivery_orders AS (
    SELECT
        o.order_id,
        i.item_count,
        i.seller_count,
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
    INNER JOIN item_summary AS i
        ON o.order_id = i.order_id
    LEFT JOIN review_summary AS r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
),
order_structure AS (
    SELECT
        *,
        CASE
            WHEN item_count = 1 THEN 'Single item'
            WHEN seller_count = 1 THEN 'Multiple items, one seller'
            ELSE 'Multiple sellers'
        END AS structure_group,
        CASE
            WHEN item_count = 1 THEN 1
            WHEN seller_count = 1 THEN 2
            ELSE 3
        END AS structure_order
    FROM delivery_orders
)
SELECT
    structure_group,
    CASE
        WHEN is_late = 1 THEN 'Late'
        ELSE 'On time'
    END AS delivery_status,
    COUNT(*) AS order_count,
    COUNT(avg_review_score) AS reviewed_order_count,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
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
FROM order_structure
GROUP BY structure_group, structure_order, is_late
ORDER BY structure_order, is_late;

