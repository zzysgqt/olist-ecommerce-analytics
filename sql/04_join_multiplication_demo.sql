-- 第四关：观察多对多连接造成的行数膨胀。
--
-- 输出列说明：
-- order_id_short       订单号前8位，仅用于方便展示
-- item_rows            该订单在商品明细表中的行数
-- payment_rows         该订单在支付表中的行数
-- rows_after_direct_join 直接按 order_id 连接两表后产生的行数
--
-- rows_after_direct_join = item_rows * payment_rows。
-- 这不是订单真的增加了，而是两组明细互相组合造成的结果。

WITH item_counts AS (
    SELECT
        order_id,
        COUNT(*) AS item_rows
    FROM order_items
    GROUP BY order_id
),
payment_counts AS (
    SELECT
        order_id,
        COUNT(*) AS payment_rows
    FROM order_payments
    GROUP BY order_id
)
SELECT
    SUBSTR(i.order_id, 1, 8) AS order_id_short,
    i.item_rows,
    p.payment_rows,
    i.item_rows * p.payment_rows AS rows_after_direct_join
FROM item_counts AS i
JOIN payment_counts AS p
    ON i.order_id = p.order_id
WHERE i.item_rows > 1
  AND p.payment_rows > 1
ORDER BY rows_after_direct_join DESC, i.order_id
LIMIT 10;
