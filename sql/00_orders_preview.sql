-- 第0关：先看数据长什么样，不做复杂计算。
-- 一行代表一笔订单。注意状态字段和五个时间字段。

SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
ORDER BY order_purchase_timestamp
LIMIT 10;
