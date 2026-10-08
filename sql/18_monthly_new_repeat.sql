-- 月度新增客户与回访客户分析。
--
-- 业务问题：每个月有多少首次购买客户，又有多少历史客户再次回来购买？
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 使用 customer_unique_id 识别真实客户。
-- 3. 客户第一笔已送达订单所在月份，定义为 first_purchase_month（首购月份）。
-- 4. 客户在首购月份活跃时计为 new customer（新增客户）。
-- 5. 客户在首购月份之后再次活跃时计为 returning customer（回访客户）。
-- 6. 同一客户在同一个月下多笔订单，客户人数仍只计算一次。
--
-- 计划输出字段：
-- activity_month        客户产生已送达订单的月份
-- active_customers      当月有已送达订单的真实客户数
-- new_customers         首购月份等于当月的客户数
-- returning_customers   首购月份早于当月的客户数
-- returning_share_pct   回访客户占当月活跃客户的百分比
--
-- 第一步：建立 delivered_customer_orders CTE。
-- 一行代表一笔已送达订单，保留 customer_unique_id 和 purchase_at。
WITH delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp AS purchase_at
    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
customer_first_purchase AS (
    SELECT
        customer_unique_id,
        strftime('%Y-%m', MIN(purchase_at)) AS first_purchase_month
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
),
customer_month_activity AS (
    SELECT DISTINCT
        customer_unique_id,
        strftime('%Y-%m', purchase_at) AS activity_month
    FROM delivered_customer_orders
),
customer_month_status AS (
    SELECT
        a.customer_unique_id,
        a.activity_month,
        f.first_purchase_month,
        CASE
            WHEN a.activity_month = f.first_purchase_month
                THEN 'new'
            ELSE 'returning'
        END AS customer_status
    FROM customer_month_activity AS a
    INNER JOIN customer_first_purchase AS f
        ON a.customer_unique_id = f.customer_unique_id
)
SELECT
    activity_month,
    COUNT(*) AS active_customers,
    SUM(
        CASE WHEN customer_status = 'new'
             THEN 1 ELSE 0 END
    ) AS new_customers,
    SUM(
        CASE WHEN customer_status = 'returning'
             THEN 1 ELSE 0 END
    ) AS returning_customers,
    ROUND(
        100.0 * SUM(
            CASE WHEN customer_status = 'returning'
                 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS returning_share_pct
FROM customer_month_status
GROUP BY activity_month
ORDER BY activity_month;
