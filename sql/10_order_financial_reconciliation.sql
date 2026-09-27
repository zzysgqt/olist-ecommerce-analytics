-- 第十关：连接订单、商品汇总和支付汇总，核对订单金额。
--
-- 最终粒度：一笔订单一行。
-- 本关保留 orders 中的全部订单，再用状态字段区分是否为已实现交易。
--
-- 输出列：
-- order_id             订单编号
-- order_status         订单状态
-- item_count           商品明细行数
-- product_value        商品金额合计
-- freight_value        运费合计
-- order_value          商品金额与运费之和
-- payment_record_count 支付记录数
-- max_installments     最大分期数
-- payment_value        支付金额合计
-- amount_difference    支付金额减去订单金额
--
-- 本查询不筛选状态；订单级底表保留所有状态，计算成交指标时再筛选 delivered。

WITH item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT product_id) AS product_count,
        COUNT(DISTINCT seller_id) AS seller_count,
        ROUND(SUM(price), 2) AS product_value,
        ROUND(SUM(freight_value), 2) AS freight_value,
        ROUND(SUM(price + freight_value), 2) AS order_value
    FROM order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT
        order_id,
        COUNT(*) AS payment_record_count,
        COUNT(DISTINCT payment_type) AS payment_type_count,
        MAX(payment_installments) AS max_installments,
        ROUND(SUM(payment_value), 2) AS payment_value
    FROM order_payments
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.order_status,
    i.item_count,
    i.product_value,
    i.freight_value,
    i.order_value,
    p.payment_record_count,
    p.max_installments,
    p.payment_value,
    ROUND(p.payment_value - i.order_value, 2) AS amount_difference
FROM orders AS o
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN payment_summary AS p
    ON o.order_id = p.order_id
ORDER BY ABS(amount_difference) DESC
LIMIT 20;
