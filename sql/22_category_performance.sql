-- 商品品类经营表现。
--
-- 业务问题：哪些品类贡献了更多订单、商品销售额和运费？
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. order_items 一行代表订单中的一个商品序号，不等于一种唯一商品。
-- 3. price 表示商品售价，freight_value 表示该商品行对应的运费。
-- 4. 本关的商品销售额使用 SUM(price)，不等同于客户支付总额。
-- 5. 商品表和翻译表使用 LEFT JOIN，以保留缺失商品或缺失品类记录供审计。
-- 6. 正式汇总前先检查商品、品类和翻译的连接覆盖率。
-- 7. 连接审计结果：110,197 个已送达商品行全部匹配商品表；
--    1,537 行缺少原始品类，22 行有原始品类但缺少英文翻译。
--
-- 计划输出字段：
-- category_name       英文商品品类；无法识别时标记为 Unknown
-- item_count          商品明细行数
-- order_count         包含该品类的不同订单数
-- product_count       不同商品数
-- seller_count        不同卖家数
-- product_value       商品售价合计
-- product_value_share_pct 品类商品售价占全部品类商品售价的百分比
-- freight_value       运费合计
-- avg_item_price      平均商品行售价
-- freight_share_pct   运费占商品售价与运费合计的百分比

WITH delivered_items AS (
    SELECT
        o.order_id,
        i.order_item_id,
        i.product_id,
        i.seller_id,
        i.price,
        i.freight_value,
        p.product_id AS matched_product_id,
        p.product_category_name,
        t.product_category_name_english AS category_name_english
    FROM orders AS o
    INNER JOIN order_items AS i
        ON o.order_id = i.order_id
    LEFT JOIN products AS p
        ON i.product_id = p.product_id
    LEFT JOIN category_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
),
categorized_items AS (
    SELECT
        *,
        CASE
            WHEN product_category_name IS NULL
                THEN 'Unknown'
            WHEN category_name_english IS NULL
                THEN 'Untranslated: ' || product_category_name
            ELSE category_name_english
        END AS category_name
    FROM delivered_items
)
SELECT
    category_name,
    COUNT(*) AS item_count,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT product_id) AS product_count,
    COUNT(DISTINCT seller_id) AS seller_count,
    ROUND(SUM(price), 2) AS product_value,
    ROUND(
        100.0 * SUM(price) / SUM(SUM(price)) OVER (),
        2
    ) AS product_value_share_pct,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(AVG(price), 2) AS avg_item_price,
    ROUND(
        100.0 * SUM(freight_value)
        / SUM(price + freight_value),
        2
    ) AS freight_share_pct
FROM categorized_items
GROUP BY category_name
ORDER BY product_value DESC
LIMIT 20;
