-- 卖家销售额集中度。
--
-- 业务问题：平台的商品销售额是否集中在少数卖家手中？
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 商品销售额使用 order_items.price，不等同于利润。
-- 3. 先聚合到“一位卖家一行”，再计算排名和销售额占比。
-- 4. 同一订单可能包含多个卖家的商品，因此各卖家的订单数不能相加后
--    当作平台订单总数。
--
-- 明细字段：
-- seller_id          卖家编号
-- item_count         该卖家售出的商品明细行数
-- order_count        包含该卖家商品的不同订单数
-- product_count      该卖家售出的不同商品数
-- product_value      该卖家的商品售价合计
-- freight_value      该卖家商品对应的运费合计
-- avg_item_price     该卖家平均每个商品明细行的售价

WITH seller_summary AS (
    SELECT
        i.seller_id,
        COUNT(*) AS item_count,
        COUNT(DISTINCT o.order_id) AS order_count,
        COUNT(DISTINCT i.product_id) AS product_count,
        ROUND(SUM(i.price), 2) AS product_value,
        ROUND(SUM(i.freight_value), 2) AS freight_value,
        ROUND(AVG(i.price), 2) AS avg_item_price
    FROM orders AS o
    INNER JOIN order_items AS i
        ON o.order_id = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY i.seller_id
),
seller_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY product_value DESC
        ) AS seller_rank,
        ROUND(
            100.0 * product_value / SUM(product_value) OVER (),
            2
        ) AS seller_value_share_pct,
        ROUND(
            100.0
            * SUM(product_value) OVER (
                ORDER BY product_value DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
            / SUM(product_value) OVER (),
            2
        ) AS cumulative_value_share_pct
    FROM seller_summary
)
SELECT
    COUNT(*) AS total_sellers,
    MAX(
        CASE WHEN seller_rank = 1
            THEN cumulative_value_share_pct END
    ) AS top_1_seller_share_pct,
    MAX(
        CASE WHEN seller_rank = 10
            THEN cumulative_value_share_pct END
    ) AS top_10_sellers_share_pct,
    MAX(
        CASE WHEN seller_rank = 20
            THEN cumulative_value_share_pct END
    ) AS top_20_sellers_share_pct,
    MIN(
        CASE WHEN cumulative_value_share_pct >= 50
            THEN seller_rank END
    ) AS sellers_needed_for_50_pct,
    MIN(
        CASE WHEN cumulative_value_share_pct >= 80
            THEN seller_rank END
    ) AS sellers_needed_for_80_pct
FROM seller_ranked;

