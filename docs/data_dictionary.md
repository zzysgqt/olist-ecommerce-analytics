# 数据字典与关联关系

## 核心表

| SQLite 表名 | 行数 | 一行的含义 | 主要键 |
|---|---:|---|---|
| `orders` | 99,441 | 一笔订单 | `order_id` |
| `customers` | 99,441 | 一次订单对应的客户记录 | `customer_id` |
| `order_items` | 112,650 | 一笔订单中的一个商品序号 | `order_id, order_item_id` |
| `order_payments` | 103,886 | 一笔订单的一次支付记录 | `order_id, payment_sequential` |
| `order_reviews` | 99,224 | 一条订单评价 | `review_id`；需检查 `order_id` 是否唯一 |
| `products` | 32,951 | 一种商品 | `product_id` |
| `sellers` | 3,095 | 一个卖家 | `seller_id` |
| `geolocation` | 1,000,163 | 邮编前缀对应的一次坐标记录 | 无单一主键，需先聚合再连接 |
| `category_translation` | 71 | 葡萄牙语品类到英语品类的映射 | `product_category_name` |

## 主要关系

```text
customers 1 ─── 1 orders 1 ─── N order_items N ─── 1 products
                      │                │
                      │                └──── N ─── 1 sellers
                      ├──── 1 ─── N order_payments
                      └──── 1 ─── N order_reviews（需先审计）

products N ─── 1 category_translation
```

## 最容易踩的坑

### `customer_id` 与 `customer_unique_id`

`customer_id` 对应一次订单的客户记录；识别同一个现实客户的多次购买，应使用
`customer_unique_id`。直接用 `customer_id` 计算复购率会把复购客户拆成不同的人。

### 订单金额不能在多表连接后直接求和

订单可能同时有多条商品和多条支付记录。直接把 `order_items` 与 `order_payments`
连接会形成多对多扩张，导致金额重复计算。应先分别聚合到订单粒度，再连接。

### 地理位置表需要预聚合

同一邮编前缀可能对应多条坐标。与客户或卖家连接前，应先按邮编前缀计算代表坐标，
否则行数会膨胀。

### 成交口径

订单状态包含 delivered、shipped、canceled 等状态。分析收入或履约表现之前，必须明确
是否只保留已交付订单，不能把所有状态混在一起。
