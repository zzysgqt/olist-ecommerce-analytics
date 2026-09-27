-- 第五关：区分订单客户记录与现实客户。
--
-- 输出列说明：
-- customer_rows          customers 表的总行数
-- distinct_customer_ids  不同 customer_id 的数量；该编号用于连接一笔订单
-- real_customers         不同 customer_unique_id 的数量；近似代表现实客户数
-- repeat_customers       拥有两笔及以上订单的现实客户数
-- max_orders_one_customer 单个现实客户最多拥有的订单数
--
-- customer_id 和 customer_unique_id 都是匿名标识符，不能据此识别真实个人。

WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers AS c
    JOIN orders AS o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
),
customer_summary AS (
    SELECT
        COUNT(*) AS customer_rows,
        COUNT(DISTINCT customer_id) AS distinct_customer_ids,
        COUNT(DISTINCT customer_unique_id) AS real_customers
    FROM customers
),
repeat_summary AS (
    SELECT
        SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
        MAX(order_count) AS max_orders_one_customer
    FROM customer_order_counts
)
SELECT
    c.customer_rows,
    c.distinct_customer_ids,
    c.real_customers,
    r.repeat_customers,
    r.max_orders_one_customer
FROM customer_summary AS c
CROSS JOIN repeat_summary AS r;
