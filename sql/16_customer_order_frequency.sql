-- 第十六关：客户购买频次分布。
--
-- 业务问题：拥有已送达订单的真实客户分别购买了多少次？
--
-- 统计口径与第十五关一致：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 使用 customer_unique_id 识别真实客户。
-- 3. 先按客户计算订单数，再按订单数统计客户人数。
--
-- 最终输出列：
-- delivered_order_count 一位客户拥有的已送达订单数（购买频次）
-- customer_count        该购买频次对应的真实客户人数
-- customer_share_pct    该组客户占全部客户的百分比（第二步再计算）
--
-- 第一步：复制第十五关的 delivered_customer_orders 和 customer_summary 两个 CTE。
-- 然后按 delivered_order_count 分组，统计 customer_count。
-- 结果解读：四舍五入后显示为 0.00% 的组仍可能包含少量客户，不能视为零。
WITH delivered_customer_orders AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders AS o
    INNER JOIN customers AS c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
customer_summary AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS delivered_order_count,
        MIN(order_purchase_timestamp) AS first_purchase_at,
        MAX(order_purchase_timestamp) AS last_purchase_at
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
)
SELECT
    delivered_order_count,
    COUNT(*) AS customer_count,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM customer_summary),
        2
    ) AS customer_share_pct
FROM customer_summary
GROUP BY delivered_order_count
ORDER BY delivered_order_count;
