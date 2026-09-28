# Olist 电商经营分析

第二个数据分析作品集项目，重点训练 SQL、多表关联、指标体系和可视化表达。

## 数据来源

- 数据集：[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- 范围：巴西多个电商平台在 2016-2018 年产生的约 10 万笔订单
- 原始文件：9 个 CSV，覆盖订单、客户、商品、卖家、支付、评价与地理位置

原始数据和生成的数据库体积较大，不纳入 Git。运行构建脚本即可在本地复现数据库。

## 项目结构

```text
olist-ecommerce-analytics/
├── data/
│   ├── raw/                 # Kaggle 原始 CSV（不提交 Git）
│   └── processed/           # 本地 SQLite 数据库（不提交 Git）
├── docs/
│   ├── data_dictionary.md   # 表粒度、主键与关联关系
│   ├── learning_path.md     # 分阶段学习路线
│   └── monthly_kpi_findings.md # 月度指标、趋势结论与解释边界
├── outputs/                 # 查询结果和后续图表
├── scripts/
│   ├── build_database.py    # CSV -> SQLite
│   └── run_query.py         # 执行 SQL 文件并输出结果
└── sql/
    └── 01_data_audit.sql    # 第一阶段查询
```

## 开始使用

在项目根目录执行：

```powershell
python scripts/build_database.py
python scripts/run_query.py sql/01_data_audit.sql
```

数据库生成在 `data/processed/olist.db`。

## 分析主线

0. 业务与数据认识：商业流程、表结构、字段类型和数据粒度；
1. 数据审计：主键、缺失值、时间范围和异常状态；
2. 核心指标：订单量、成交额、客单价、件单价与履约时长；
3. 客户分析：新老客户、复购、留存与 RFM 分层；
4. 商品和卖家：品类结构、卖家集中度、交付与评价；
5. 管理看板：把 SQL 指标整理成可解释的一页式仪表盘。

## 当前分析成果

- [月度经营指标与趋势发现](docs/monthly_kpi_findings.md)：包含指标口径、完整月份审计、订单环比和业务解释边界。

## 分析原则

- 先确认一行代表什么，再计算指标；
- 连接多表前先检查一对一、一对多或多对多关系；
- 区分订单金额、支付金额、商品价格和运费；
- 所有结论同时说明统计口径与数据边界。
