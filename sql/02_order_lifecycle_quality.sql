-- 第二关：检查订单状态与生命周期时间是否互相一致。
--
-- NaN/NULL 表示事件没有被记录。例如，尚未送达的 shipped 订单没有 delivered_at 很正常。
-- 但如果 canceled 订单出现 carrier_at 或 delivered_at，就值得进一步调查。
--
-- 观察后请回答：
-- 1. canceled 订单中，有多少已经交给承运商？多少记录为已送达？
-- 2. delivered 订单是否全部都有送达时间？
-- 3. “状态”和“时间记录”冲突时，为什么不应该直接删除这些订单？

SELECT
    order_status,
    COUNT(*) AS orders,
    SUM(CASE WHEN order_approved_at IS NOT NULL THEN 1 ELSE 0 END) AS approved_records,
    SUM(CASE WHEN order_delivered_carrier_date IS NOT NULL THEN 1 ELSE 0 END) AS carrier_records,
    SUM(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END) AS delivered_records,
    SUM(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
            ELSE 0
        END
    ) AS delivered_after_estimate
FROM orders
GROUP BY order_status
ORDER BY orders DESC;
