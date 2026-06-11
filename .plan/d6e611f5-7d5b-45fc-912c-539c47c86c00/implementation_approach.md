# Implementation Approach

## Implementation Approach: Hive/Avro DDL → BigQuery DDL Conversion

### Output Structure
Generate BigQuery DDL files organized by dataset under `ddl/acme-lake-prod/`:
- `ddl/acme-lake-prod/raw/` — 20 raw tables + 2 views
- `ddl/acme-lake-prod/staging/` — 11 staging tables + 1 view
- One `.sql` file per table/view
- A master `00-apply-all.sql` that `INCLUDE`s all DDL in dependency order (views after tables)

### Dataset Creation
```sql
CREATE SCHEMA IF NOT EXISTS `acme-lake-prod.raw` OPTIONS(location='US');
CREATE SCHEMA IF NOT EXISTS `acme-lake-prod.staging` OPTIONS(location='US');
```

### DDL Translation Rules Applied (per locked SQL Dialect decision)

**Clauses dropped:**
- `STORED AS PARQUET/TEXTFILE/RCFILE/SEQUENCEFILE` → dropped; all become managed BQ tables
- `ROW FORMAT SERDE '...'` / `ROW FORMAT DELIMITED ...` → dropped
- `LOCATION 'hdfs://...'` or `LOCATION '/user/etl/...'` → dropped
- `TBLPROPERTIES (parquet.compression, skip.header.line.count, serialization.null.format, ignore.malformed.json)` → dropped
- `WITH SERDEPROPERTIES (...)` → dropped
- `avro.schema.url` → dropped; Avro fields resolved from `.avsc` and inlined into BQ DDL

**Type mappings:**
| Hive Type | BigQuery Type | Rule |
|---|---|---|
| `STRING` | `STRING` | Direct |
| `INT` | `INT64` | Direct |
| `BIGINT` | `INT64` | Direct |
| `TINYINT` | `INT64` | R6 NARROW_INT |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` | Direct (p≤38, s≤9 fits NUMERIC) |
| `TIMESTAMP` | `DATETIME` | Per AC2 — Hive TIMESTAMP has no timezone; DATETIME is the semantic match |
| `DATE` | `DATE` | Direct |
| `BOOLEAN` / `boolean` (Avro) | `BOOL` | Direct |
| `DOUBLE` / `double` (Avro) | `FLOAT64` | Direct |
| `MAP<STRING,STRING>` | `JSON` | Per AC2 |
| `STRUCT<...>` | `STRUCT<...>` | Nested fields type-mapped recursively |
| `ARRAY<STRUCT<...>>` | `ARRAY<STRUCT<...>>` (mode REPEATED) | Nested fields type-mapped recursively |
| `ARRAY<STRING>` (Avro) | `ARRAY<STRING>` (mode REPEATED) | Direct |
| Avro `union [null, T]` | T with mode NULLABLE | Standard Avro→BQ |
| Avro `long` + `timestamp-millis` | `TIMESTAMP` | Per AC7 — Avro timestamp-millis maps to BQ TIMESTAMP (not DATETIME) |

### Partition Strategy

Source Hive tables use `PARTITIONED BY (col TYPE)` which adds partition columns outside the main column list. In BQ, partition columns are part of the schema.

| Table | Source Partition | BQ Partition Strategy |
|---|---|---|
| `raw.sales_retail` | `date_ts STRING` | `PARTITION BY DATE(PARSE_DATE('%Y%m%d', date_ts))` — ingestion-time pseudo-column or use a generated column. **Recommendation**: keep `date_ts STRING` in schema, add a generated column `_partition_date DATE AS (PARSE_DATE('%Y-%m-%d', date_ts))`, partition by `_partition_date`. **Alternative**: If `date_ts` is already ISO-date-formatted, use `PARTITION BY DATE(date_ts)` directly. |
| `raw.mobile_events` | `event_date STRING, hour_bucket TINYINT` | Both columns added to BQ schema. `hour_bucket` promoted to INT64 (R6). Partition by `DATE(PARSE_TIMESTAMP(..., event_date))` or keep string + generated column. |
| `raw.inventory_movements` | `year INT, month INT, day INT` | All 3 as INT64. Create generated column `_partition_date DATE AS (DATE(year, month, day))`, partition by `_partition_date`. |
| `raw.shipment_tracking` | `date_ts STRING, carrier_partition STRING` | Partition by date_ts (same pattern as sales_retail). `carrier_partition` becomes a CLUSTER BY column. |
| `raw.warehouse_picks` | `date_ts STRING, warehouse_id_partition STRING` | Partition by date_ts. `warehouse_id_partition` becomes a CLUSTER BY column. |
| Staging tables with `DATE` partition | `order_date DATE`, `load_date DATE`, `snapshot_date DATE`, `score_date DATE` | Direct: `PARTITION BY order_date` etc. — BQ natively supports DATE partitioning. |
| Tables with `date_ts STRING` | Multiple | Same generated-column pattern or `PARTITION BY DATE(PARSE_DATE(...))`. |

### Avro-Backed Tables (Schema Inlining)
`raw.customer_signups` and `raw.fraud_signals` have no column list in Hive DDL — schema comes from `.avsc` files. The BQ DDL will **inline all fields** from the Avro schemas:

**customer_signups** (from `customer_signups-v3.avsc`): 12 fields — `customer_id STRING, email STRING, phone STRING, first_name STRING, last_name STRING, addr_line1 STRING, addr_city STRING, addr_region STRING, addr_country STRING, addr_postal STRING, signup_source STRING, marketing_opt_in BOOL` — all NULLABLE. Plus partition column `signup_date STRING`.

**fraud_signals** (from `fraud_signals-v5.avsc`): 7 fields — `customer_id STRING, signal_type STRING, score FLOAT64, risk_band STRING, reason_codes ARRAY<STRING>, signal_ts TIMESTAMP, vendor STRING` — all NULLABLE. Plus partition column `signal_date STRING`.

### Views Translation
3 views need Hive→BQ SQL translation:

1. **`raw.omniture`** — Simple column projection. Only change: fully qualify table reference to `acme-lake-prod.raw.omniture_logs`.
2. **`staging.v_returns_pending`** — Uses `DATEDIFF(current_date(), to_date(r.requested_at))`. Apply R8: `DATE_DIFF(CURRENT_DATE(), DATE(r.requested_at), DAY) AS days_pending`. Fully qualify `acme-lake-prod.raw.return_authorizations`.
3. **`raw.v_fraud_signals_recent`** — Uses `date_format(date_sub(current_date(), 1), 'yyyyMMdd')`. Apply R8: `FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))`.

### Table Naming
All table names preserved as-is (snake_case). No renaming. `raw.*` and `staging.*` map directly to `acme-lake-prod.raw.*` and `acme-lake-prod.staging.*`.

### All Tables/Views (35 tables + 3 views)

**raw (20 tables, 2 views):**
1. sales_retail, 2. omniture_logs, 3. returns_cdc, 4. mobile_events, 5. pos_transactions, 6. inventory_movements, 7. customer_signups (Avro), 8. loyalty_events (RegexSerDe), 9. product_catalog_feed (RCFile), 10. supplier_invoices (SequenceFile), 11. email_campaign_clicks (JsonSerDe), 12. shipment_tracking, 13. return_authorizations, 14. fraud_signals (Avro), 15. warehouse_picks, 16. delivery_routes, 17. driver_logs (JsonSerDe), 18. customer_complaints, 19. chat_transcripts, 20. (reserved for additional if needed)
Views: omniture, v_fraud_signals_recent

**staging (11 tables, 1 view):**
1. cleansed_orders, 2. cleansed_customers, 3. cleansed_products, 4. dedup_clickstream, 5. geocoded_addresses, 6. parsed_loyalty_events, 7. merged_returns_cdc, 8. normalized_carrier_events, 9. fraud_scored, 10. warehouse_kpi_snapshot
View: v_returns_pending

**Note**: The acceptance criteria mention 35 tables but the source DDL yields 31 tables (20 raw + 11 staging). The AC1 list includes 29 named tables. We count exactly what's in the source DDL files. Any discrepancy should be resolved by treating the source HQL files as the authoritative list.

### CLUSTERED BY Translation
`staging.dedup_clickstream` has `CLUSTERED BY (user_id) INTO 16 BUCKETS`. This becomes `CLUSTER BY user_id` in BQ (bucket count is dropped — BQ manages bucket count automatically).

### All Tables Created as Managed
All source tables (even `EXTERNAL TABLE`) become managed BQ tables. The `EXTERNAL` designation was Hive-specific (schema-on-read over HDFS). In BQ, data will be loaded via `bq load` from GCS during the data migration phase.
