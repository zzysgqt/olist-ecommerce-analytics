-- 第0关：先看数据长什么样，不做复杂计算。
-- 一行代表一笔订单。注意状态字段和五个时间字段。

SELECT
    SUBSTR(order_id, 1, 8) AS order_id_short,
    order_status,
    order_purchase_timestamp AS purchased_at,
    order_approved_at AS approved_at,
    order_delivered_carrier_date AS carrier_at,
    order_delivered_customer_date AS delivered_at,
    order_estimated_delivery_date AS estimated_at
FROM orders
ORDER BY order_purchase_timestamp
LIMIT 10;
