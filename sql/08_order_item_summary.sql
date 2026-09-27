-- 第八关：构建订单商品汇总层。
--
-- 业务目标：把 order_items 从“商品明细粒度”汇总为“一笔订单一行”。
-- 本关暂时不连接 orders，也不筛选订单状态；下一关再处理成交口径。
--
-- 原始字段：
-- order_id       订单编号
-- order_item_id  订单内部的商品明细序号
-- product_id     商品编号
-- seller_id      卖家编号
-- price          该商品明细的商品金额
-- freight_value  该商品明细的运费
--
-- 输出列：
-- item_count     订单包含的商品明细行数
-- product_count  订单包含的不同商品数
-- seller_count   订单涉及的不同卖家数
-- product_value  订单商品金额合计
-- freight_value  订单运费合计
-- order_value    商品金额与运费之和
--
SELECT
    order_id,
    COUNT(*) AS item_count,
    COUNT(DISTINCT product_id) AS product_count,
    COUNT(DISTINCT seller_id) AS seller_count,
    ROUND(SUM(price), 2) AS product_value,
    ROUND(SUM(freight_value), 2) AS freight_value,
    ROUND(SUM(price+freight_value), 2) AS order_value
FROM order_items
GROUP BY order_id
ORDER BY order_value DESC
LIMIT 10;
