-- 第十四关：计算月度已送达订单数及环比变化。
--
-- 本关只分析一个指标，避免同时处理过多金额列。
-- 严格比较窗口：2017-02-01（含）至 2018-08-01（不含）。
-- 这个窗口中的月份连续且完整，因此 LAG 的上一行就是上一个自然月。
-- 环比用于描述相邻月份的变化，不能单独证明促销或其他因素造成了变化。
--
-- 输出列：
-- order_month          下单月份
-- delivered_orders     当月最终送达的订单数
-- previous_orders      上月最终送达的订单数
-- mom_order_growth_pct 订单数月度环比百分比（mom = month over month）
--
-- 第一步：完成 monthly_orders CTE，得到“一月一行”的订单数。
-- 第二步：完成 order_trend CTE，使用 LAG 取得 previous_orders。
-- 第三步：在最终 SELECT 中计算 mom_order_growth_pct。

WITH monthly_orders AS (
    SELECT
        strftime('%Y-%m', order_purchase_timestamp) AS order_month,
        COUNT(*) AS delivered_orders
    FROM orders
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= '2017-02-01'
      AND order_purchase_timestamp < '2018-08-01'
    GROUP BY order_month
),
order_trend AS (
    SELECT
        order_month,
        delivered_orders,
        LAG(delivered_orders) OVER (
            ORDER BY order_month
        ) AS previous_orders
    FROM monthly_orders
)
SELECT
    order_month,
    delivered_orders,
    previous_orders,
    ROUND(
        100.0 * (delivered_orders - previous_orders) / previous_orders,
        2
    ) AS mom_order_growth_pct
FROM order_trend
ORDER BY order_month;
