-- 第七关：继续调查评价表的真实粒度。
--
-- 输出列说明：
-- review_rows                 评价表总行数
-- distinct_review_ids         不同 review_id 的数量
-- review_id_extra_rows        review_id 重复产生的额外行数
-- distinct_orders             出现在评价表中的不同订单数
-- order_extra_review_rows     同一订单存在多条评价而产生的额外行数
-- distinct_review_order_pairs 不同 review_id + order_id 组合的数量
-- pair_duplicate_rows         上述组合仍然重复的额外行数
-- max_orders_one_review_id    一个 review_id 最多关联多少笔订单
-- max_reviews_one_order       一笔订单最多有多少条评价记录

WITH review_id_counts AS (
    SELECT
        review_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM order_reviews
    GROUP BY review_id
),
order_review_counts AS (
    SELECT
        order_id,
        COUNT(*) AS review_count
    FROM order_reviews
    GROUP BY order_id
),
review_summary AS (
    SELECT
        COUNT(*) AS review_rows,
        COUNT(DISTINCT review_id) AS distinct_review_ids,
        COUNT(*) - COUNT(DISTINCT review_id) AS review_id_extra_rows,
        COUNT(DISTINCT order_id) AS distinct_orders,
        COUNT(*) - COUNT(DISTINCT order_id) AS order_extra_review_rows,
        COUNT(DISTINCT review_id || '|' || order_id) AS distinct_review_order_pairs
    FROM order_reviews
)
SELECT
    s.review_rows,
    s.distinct_review_ids,
    s.review_id_extra_rows,
    s.distinct_orders,
    s.order_extra_review_rows,
    s.distinct_review_order_pairs,
    s.review_rows - s.distinct_review_order_pairs AS pair_duplicate_rows,
    (SELECT MAX(order_count) FROM review_id_counts) AS max_orders_one_review_id,
    (SELECT MAX(review_count) FROM order_review_counts) AS max_reviews_one_order
FROM review_summary AS s;
