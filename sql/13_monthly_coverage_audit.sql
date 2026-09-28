-- 第十三关：审计月度数据覆盖范围。
--
-- 业务目的：月度数据量低不一定代表经营低迷，也可能只是当月只覆盖了几天。
-- 在解释趋势前，先检查每个月实际包含的日期范围和活跃天数。
--
-- 输出列：
-- order_month       下单月份
-- first_order_date  当月最早下单日期
-- last_order_date   当月最晚下单日期
-- active_days       当月出现已送达订单的不同日期数
-- delivered_orders  最终送达的订单数

SELECT
    strftime('%Y-%m', order_purchase_timestamp) AS order_month,
    MIN(date(order_purchase_timestamp)) AS first_order_date,
    MAX(date(order_purchase_timestamp)) AS last_order_date,
    COUNT(DISTINCT date(order_purchase_timestamp)) AS active_days,
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;
