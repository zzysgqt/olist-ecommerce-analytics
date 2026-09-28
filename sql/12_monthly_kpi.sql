-- 第十二关：月度经营指标。
--
-- 业务问题：平台每个月有多少有效订单、真实客户和售出商品，金额如何变化？
--
-- 本关口径：
-- 1. 月份按照 order_purchase_timestamp（下单时间）划分。
-- 2. 只把 order_status = 'delivered' 视为本次分析中的有效订单。
-- 3. 先把商品与支付分别汇总为“一笔订单一行”，再连接，避免金额膨胀。
-- 4. customer_unique_id 代表跨订单识别的真实客户。
-- 5. 输出保留全部月份用于数据覆盖审计；严格的月度趋势比较使用 2017-02 至 2018-07。
-- 6. AVG(payment_value) 会忽略 NULL；2016-09 有一笔已送达订单缺少支付记录。
--
-- SQLite 月份写法：
-- strftime('%Y-%m', order_purchase_timestamp)
-- 例如：2018-07-15 会得到 2018-07。
--
-- 最终输出列：
-- order_month          下单月份（一行代表一个自然月）
-- delivered_orders     最终送达的订单数
-- real_customers       去重后的真实客户数
-- items_sold           售出的商品明细件数
-- product_value        商品金额合计，不含运费
-- freight_value        运费合计
-- payment_value        客户实际支付金额合计
-- avg_payment_per_order 平均每笔有效订单的支付金额
--
-- 第一步：请先完成 item_summary。
-- 要求：一笔订单一行，计算 item_count、product_value、freight_value。
-- 可以参考 08_order_item_summary.sql，但 CTE 内不要保留 ORDER BY 和 LIMIT。

WITH item_summary AS (
    SELECT
    order_id,
    COUNT(*) AS item_count,
    ROUND(SUM(price), 2) AS product_value,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(price+freight_value), 2) AS order_value
    FROM order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT
    order_id,
    COUNT(*) AS payment_record_count,
    COUNT(DISTINCT payment_type) AS payment_type_count,
    ROUND(SUM(payment_value), 2) AS payment_value
    FROM order_payments
    GROUP BY order_id
),
order_level AS (
    SELECT
    o.order_id,
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
    c.customer_unique_id,
    i.item_count,
    i.product_value,
    i.freight_value,
    p.payment_value
    FROM orders AS o
    LEFT JOIN customers AS c
        ON o.customer_id=c.customer_id
    LEFT JOIN item_summary AS i
        ON o.order_id=i.order_id
    LEFT JOIN payment_summary AS p
        ON o.order_id=p.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    order_month,
    COUNT (*) AS delivered_orders,
    COUNT (DISTINCT customer_unique_id) AS real_customers,
    SUM (item_count) AS items_sold,
    ROUND (SUM(product_value),2) AS product_value,
    ROUND (SUM(freight_value),2) AS freight_value,
    ROUND (SUM(payment_value),2) AS payment_value,
    ROUND (AVG(payment_value),2) AS avg_payment_per_order
FROM order_level
GROUP BY order_month
ORDER BY order_month;
