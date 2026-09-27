-- 第三关：比较核心表的数据粒度。
--
-- 输出列说明：
-- table_name                 表名
-- rows                       表的总行数
-- distinct_orders            表中不同订单号的数量
-- rows_beyond_one_per_order  每笔订单保留第一行后，剩余的明细行数
-- max_rows_in_one_order      同一订单在该表中最多占几行
--
-- 注意：rows_beyond_one_per_order 不等于“重复数据行”。
-- 在商品、支付和评价表中，多出来的行可能代表真实的不同商品、分拆支付或多条评价。

WITH table_grain AS (
    SELECT
        'orders' AS table_name,
        COUNT(*) AS rows,
        COUNT(DISTINCT order_id) AS distinct_orders,
        COUNT(*) - COUNT(DISTINCT order_id) AS rows_beyond_one_per_order,
        MAX(rows_per_order) AS max_rows_in_one_order
    FROM (
        SELECT order_id, COUNT(*) OVER (PARTITION BY order_id) AS rows_per_order
        FROM orders
    )

    UNION ALL

    SELECT
        'order_items',
        COUNT(*),
        COUNT(DISTINCT order_id),
        COUNT(*) - COUNT(DISTINCT order_id),
        MAX(rows_per_order)
    FROM (
        SELECT order_id, COUNT(*) OVER (PARTITION BY order_id) AS rows_per_order
        FROM order_items
    )

    UNION ALL

    SELECT
        'order_payments',
        COUNT(*),
        COUNT(DISTINCT order_id),
        COUNT(*) - COUNT(DISTINCT order_id),
        MAX(rows_per_order)
    FROM (
        SELECT order_id, COUNT(*) OVER (PARTITION BY order_id) AS rows_per_order
        FROM order_payments
    )

    UNION ALL

    SELECT
        'order_reviews',
        COUNT(*),
        COUNT(DISTINCT order_id),
        COUNT(*) - COUNT(DISTINCT order_id),
        MAX(rows_per_order)
    FROM (
        SELECT order_id, COUNT(*) OVER (PARTITION BY order_id) AS rows_per_order
        FROM order_reviews
    )
)
SELECT *
FROM table_grain
ORDER BY rows DESC;
