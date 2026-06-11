# acme-analytics-prod — BigQuery DDL

Converted BigQuery DDL for the **retail** database from the
acme-analytics Hive/Hadoop cluster. This DDL creates the dimensional
warehouse layer in the `acme-analytics-prod` BigQuery project, ready
for data loading.

## Scope

| Dataset   | Tables | Views | UDFs | Total |
|-----------|--------|-------|------|-------|
| `retail`  | 58     | 11    | 1    | 70    |

> **Note**: The 58 tables break down as 15 dimension tables, 17 fact tables,
> 10 aggregate tables, 5 ACID tables, 5 bridge tables, 2 SCD-2 history
> tables, and 4 Kudu real-time tables. The UDF (`normalize_country_js`) is a
> prerequisite for `vw_panel_continuity_score`.

## Object Inventory

### Dimension Tables (15)

| # | Table | Source File | Partition | Cluster | Notes |
|---|-------|-------------|-----------|---------|-------|
| 1 | `dim_date` | 03-retail-tables.hql | — | — | TPC-DS date dimension |
| 2 | `dim_customer` | 03-retail-tables.hql | — | — | TIMESTAMP→DATETIME |
| 3 | `dim_product` | 03-retail-tables.hql | — | — | DECIMAL→NUMERIC |
| 4 | `dim_store` | 10-additional-dims.hql | — | — | MAP→JSON (attributes) |
| 5 | `dim_supplier` | 10-additional-dims.hql | — | — | STRUCT + ARRAY\<STRING\> |
| 6 | `dim_employee` | 10-additional-dims.hql | — | — | |
| 7 | `dim_promotion` | 10-additional-dims.hql | — | — | ARRAY\<STRING\> + MAP→JSON |
| 8 | `dim_warehouse` | 10-additional-dims.hql | — | — | STRUCT\<DOUBLE→FLOAT64\> |
| 9 | `dim_currency` | 10-additional-dims.hql | — | — | |
| 10 | `dim_geography` | 10-additional-dims.hql | — | — | DOUBLE→FLOAT64 |
| 11 | `dim_color` | 10-additional-dims.hql | — | — | |
| 12 | `dim_size` | 10-additional-dims.hql | — | — | |
| 13 | `dim_brand` | 10-additional-dims.hql | — | — | BOOLEAN→BOOL |
| 14 | `dim_category` | 10-additional-dims.hql | — | — | Self-referencing hierarchy |
| 15 | `dim_payment_method` | 10-additional-dims.hql | — | — | DECIMAL(5,4)→NUMERIC(5,4) |

### Fact Tables (17)

| # | Table | Source File | Partition | Cluster | Notes |
|---|-------|-------------|-----------|---------|-------|
| 1 | `fact_sales` | 03-retail-tables.hql | `sale_date` | `customer_sk` | Primary sales fact |
| 2 | `fact_web_session` | 03-retail-tables.hql | `event_date` | — | country inlined from partition |
| 3 | `fact_inventory_movements` | 11-additional-facts.hql | `_partition_date` (synthetic) | `sku` | Multi-col partition → synthetic |
| 4 | `fact_inventory_snapshot` | 11-additional-facts.hql | `snapshot_date` | `sku` | |
| 5 | `fact_returns` | 11-additional-facts.hql | `return_date` | — | |
| 6 | `fact_payments` | 11-additional-facts.hql | `_partition_month` (synthetic) | `invoice_no` | Multi-col partition → synthetic |
| 7 | `fact_shipments` | 11-additional-facts.hql | `_partition_date` (synthetic) | `warehouse_sk` | ARRAY\<STRUCT\> tracking_events |
| 8 | `fact_refunds` | 11-additional-facts.hql | `refund_date` | — | |
| 9 | `fact_app_clicks` | 11-additional-facts.hql | `event_date` | — | MAP→JSON, STRUCT device |
| 10 | `fact_email_engagement` | 11-additional-facts.hql | `event_date` | — | ARRAY\<STRUCT\> clicks |
| 11 | `fact_chat_interactions` | 11-additional-facts.hql | `start_date` | — | BOOLEAN→BOOL |
| 12 | `fact_warehouse_picks` | 11-additional-facts.hql | `pick_date` | `picker_sk` | warehouse_partition inlined |
| 13 | `fact_supplier_invoice_lines` | 11-additional-facts.hql | `_partition_month` (synthetic) | — | Multi-col partition → synthetic |
| 14 | `fact_loyalty_events` | 11-additional-facts.hql | `event_date` | — | MAP→JSON (meta) |
| 15 | `fact_fraud_decisions` | 11-additional-facts.hql | `decision_date` | — | ARRAY\<STRING\> rule_signals |
| 16 | `fact_promo_redemptions` | 11-additional-facts.hql | `redemption_date` | — | |
| 17 | `fact_customer_complaints` | 11-additional-facts.hql | `created_date` | — | |

### Aggregate Tables (10)

| # | Table | Source File | Partition | Notes |
|---|-------|-------------|-----------|-------|
| 1 | `sales_cube` | 08-rollup-etl.hql | `as_of_date` | TINYINT/SMALLINT→INT64 (R6) |
| 2 | `top_countries_daily` | 08-rollup-etl.hql | — | TINYINT→INT64 (R6) |
| 3 | `agg_daily_sales_by_store` | 12-aggregates-rollups.hql | `sale_date` | |
| 4 | `agg_daily_sales_by_product` | 12-aggregates-rollups.hql | `sale_date` | |
| 5 | `agg_weekly_customer_ltv` | 12-aggregates-rollups.hql | `week_start_date` | |
| 6 | `agg_monthly_supplier_performance` | 12-aggregates-rollups.hql | `month_start` | |
| 7 | `agg_hourly_warehouse_kpi` | 12-aggregates-rollups.hql | `_partition_date` (synthetic) | snapshot_hour STRING inlined |
| 8 | `agg_daily_carrier_otd` | 12-aggregates-rollups.hql | `ship_date` | |
| 9 | `agg_marketing_attribution_cube` | 12-aggregates-rollups.hql | `period_date` | |
| 10 | `agg_returns_by_reason_monthly` | 12-aggregates-rollups.hql | `month_start` | |

### ACID Tables (5)

| # | Table | Source File | Cluster | Notes |
|---|-------|-------------|---------|-------|
| 1 | `returns_ledger` | 06-acid-tables.hql | `return_id` | ORC/transactional dropped |
| 2 | `acid_customer_address_history` | 13-additional-acid-tables.hql | `customer_sk` | SCD-2 address tracking |
| 3 | `acid_supplier_terms_history` | 13-additional-acid-tables.hql | `supplier_sk` | SCD-2 terms changes |
| 4 | `acid_loyalty_points_ledger` | 13-additional-acid-tables.hql | `member_id` | Live earn/redeem ledger |
| 5 | `acid_inventory_adjustments_log` | 13-additional-acid-tables.hql | `adjustment_id` | Audit-mandatory |

### Bridge Tables (5) + SCD-2 History Tables (2)

| # | Table | Source File | Partition | Notes |
|---|-------|-------------|-----------|-------|
| 1 | `bridge_product_attribute` | 15-bridge-and-scd2.hql | — | Product M:N attributes |
| 2 | `bridge_product_supplier` | 15-bridge-and-scd2.hql | — | Product M:N suppliers |
| 3 | `bridge_customer_segment` | 15-bridge-and-scd2.hql | `snapshot_date` | Customer M:N segments |
| 4 | `bridge_promo_eligibility` | 15-bridge-and-scd2.hql | `load_date` | Customer promo eligibility |
| 5 | `bridge_employee_role` | 15-bridge-and-scd2.hql | — | Employee M:N roles |
| 6 | `dim_employee_history` | 15-bridge-and-scd2.hql | `_partition_year` (synthetic) | SCD-2, eff_from_year inlined |
| 7 | `dim_store_history` | 15-bridge-and-scd2.hql | — | SCD-2 store changes |

### Kudu Real-Time Tables (4)

| # | Table | Source Table | Cluster | Notes |
|---|-------|-------------|---------|-------|
| 1 | `inventory_realtime` | kudu_inventory_realtime | `warehouse_id, sku` | Renamed; PK→CLUSTER BY |
| 2 | `kudu_session_state` | kudu_session_state | `session_id` | PK→CLUSTER BY |
| 3 | `kudu_promo_eligibility` | kudu_promo_eligibility | `customer_id, promo_id` | PK→CLUSTER BY |
| 4 | `kudu_realtime_price` | kudu_realtime_price | `sku, store_id` | PK→CLUSTER BY |

### UDFs (1)

| # | UDF | Type | Notes |
|---|-----|------|-------|
| 1 | `normalize_country_js` | JavaScript UDF | Ported from `com.acme.udf.NormalizeCountry` |

### Views (11)

| # | View | Source File | Translation Rules Applied |
|---|------|-----------|--------------------------|
| 1 | `vw_daily_sales_by_country` | 09-analytics-views.hql | Green path — fully qualified refs only |
| 2 | `vw_weekly_sales_with_running_totals` | 09-analytics-views.hql | Green path — window functions pass through |
| 3 | `vw_customer_lifetime_value` | 09-analytics-views.hql | R8: `DATEDIFF`→`DATE_DIFF(a, b, DAY)` |
| 4 | `vw_product_performance` | 09-analytics-views.hql | Green path |
| 5 | `vw_monthly_cohort_retention` | 09-analytics-views.hql | R8: `DATE_FORMAT`→`FORMAT_DATE`, `MONTHS_BETWEEN`→`DATE_DIFF(MONTH)`, `to_date(concat(...))`→`PARSE_DATE` |
| 6 | `vw_session_to_order_attribution` | 09-analytics-views.hql | Cross-project ref to `acme-lake-prod.raw.mobile_events`; R9: `INTERVAL` syntax→`DATETIME_ADD` |
| 7 | `vw_active_member_panel` | 16-additional-views.hql | R3: `NDV()`→`APPROX_COUNT_DISTINCT()`; `date_sub`→`DATE_SUB` |
| 8 | `vw_sales_rollup_by_region` | 16-additional-views.hql | R4: `WITH ROLLUP`→`GROUP BY ROLLUP()`; `GROUPING__ID`→`GROUPING()` bit expression |
| 9 | `vw_category_hierarchy_recursive` | 16-additional-views.hql | R10: `WITH RECURSIVE` passes through natively |
| 10 | `vw_panel_continuity_score` | 16-additional-views.hql | T4: `normalize_country()`→`normalize_country_js()` in JOIN ON clause |
| 11 | `vw_otd_by_carrier_30d` | 16-additional-views.hql | R9: `INTERVAL` syntax→`DATETIME_ADD`; `unix_timestamp()`→`UNIX_SECONDS()` |

## Type Mapping Rules

| Hive/Kudu Type | BigQuery Type | Rule | Notes |
|----------------|---------------|------|-------|
| `BIGINT` | `INT64` | Direct | |
| `INT` | `INT64` | Direct | |
| `TINYINT` | `INT64` | R6 NARROW_INT | BQ has no TINYINT |
| `SMALLINT` | `INT64` | R6 NARROW_INT | BQ has no SMALLINT |
| `STRING` | `STRING` | Direct | |
| `BOOLEAN` | `BOOL` | Direct | |
| `DATE` | `DATE` | Direct | |
| `TIMESTAMP` | `DATETIME` | Semantic | Hive TIMESTAMP has no timezone; DATETIME is the lossless equivalent |
| `DOUBLE` | `FLOAT64` | Direct | |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` | Direct | BQ NUMERIC supports up to 38,9; BIGNUMERIC for wider |
| `MAP<STRING,STRING>` | `JSON` | Complex | Semi-structured key-value data |
| `ARRAY<T>` | `ARRAY<T>` (REPEATED) | Direct | e.g., `ARRAY<STRING>` → `ARRAY<STRING>` |
| `ARRAY<STRUCT<...>>` | `ARRAY<STRUCT<...>>` | Recursive | Fields mapped recursively |
| `STRUCT<...>` | `STRUCT<...>` | Recursive | Field types mapped recursively |

## Hive Function Translations (Views)

| Hive Function | BigQuery Equivalent | Used In |
|---------------|-------------------|---------| 
| `DATEDIFF(a, b)` | `DATE_DIFF(a, b, DAY)` | `vw_customer_lifetime_value` |
| `DATE_FORMAT(d, 'yyyy-MM')` | `FORMAT_DATE('%Y-%m', d)` | `vw_monthly_cohort_retention` |
| `MONTHS_BETWEEN(a, b)` | `DATE_DIFF(a, b, MONTH)` | `vw_monthly_cohort_retention` |
| `to_date(concat(s, '-01'))` | `PARSE_DATE('%Y-%m-%d', CONCAT(s, '-01'))` | `vw_monthly_cohort_retention` |
| `NDV(col)` | `APPROX_COUNT_DISTINCT(col)` | `vw_active_member_panel` |
| `date_sub(current_date(), N)` | `DATE_SUB(CURRENT_DATE(), INTERVAL N DAY)` | Multiple views |
| `GROUP BY ... WITH ROLLUP` | `GROUP BY ROLLUP(...)` | `vw_sales_rollup_by_region` |
| `GROUPING__ID` | `GROUPING(a) * 2 + GROUPING(b)` | `vw_sales_rollup_by_region` |
| `+ INTERVAL '1' DAY` | `DATETIME_ADD(ts, INTERVAL 1 DAY)` | `vw_session_to_order_attribution` |
| `+ INTERVAL '48' HOUR` | `DATETIME_ADD(ts, INTERVAL 48 HOUR)` | `vw_otd_by_carrier_30d` |
| `unix_timestamp(ts)` | `UNIX_SECONDS(CAST(ts AS TIMESTAMP))` | `vw_otd_by_carrier_30d` |
| `normalize_country(x)` | `normalize_country_js(x)` | `vw_panel_continuity_score` |

## Partition Strategy

### DATE-typed partition columns (direct partitioning)
Tables with Hive `PARTITIONED BY (col DATE)` use BigQuery's native DATE
partitioning directly:

```sql
PARTITION BY sale_date       -- fact_sales, agg_daily_sales_by_store, agg_daily_sales_by_product
PARTITION BY event_date      -- fact_web_session, fact_app_clicks, fact_email_engagement, fact_loyalty_events
PARTITION BY return_date     -- fact_returns
PARTITION BY refund_date     -- fact_refunds
PARTITION BY snapshot_date   -- fact_inventory_snapshot, bridge_customer_segment
PARTITION BY as_of_date      -- sales_cube
PARTITION BY week_start_date -- agg_weekly_customer_ltv
PARTITION BY month_start     -- agg_monthly_supplier_performance, agg_returns_by_reason_monthly
PARTITION BY ship_date       -- agg_daily_carrier_otd
PARTITION BY period_date     -- agg_marketing_attribution_cube
PARTITION BY pick_date       -- fact_warehouse_picks
PARTITION BY start_date      -- fact_chat_interactions
PARTITION BY created_date    -- fact_customer_complaints
PARTITION BY decision_date   -- fact_fraud_decisions
PARTITION BY redemption_date -- fact_promo_redemptions
PARTITION BY load_date       -- bridge_promo_eligibility
```

### Multi-column partitions → synthetic partition columns
Hive tables with multiple partition columns (e.g., year/month/day/region)
get a synthetic partition column. Original partition columns are inlined as
regular columns for backward-compatible queries.

| Table | Hive Partition | BQ Partition | Synthetic Column |
|-------|---------------|-------------|-----------------|
| `fact_inventory_movements` | `year INT, month INT, day INT, region STRING` | `PARTITION BY _partition_date` | `_partition_date DATE` |
| `fact_shipments` | `ship_year INT, ship_month INT, ship_day INT, carrier_partition STRING` | `PARTITION BY _partition_date` | `_partition_date DATE` |
| `fact_payments` | `post_year INT, post_month INT, payment_method_partition STRING` | `PARTITION BY DATE_TRUNC(_partition_month, MONTH)` | `_partition_month DATE` |
| `fact_supplier_invoice_lines` | `invoice_year INT, invoice_month INT` | `PARTITION BY DATE_TRUNC(_partition_month, MONTH)` | `_partition_month DATE` |
| `agg_hourly_warehouse_kpi` | `snapshot_hour STRING` | `PARTITION BY _partition_date` | `_partition_date DATE` |
| `dim_employee_history` | `eff_from_year INT` | `PARTITION BY DATE_TRUNC(_partition_year, YEAR)` | `_partition_year DATE` |

**ETL convention**: ETL pipelines must populate synthetic columns on insert:
- `_partition_date = DATE(year, month, day)` (for year/month/day decomposition)
- `_partition_month = DATE(year, month, 1)` (for year/month decomposition)
- `_partition_year = DATE(year, 1, 1)` (for year-only decomposition)

### Unpartitioned tables
All dimension tables (except `dim_employee_history`), bridge tables (except
`bridge_customer_segment` and `bridge_promo_eligibility`), ACID tables,
SCD-2 history tables (except `dim_employee_history`), and Kudu tables are
unpartitioned — they are small enough that BQ manages them efficiently
without partitioning.

## Clustering Strategy

- `CLUSTERED BY (col) INTO N BUCKETS` → `CLUSTER BY col` (bucket count dropped)
- ACID tables with `CLUSTERED BY (col)` → `CLUSTER BY col`:
  - `returns_ledger` → `CLUSTER BY return_id`
  - `acid_customer_address_history` → `CLUSTER BY customer_sk`
  - `acid_supplier_terms_history` → `CLUSTER BY supplier_sk`
  - `acid_loyalty_points_ledger` → `CLUSTER BY member_id`
  - `acid_inventory_adjustments_log` → `CLUSTER BY adjustment_id`
- Kudu `PRIMARY KEY (cols)` → `CLUSTER BY cols`:
  - `inventory_realtime` → `CLUSTER BY warehouse_id, sku`
  - `kudu_session_state` → `CLUSTER BY session_id`
  - `kudu_promo_eligibility` → `CLUSTER BY customer_id, promo_id`
  - `kudu_realtime_price` → `CLUSTER BY sku, store_id`

## ACID Table Handling

Hive ACID tables (`transactional=true`) are converted to standard managed
BigQuery tables:
- `STORED AS ORC` → dropped (BQ manages storage format)
- `TBLPROPERTIES ('transactional'='true', ...)` → dropped (BQ supports DML natively)
- `CLUSTERED BY (col) INTO N BUCKETS` → `CLUSTER BY col`
- `bucketing_version`, `orc.compress` → dropped

BigQuery natively supports UPDATE, DELETE, and MERGE, so ACID semantics are
preserved without any special configuration.

## Kudu Table Handling

Kudu real-time tables are converted to standard managed BigQuery tables:
- `STORED AS KUDU` → dropped
- `PRIMARY KEY (cols)` → `CLUSTER BY cols` (BQ has no enforced PKs)
- `PARTITION BY HASH(col) PARTITIONS N` → dropped (BQ manages distribution)
- `TBLPROPERTIES ('kudu.master_addresses'=..., 'kudu.table_name'=..., ...)` → dropped

**Rename**: `kudu_inventory_realtime` → `inventory_realtime` (per migration decision).
Other Kudu tables keep their names.

**Performance note**: Kudu sub-second UPSERT workloads map to BigQuery
MERGE (higher latency) or Bigtable for true real-time needs.

## Cross-Project References

`vw_session_to_order_attribution` references `acme-lake-prod.raw.mobile_events`
(cross-project). The analytics service account needs `roles/bigquery.dataViewer`
on the `acme-lake-prod` project's `raw` dataset.

## Dropped Hive Clauses

The following Hive-specific clauses are **completely removed** from the
BigQuery DDL:

| Hive Clause | Reason |
|-------------|--------|
| `STORED AS PARQUET/ORC/KUDU` | BQ manages storage format |
| `TBLPROPERTIES (parquet.compression, transactional, kudu.*, ...)` | No equivalent in BQ |
| `ROW FORMAT SERDE '...'` | No SerDe concept in BQ |
| `LOCATION '/user/hive/...'` | No HDFS in BQ |
| `PRIMARY KEY (...)` | BQ has no enforced PKs; clustering substitutes |
| `PARTITION BY HASH(col) PARTITIONS N` | Kudu-specific; BQ manages distribution |
| `CLUSTERED BY (col) INTO N BUCKETS` | Bucket count dropped; `CLUSTER BY col` replaces |
| `CREATE EXTERNAL TABLE` | All tables are managed BQ tables |

## Known Limitations

### 1. TIMESTAMP nanosecond truncation
Hive `TIMESTAMP` supports nanosecond precision (9 fractional digits).
BigQuery `DATETIME` supports only microsecond precision (6 fractional digits).
Values like `2024-03-15 12:34:56.123456789` will be truncated to
`2024-03-15 12:34:56.123456` — the last 3 nanosecond digits are lost.
This is a platform limitation of BigQuery.

### 2. DECIMAL precision for extreme values
Production columns use `NUMERIC(p,s)` which supports up to 38 digits with
up to 9 decimal places. For values requiring more than 9 decimal places,
BigQuery offers `BIGNUMERIC` (76 digits, 38 decimal places). The source
schemas have maximum scale of `DECIMAL(5,4)` — well within NUMERIC limits.

### 3. No enforced primary keys
BigQuery does not enforce primary key constraints. Kudu PK columns are
mapped to `CLUSTER BY` for query performance, but uniqueness is not enforced.
Data pipelines must ensure PK uniqueness at the application level.

### 4. Cross-project view dependency
`vw_session_to_order_attribution` depends on `acme-lake-prod.raw.mobile_events`.
If the lake DDL has not been applied to BigQuery, this view creation will fail.
Apply the acme-lake-prod DDL first, or create the view after both projects are
migrated.

### 5. UDF fidelity
`normalize_country_js` is a JavaScript UDF placeholder. The full mapping logic
from the original Java UDF (`com.acme.udf.NormalizeCountry`) must be ported
completely for production use.

### 6. MAP→JSON semantic change
Hive `MAP<STRING,STRING>` provides typed key-value access (`map['key']`).
BigQuery `JSON` requires `JSON_VALUE(col, '$.key')` for extraction. ETL code
that accesses map keys must be updated.

## How to Apply

### Prerequisites
- Google Cloud SDK (`gcloud`) installed and authenticated
- Access to the `acme-analytics-prod` BigQuery project
- Permissions: `bigquery.datasets.create`, `bigquery.tables.create`
- For cross-project view: `bigquery.dataViewer` on `acme-lake-prod.raw`

### Option 1: Master script
```bash
bq query --use_legacy_sql=false --project_id=acme-analytics-prod \
  < ddl/acme-analytics-prod/00-apply-all.sql
```

### Option 2: Individual files (recommended for CI/CD)
```bash
# 1. Create dataset
bq query --use_legacy_sql=false --project_id=acme-analytics-prod \
  < ddl/acme-analytics-prod/00-create-datasets.sql

# 2. Apply tables (dims → facts → aggregates → ACID → bridges → Kudu)
for f in ddl/acme-analytics-prod/retail/*.sql; do
  case "$f" in *vw_*) continue ;; esac  # Skip views
  echo "Applying $f ..."
  bq query --use_legacy_sql=false --project_id=acme-analytics-prod < "$f"
done

# 3. Apply UDF (from 00-apply-all.sql section 8, or a separate UDF file)

# 4. Apply views
for f in ddl/acme-analytics-prod/retail/vw_*.sql; do
  echo "Applying $f ..."
  bq query --use_legacy_sql=false --project_id=acme-analytics-prod < "$f"
done
```

### Option 3: Node.js validation script
```bash
set -a; source /workspace/.gallop/db.env; set +a
node scripts/validate-analytics-ac.mjs
```

## Directory Structure

```
ddl/acme-analytics-prod/
├── 00-apply-all.sql                          # Master concatenated script (70 objects)
├── 00-create-datasets.sql                    # CREATE SCHEMA for retail
├── README.md                                 # This file
└── retail/
    ├── dim_date.sql                          # 15 dimension tables
    ├── dim_customer.sql
    ├── dim_product.sql
    ├── dim_store.sql
    ├── dim_supplier.sql
    ├── dim_employee.sql
    ├── dim_promotion.sql
    ├── dim_warehouse.sql
    ├── dim_currency.sql
    ├── dim_geography.sql
    ├── dim_color.sql
    ├── dim_size.sql
    ├── dim_brand.sql
    ├── dim_category.sql
    ├── dim_payment_method.sql
    ├── fact_sales.sql                        # 17 fact tables
    ├── fact_web_session.sql
    ├── fact_inventory_movements.sql
    ├── fact_inventory_snapshot.sql
    ├── fact_returns.sql
    ├── fact_payments.sql
    ├── fact_shipments.sql
    ├── fact_refunds.sql
    ├── fact_app_clicks.sql
    ├── fact_email_engagement.sql
    ├── fact_chat_interactions.sql
    ├── fact_warehouse_picks.sql
    ├── fact_supplier_invoice_lines.sql
    ├── fact_loyalty_events.sql
    ├── fact_fraud_decisions.sql
    ├── fact_promo_redemptions.sql
    ├── fact_customer_complaints.sql
    ├── sales_cube.sql                        # 10 aggregate tables
    ├── top_countries_daily.sql
    ├── agg_daily_sales_by_store.sql
    ├── agg_daily_sales_by_product.sql
    ├── agg_weekly_customer_ltv.sql
    ├── agg_monthly_supplier_performance.sql
    ├── agg_hourly_warehouse_kpi.sql
    ├── agg_daily_carrier_otd.sql
    ├── agg_marketing_attribution_cube.sql
    ├── agg_returns_by_reason_monthly.sql
    ├── returns_ledger.sql                    # 5 ACID tables
    ├── acid_customer_address_history.sql
    ├── acid_supplier_terms_history.sql
    ├── acid_loyalty_points_ledger.sql
    ├── acid_inventory_adjustments_log.sql
    ├── bridge_product_attribute.sql          # 5 bridge + 2 SCD-2 tables
    ├── bridge_product_supplier.sql
    ├── bridge_customer_segment.sql
    ├── bridge_promo_eligibility.sql
    ├── bridge_employee_role.sql
    ├── dim_employee_history.sql
    ├── dim_store_history.sql
    ├── inventory_realtime.sql                # 4 Kudu tables
    ├── kudu_session_state.sql
    ├── kudu_promo_eligibility.sql
    ├── kudu_realtime_price.sql
    ├── vw_daily_sales_by_country.sql         # 11 views
    ├── vw_weekly_sales_with_running_totals.sql
    ├── vw_customer_lifetime_value.sql
    ├── vw_product_performance.sql
    ├── vw_monthly_cohort_retention.sql
    ├── vw_session_to_order_attribution.sql   ← cross-project VIEW
    ├── vw_active_member_panel.sql
    ├── vw_sales_rollup_by_region.sql
    ├── vw_category_hierarchy_recursive.sql
    ├── vw_panel_continuity_score.sql         ← uses normalize_country_js UDF
    └── vw_otd_by_carrier_30d.sql
```
