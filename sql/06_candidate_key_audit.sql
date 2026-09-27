-- 第六关：检查各表的候选唯一键。
--
-- 候选唯一键：理论上能够唯一识别一行记录的一个字段或一组字段。
-- 如果 rows = distinct_keys，则本次数据中该候选键没有重复。
--
-- 输出列说明：
-- table_name     表名
-- candidate_key  本次接受检查的候选键
-- rows           表的总行数
-- distinct_keys  不同候选键的数量
-- duplicate_rows 总行数减去不同键数量；为0表示候选键没有重复

SELECT
    'orders' AS table_name,
    'order_id' AS candidate_key,
    COUNT(*) AS rows,
    COUNT(DISTINCT order_id) AS distinct_keys,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM orders

UNION ALL

SELECT
    'customers',
    'customer_id',
    COUNT(*),
    COUNT(DISTINCT customer_id),
    COUNT(*) - COUNT(DISTINCT customer_id)
FROM customers

UNION ALL

SELECT
    'order_items',
    'order_id + order_item_id',
    COUNT(*),
    COUNT(DISTINCT order_id || '|' || order_item_id),
    COUNT(*) - COUNT(DISTINCT order_id || '|' || order_item_id)
FROM order_items

UNION ALL

SELECT
    'order_payments',
    'order_id + payment_sequential',
    COUNT(*),
    COUNT(DISTINCT order_id || '|' || payment_sequential),
    COUNT(*) - COUNT(DISTINCT order_id || '|' || payment_sequential)
FROM order_payments

UNION ALL

SELECT
    'order_reviews',
    'review_id',
    COUNT(*),
    COUNT(DISTINCT review_id),
    COUNT(*) - COUNT(DISTINCT review_id)
FROM order_reviews

UNION ALL

SELECT
    'products',
    'product_id',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id)
FROM products

UNION ALL

SELECT
    'sellers',
    'seller_id',
    COUNT(*),
    COUNT(DISTINCT seller_id),
    COUNT(*) - COUNT(DISTINCT seller_id)
FROM sellers

UNION ALL

SELECT
    'category_translation',
    'product_category_name',
    COUNT(*),
    COUNT(DISTINCT product_category_name),
    COUNT(*) - COUNT(DISTINCT product_category_name)
FROM category_translation

ORDER BY duplicate_rows DESC, table_name;
