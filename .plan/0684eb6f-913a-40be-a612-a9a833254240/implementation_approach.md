# Implementation Approach

## Implementation Approach: Generate BigQuery DDL for 52 Tables + 11 Views

### Output Structure
Following the established pattern in `ddl/acme-lake-prod/`, create a parallel directory:
```
ddl/acme-analytics-prod/
├── 00-create-datasets.sql          -- CREATE SCHEMA retail (US region)
├── 00-apply-all.sql                -- Master apply script
├── README.md
└── retail/
    ├── dim_date.sql
    ├── dim_customer.sql
    ├── ... (52 table files + 11 view files)
    └── vw_panel_continuity_score.sql
```

One `.sql` file per table/view, matching the `acme-lake-prod/raw/*.sql` convention (lowercase table name, comment header documenting source file, storage format, type mappings applied).

### DDL Generation Rules (Mechanical Application)

**Type Mappings (applied universally):**

| Hive/Kudu Type | BigQuery Type | Rule |
|---|---|---|
| `BIGINT` | `INT64` | Direct |
| `INT` | `INT64` | Direct |
| `TINYINT` | `INT64` | R6 NARROW_INT |
| `SMALLINT` | `INT64` | R6 NARROW_INT |
| `STRING` | `STRING` | Direct |
| `BOOLEAN` | `BOOL` | Direct |
| `DATE` | `DATE` | Direct |
| `TIMESTAMP` | `DATETIME` | Hive TIMESTAMP has no timezone; BQ DATETIME is the lossless equivalent |
| `DOUBLE` | `FLOAT64` | Direct |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` | Direct (BQ NUMERIC supports up to 38,9; BIGNUMERIC for wider) |
| `MAP<STRING,STRING>` | `JSON` | Per locked decision; confirmed by `dim_store.attributes`, `dim_promotion.eligibility`, `fact_app_clicks.properties`, `fact_loyalty_events.meta` |
| `ARRAY<T>` | `ARRAY<T>` (REPEATED) | `dim_supplier.categories` → `REPEATED STRING`; `dim_promotion.channels` → `REPEATED STRING` |
| `ARRAY<STRUCT<...>>` | `ARRAY<STRUCT<...>>` (REPEATED STRUCT) | `fact_shipments.tracking_events`, `fact_email_engagement.clicks`, `fact_fraud_decisions.rule_signals` |
| `STRUCT<...>` | `STRUCT<...>` | `dim_supplier.primary_contact`, `dim_warehouse.geocode`, `fact_app_clicks.device` |

**Storage/Property Disposition (all dropped):**
- `STORED AS PARQUET` → dropped
- `STORED AS ORC` → dropped
- `STORED AS KUDU` → dropped
- `TBLPROPERTIES ('parquet.compression'=...)` → dropped
- `TBLPROPERTIES ('transactional'='true', ...)` → dropped (BQ supports DML natively)
- `TBLPROPERTIES ('kudu.*')` → dropped
- `PARTITION BY HASH(col) PARTITIONS N` → dropped (Kudu-specific)
- `PRIMARY KEY (...)` → dropped (BQ has no enforced PKs; clustering substitutes)

**Partitioning Strategy:**

| Source Pattern | BQ Translation | Tables |
|---|---|---|
| `PARTITIONED BY (date_col DATE)` | `PARTITION BY date_col` | fact_sales(sale_date), fact_returns(return_date), fact_refunds(refund_date), agg_daily_sales_by_store(sale_date), agg_daily_sales_by_product(sale_date), etc. |
| `PARTITIONED BY (date_col DATE, string_col STRING)` | `PARTITION BY date_col` (drop non-date partition cols, inline them as regular columns) | fact_web_session(event_date — keep; country — inline), bridge_customer_segment(snapshot_date), bridge_promo_eligibility(load_date) |
| `PARTITIONED BY (year INT, month INT, day INT, region STRING)` | Synthetic `PARTITION BY DATE(PARSE_DATE('%Y%m%d', CONCAT(CAST(year AS STRING), LPAD(CAST(month AS STRING),2,'0'), LPAD(CAST(day AS STRING),2,'0'))))` or use a synthetic `_partition_date DATE` column with `PARTITION BY _partition_date` | fact_inventory_movements, fact_shipments, fact_payments |
| `PARTITIONED BY (year INT, month INT)` | Synthetic `_partition_month DATE` with `PARTITION BY DATE_TRUNC(_partition_month, MONTH)` | fact_supplier_invoice_lines, dim_employee_history(eff_from_year) |
| `PARTITIONED BY (snapshot_hour STRING)` | `PARTITION BY DATE(PARSE_DATETIME('%Y%m%d_%H', snapshot_hour))` or synthetic `_partition_date DATE` | agg_hourly_warehouse_kpi |
| `PARTITIONED BY (as_of_date DATE)` | `PARTITION BY as_of_date` | sales_cube |
| No partition (dims, bridges, ACID) | No partition (small tables) | All dim_* (except dim_employee_history), bridge_* (unpartitioned ones), ACID tables |

**Clustering Strategy:**
- `CLUSTERED BY (col) INTO N BUCKETS` → `CLUSTER BY col` (drop bucket count)
- ACID tables with `CLUSTERED BY (col)` → `CLUSTER BY col` (returns_ledger→return_id, acid_customer_address_history→customer_sk, acid_supplier_terms_history→supplier_sk, acid_loyalty_points_ledger→member_id, acid_inventory_adjustments_log→adjustment_id)
- Kudu PRIMARY KEY columns → `CLUSTER BY pk_cols` (inventory_realtime→warehouse_id,sku; kudu_session_state→session_id; kudu_promo_eligibility→customer_id,promo_id; kudu_realtime_price→sku,store_id)

**Multi-Column Partition → Synthetic Partition Column:**
For tables with `PARTITIONED BY (year INT, month INT, day INT, region STRING)`:
1. Inline all original partition columns as regular columns
2. Add a synthetic `_partition_date DATE` column
3. `PARTITION BY _partition_date`
4. Document: ETL must populate `_partition_date = DATE(year, month, day)` on insert

**Kudu Table Renaming:**
- `kudu_inventory_realtime` → `inventory_realtime` (per AC-8 and locked Kudu decision)
- `kudu_session_state`, `kudu_promo_eligibility`, `kudu_realtime_price` → keep names (AC-8 lists them without rename)

### View Translation Rules

| View | Key Translations |
|---|---|
| `vw_daily_sales_by_country` | Green path — minimal changes. Fully qualify table refs to `acme-analytics-prod.retail.*` |
| `vw_weekly_sales_with_running_totals` | Green path — window functions translate directly |
| `vw_customer_lifetime_value` | R8: `DATEDIFF(a,b)` → `DATE_DIFF(a, b, DAY)`. `DATE_FORMAT(d,'yyyy-MM')` → `FORMAT_DATE('%Y-%m', d)` |
| `vw_monthly_cohort_retention` | R8: `DATE_FORMAT` → `FORMAT_DATE`. `MONTHS_BETWEEN` → `DATE_DIFF(a, b, MONTH)`. `to_date(concat(...))` → `PARSE_DATE('%Y-%m-%d', CONCAT(...))` |
| `vw_product_performance` | Green path |
| `vw_session_to_order_attribution` | Cross-project: `raw.mobile_events` → `` `acme-lake-prod.raw.mobile_events` ``. R9: `+ INTERVAL '1' DAY` → `DATETIME_ADD(s.event_ts, INTERVAL 1 DAY)`. Struct access: `s.context.referrer` works natively in BQ. |
| `vw_active_member_panel` | R3: `NDV(member_id)` → `APPROX_COUNT_DISTINCT(member_id)`. `date_sub(current_date(), 30)` → `DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)` |
| `vw_sales_rollup_by_region` | R4: `WITH ROLLUP` → `GROUP BY ROLLUP(s.region, s.store_sk)`. `GROUPING__ID` → `GROUPING(s.region) * 2 + GROUPING(s.store_sk)` |
| `vw_category_hierarchy_recursive` | R10: `WITH RECURSIVE` passes through. `UNION ALL` already present — no change needed. |
| `vw_panel_continuity_score` | T4: `normalize_country()` → `normalize_country_js()` (BQ JS UDF). `date_sub(current_date(), 90)` → `DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)` |
| `vw_otd_by_carrier_30d` | R9: `+ INTERVAL '48' HOUR` → `TIMESTAMP_ADD(shipped_ts, INTERVAL 48 HOUR)`. `unix_timestamp()` → `UNIX_SECONDS()`. `date_sub` → `DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)` |

### Execution Order
DDL must be applied in this order:
1. `00-create-datasets.sql` — create `retail` dataset
2. All `dim_*` tables (no dependencies)
3. All `fact_*` tables (no dependencies on each other, reference dims via FK conventions)
4. All `agg_*`, `bridge_*`, `acid_*`, `returns_ledger`, `sales_cube`, `top_countries_daily` tables
5. All `inventory_realtime`, `kudu_*` tables
6. UDFs (normalize_country_js — prerequisite for vw_panel_continuity_score)
7. All `vw_*` views (depend on tables + UDFs)

### Fully Qualified Naming
All DDL uses backtick-quoted project-dataset-table format:
`` `acme-analytics-prod.retail.fact_sales` ``
Cross-project references use:
`` `acme-lake-prod.raw.mobile_events` ``
