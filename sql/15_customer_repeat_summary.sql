-- 第十五关：客户复购概况。
--
-- 业务问题：在产生过已送达订单的真实客户中，有多少人购买过两次及以上？
--
-- 客户身份：
-- customer_id         一次订单对应的客户记录编号，同一真实客户再次下单时通常会变化
-- customer_unique_id  跨订单识别同一真实客户的编号，本关按它统计客户
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 一位客户有两笔及以上已送达订单，定义为 repeat customer（复购客户）。
-- 3. 这里计算的是历史观察窗口内的复购客户比例，不等同于留存率。
-- 4. 靠近数据截止日期才首次购买的客户，复购观察时间较短，这是本指标的边界。
--
-- 最终计划输出：
-- total_customers          有已送达订单的真实客户数
-- repeat_customers         有两笔及以上已送达订单的真实客户数
-- one_time_customers       只有一笔已送达订单的真实客户数
-- repeat_customer_rate_pct 复购客户占全部客户的百分比
--
-- 第一步：建立 delivered_customer_orders CTE。
-- 一行代表一笔已送达订单，保留 order_id、customer_unique_id 和下单时间。
WITH delivered_customer_orders AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders AS o
    INNER JOIN customers AS c
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
customer_summary AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS delivered_order_count,
        MIN(order_purchase_timestamp) AS first_purchase_at,
        MAX(order_purchase_timestamp) AS last_purchase_at
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(
        CASE WHEN delivered_order_count >= 2
             THEN 1 ELSE 0 END
    ) AS repeat_customers,
    SUM(
        CASE WHEN delivered_order_count = 1
             THEN 1 ELSE 0 END
    ) AS one_time_customers,
    ROUND(
        100.0 * SUM(
            CASE WHEN delivered_order_count >= 2
                 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS repeat_customer_rate_pct
FROM customer_summary;
