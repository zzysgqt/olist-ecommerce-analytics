-- 客户同期群留存分析。
--
-- 业务问题：同一首购月份获得的客户，在之后各月还有多少人回来购买？
--
-- 统计口径：
-- 1. 只统计 order_status = 'delivered' 的订单。
-- 2. 使用 customer_unique_id 识别真实客户。
-- 3. cohort_month 表示客户首笔已送达订单所在月份。
-- 4. activity_month 表示客户产生已送达订单的月份。
-- 5. month_number 表示活动月份距离首购月份经过了几个月；首购月为 0。
-- 6. cohort_size 表示该首购同期群的客户总数。
-- 7. retained_customers 表示同期群在指定 month_number 仍然活跃的客户数。
-- 8. retention_rate_pct 表示 retained_customers / cohort_size × 100%。
-- 9. 同一客户在同一个月份下多笔订单，客户人数只计算一次。
-- 10. 正式比较限定为 2017-02 至 2018-01 首购同期群，并观察首购后 0 至 6 个月；
--     这样每个同期群都有完整且可比较的六个月观察窗口。
--
-- 重要边界：
-- 越靠近数据截止日期的同期群，可观察的后续月份越少，不能把“尚未观察到”当成未留存。
--
-- 计划输出字段：
-- cohort_month       客户首购月份
-- month_number       距首购月的月数，首购月为 0
-- cohort_size        同期群客户总数
-- retained_customers 当期仍活跃的客户数
-- retention_rate_pct 当期留存率
--
-- 第一步：建立已送达订单的客户购买明细。
-- 一行代表一笔已送达订单。
WITH delivered_customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp AS purchase_at
    FROM orders AS o
    INNER JOIN customers AS c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
customer_cohort AS (
    SELECT
        customer_unique_id,
        strftime('%Y-%m', MIN(purchase_at)) AS cohort_month
    FROM delivered_customer_orders
    GROUP BY customer_unique_id
),
customer_month_activity AS (
    SELECT DISTINCT
        customer_unique_id,
        strftime('%Y-%m', purchase_at) AS activity_month
    FROM delivered_customer_orders
),
cohort_activity AS (
    SELECT
        a.customer_unique_id,
        c.cohort_month,
        a.activity_month,
        (
            CAST(substr(a.activity_month, 1, 4) AS INTEGER)
                - CAST(substr(c.cohort_month, 1, 4) AS INTEGER)
        ) * 12
        + CAST(substr(a.activity_month, 6, 2) AS INTEGER)
        - CAST(substr(c.cohort_month, 6, 2) AS INTEGER)
            AS month_number
    FROM customer_month_activity AS a
    INNER JOIN customer_cohort AS c
        ON a.customer_unique_id = c.customer_unique_id
),
cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM customer_cohort
    GROUP BY cohort_month
)
SELECT
    a.cohort_month,
    a.month_number,
    s.cohort_size,
    COUNT(*) AS retained_customers,
    ROUND(
        100.0 * COUNT(*) / s.cohort_size,
        2
    ) AS retention_rate_pct
FROM cohort_activity AS a
INNER JOIN cohort_sizes AS s
    ON a.cohort_month = s.cohort_month
WHERE a.cohort_month BETWEEN '2017-02' AND '2018-01'
  AND a.month_number BETWEEN 0 AND 6
GROUP BY
    a.cohort_month,
    a.month_number,
    s.cohort_size
ORDER BY
    a.cohort_month,
    a.month_number;
