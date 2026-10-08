-- 客户复购间隔分析。
--
-- 业务问题：产生复购的客户，两笔相邻已送达订单之间间隔多少天？
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 使用 customer_unique_id 识别真实客户。
-- 3. 按客户分区，并在每位客户内部按下单时间排序。
-- 4. 每位客户的第一笔订单没有上一笔订单，不属于复购间隔记录。
--
-- 计划输出字段：
-- customer_unique_id 真实客户编号
-- order_id           当前订单编号
-- purchase_at        当前订单下单时间
-- previous_purchase_at 同一客户上一笔订单的下单时间
-- repurchase_gap_days 两笔相邻订单之间的原始间隔天数
-- gap_bucket         复购间隔分组
-- interval_count     分组内的相邻订单间隔数
-- interval_share_pct 分组间隔数占全部间隔数的百分比
WITH delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp AS purchase_at
    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
customer_order_sequence AS (
    SELECT
        customer_unique_id,
        order_id,
        purchase_at,
        LAG(purchase_at) OVER (
            PARTITION BY customer_unique_id
            ORDER BY purchase_at
        ) AS previous_purchase_at
    FROM delivered_customer_orders
),
repurchase_intervals AS (
    SELECT
        customer_unique_id,
        order_id,
        purchase_at,
        previous_purchase_at,
        julianday(purchase_at)
            - julianday(previous_purchase_at) AS repurchase_gap_days
    FROM customer_order_sequence
    WHERE previous_purchase_at IS NOT NULL
)
SELECT
    CASE
        WHEN repurchase_gap_days < 1 THEN '<1 day'
        WHEN repurchase_gap_days <= 30 THEN '1-30 days'
        WHEN repurchase_gap_days <= 90 THEN '31-90 days'
        WHEN repurchase_gap_days <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END AS gap_bucket,
    COUNT(*) AS interval_count,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM repurchase_intervals),
        2
    ) AS interval_share_pct
FROM repurchase_intervals
GROUP BY gap_bucket
ORDER BY MIN(repurchase_gap_days);
