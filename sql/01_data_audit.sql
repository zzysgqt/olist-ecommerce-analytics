-- 第一关：确认订单表的粒度、时间范围和状态分布。
--
-- 这条查询输出每种订单状态的订单数、客户数和购买日期范围。
-- 观察后请回答：
-- 1. 哪个状态占绝大多数？
-- 2. 数据覆盖的最早和最晚购买日期是什么？
-- 3. 分析“成交额”时，是否应该包含 canceled 和 unavailable？为什么？

SELECT
    order_status,
    COUNT(*) AS order_rows,
    COUNT(DISTINCT order_id) AS distinct_orders,
    COUNT(DISTINCT customer_id) AS distinct_customer_records,
    MIN(order_purchase_timestamp) AS first_purchase,
    MAX(order_purchase_timestamp) AS last_purchase
FROM orders
GROUP BY order_status
ORDER BY order_rows DESC;
