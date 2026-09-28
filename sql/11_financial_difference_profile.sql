-- 第十一关：使用条件聚合量化订单金额差异。
--
-- 本查询只分析商品金额和支付金额都存在的订单，因此使用 INNER JOIN。
-- 金额绝对差不超过 0.01 时视为匹配，避免浮点计算产生的微小误差。
--
-- 输出列：
-- comparable_orders  两边金额均存在、可以比较的订单数
-- matched_orders     差额绝对值不超过0.01的订单数
-- mismatched_orders  差额绝对值超过0.01的订单数
-- payment_higher     支付金额高出订单金额超过0.01的订单数
-- payment_lower      支付金额低于订单金额超过0.01的订单数
-- mismatch_rate_pct  差异订单占可比较订单的百分比
--
WITH item_summary AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS order_value
    FROM order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM order_payments
    GROUP BY order_id
),
reconciliation AS (
    SELECT
        o.order_id,
        p.payment_value - i.order_value AS amount_difference
    FROM orders AS o
    INNER JOIN item_summary AS i
        ON o.order_id = i.order_id
    INNER JOIN payment_summary AS p
        ON o.order_id = p.order_id
)
SELECT
    COUNT(*) AS comparable_orders,
    SUM(
        CASE WHEN ABS(amount_difference) <= 0.01 THEN 1 ELSE 0 END
    ) AS matched_orders,
    SUM(
        CASE WHEN ABS(amount_difference) > 0.01 THEN 1 ELSE 0 END
    ) AS mismatched_orders,
    SUM(
        CASE WHEN amount_difference > 0.01 THEN 1 ELSE 0 END
    ) AS payment_higher,
    SUM(
        CASE WHEN amount_difference < -0.01 THEN 1 ELSE 0 END
    ) AS payment_lower,
    ROUND(100.0 * SUM(
        CASE WHEN ABS(amount_difference) > 0.01 THEN 1 ELSE 0 END
    ) / COUNT(*), 2) AS mismatch_rate_pct
FROM reconciliation;
