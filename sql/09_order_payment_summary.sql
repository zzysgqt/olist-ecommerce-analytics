-- 第九关：构建订单支付汇总层。
--
-- 业务目标：把 order_payments 从“支付记录粒度”汇总为“一笔订单一行”。
--
-- 原始字段：
-- order_id             订单编号
-- payment_sequential   同一订单内的支付记录序号
-- payment_type         支付方式
-- payment_installments 分期数
-- payment_value        该条支付记录的金额
--
-- 输出列：
-- payment_record_count 支付记录数
-- payment_type_count   不同支付方式数
-- max_installments     订单所有支付记录中的最大分期数
-- payment_value        订单支付金额合计
--
SELECT
    order_id,
    COUNT(*) AS payment_record_count,
    COUNT(DISTINCT payment_type) AS payment_type_count,
    MAX(payment_installments) AS max_installments,
    ROUND(SUM(payment_value), 2) AS payment_value
FROM order_payments
GROUP BY order_id
ORDER BY payment_value DESC
LIMIT 10;
