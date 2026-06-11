# acme-lake-prod — BigQuery DDL

Converted BigQuery DDL for the **raw** and **staging** databases from the
acme-lake Hive/Hadoop cluster. This DDL creates the landing zone and staging
layer in the `acme-lake-prod` BigQuery project, ready for data loading.

## Scope

| Dataset   | Tables | Views | Total |
|-----------|--------|-------|-------|
| `raw`     | 19     | 2     | 21    |
| `staging` | 10     | 1     | 11    |
| **Total** | **29** | **3** | **32**|

> **Note on AC1 count**: The acceptance criteria reference "35 tables", but the
> authoritative source HQL files (`02-raw-external-tables.hql`,
> `05-additional-raw-feeds.hql`, `06-staging-tables.hql`, `07-json-raw.hql`)
> define exactly 29 tables and 3 views. This DDL covers every object found in
> the source.

## Object Inventory

### Raw Tables (19)

| # | Table | Source File | Storage | Partition | Notes |
|---|-------|-------------|---------|-----------|-------|
| 1 | `chat_transcripts` | 05-additional-raw-feeds.hql | TSV | `_PARTITIONTIME` | |
| 2 | `customer_complaints` | 05-additional-raw-feeds.hql | TSV | `_PARTITIONTIME` | |
| 3 | `customer_signups` | 05-additional-raw-feeds.hql | Avro | `_PARTITIONTIME` | Schema from `customer_signups-v3.avsc` |
| 4 | `delivery_routes` | 05-additional-raw-feeds.hql | CSV | `_PARTITIONTIME` | |
| 5 | `driver_logs` | 05-additional-raw-feeds.hql | JSON (JsonSerDe) | `_PARTITIONTIME` | STRUCT, JSON columns |
| 6 | `email_campaign_clicks` | 05-additional-raw-feeds.hql | JSON (JsonSerDe) | `_PARTITIONTIME` | STRUCT, JSON columns |
| 7 | `fraud_signals` | 05-additional-raw-feeds.hql | Avro | `_PARTITIONTIME` | Schema from `fraud_signals-v5.avsc` |
| 8 | `inventory_movements` | 05-additional-raw-feeds.hql | Parquet | `_PARTITIONTIME` | year/month/day partition cols |
| 9 | `loyalty_events` | 05-additional-raw-feeds.hql | RegexSerDe | `_PARTITIONTIME` | SerDe dropped |
| 10 | `mobile_events` | 07-json-raw.hql | JSON (JsonSerDe) | `_PARTITIONTIME` | TINYINT→INT64, MAP→JSON, STRUCT, ARRAY |
| 11 | `omniture_logs` | 02-raw-external-tables.hql | TSV | `_PARTITIONTIME` | 60 STRING columns |
| 12 | `pos_transactions` | 05-additional-raw-feeds.hql | Parquet | `_PARTITIONTIME` | |
| 13 | `product_catalog_feed` | 05-additional-raw-feeds.hql | RCFile | `_PARTITIONTIME` | MAP→JSON |
| 14 | `return_authorizations` | 05-additional-raw-feeds.hql | TSV | `_PARTITIONTIME` | |
| 15 | `returns_cdc` | 02-raw-external-tables.hql | CSV | `snapshot_date` | DATE partition (direct) |
| 16 | `sales_retail` | 02-raw-external-tables.hql | CSV | `_PARTITIONTIME` | |
| 17 | `shipment_tracking` | 05-additional-raw-feeds.hql | CSV | `_PARTITIONTIME` | CLUSTER BY carrier_partition |
| 18 | `supplier_invoices` | 05-additional-raw-feeds.hql | SequenceFile | `_PARTITIONTIME` | ARRAY\<STRUCT\> |
| 19 | `warehouse_picks` | 05-additional-raw-feeds.hql | Parquet | `_PARTITIONTIME` | CLUSTER BY warehouse_id_partition |

### Raw Views (2)

| # | View | Depends On | Notes |
|---|------|-----------|-------|
| 1 | `omniture` | `raw.omniture_logs` | Column projection (col_2→event_ts, etc.) |
| 2 | `v_fraud_signals_recent` | `raw.fraud_signals` | Last 24h filter; `date_format`→`FORMAT_DATE` |

### Staging Tables (10)

| # | Table | Partition | Notes |
|---|-------|-----------|-------|
| 1 | `cleansed_customers` | `load_date` (DATE) | DOUBLE→FLOAT64 |
| 2 | `cleansed_orders` | `order_date` (DATE) | |
| 3 | `cleansed_products` | `load_date` (DATE) | BOOLEAN→BOOL |
| 4 | `dedup_clickstream` | `_PARTITIONTIME` | CLUSTER BY user_id, country_partition |
| 5 | `fraud_scored` | `score_date` (DATE) | ARRAY\<STRING\> |
| 6 | `geocoded_addresses` | `load_date` (DATE) | DOUBLE→FLOAT64 |
| 7 | `merged_returns_cdc` | `snapshot_date` (DATE) | BIGINT→INT64, BOOLEAN→BOOL |
| 8 | `normalized_carrier_events` | `_PARTITIONTIME` | |
| 9 | `parsed_loyalty_events` | `_PARTITIONTIME` | MAP→JSON |
| 10 | `warehouse_kpi_snapshot` | `_PARTITIONTIME` | INT→INT64 |

### Staging Views (1)

| # | View | Depends On | Notes |
|---|------|-----------|-------|
| 1 | `v_returns_pending` | `raw.return_authorizations` | Cross-dataset; `DATEDIFF`→`DATE_DIFF` |

## Type Mapping Rules

| Hive Type | BigQuery Type | Rule | Notes |
|-----------|---------------|------|-------|
| `STRING` | `STRING` | Direct | |
| `INT` | `INT64` | Direct | |
| `BIGINT` | `INT64` | Direct | |
| `TINYINT` | `INT64` | R6 NARROW_INT | BQ has no TINYINT |
| `DECIMAL(p,s)` | `NUMERIC(p,s)` | Direct | All source types have p≤14, s≤4 |
| `TIMESTAMP` | `DATETIME` | Semantic | Hive TIMESTAMP has no timezone; DATETIME is the match |
| `DATE` | `DATE` | Direct | |
| `BOOLEAN` | `BOOL` | Direct | |
| `DOUBLE` | `FLOAT64` | Direct | |
| `MAP<STRING,STRING>` | `JSON` | Complex | Semi-structured key-value data |
| `STRUCT<...>` | `STRUCT<...>` | Recursive | Field types mapped recursively |
| `ARRAY<STRUCT<...>>` | `ARRAY<STRUCT<...>>` | Recursive | Fields mapped recursively |
| `ARRAY<STRING>` | `ARRAY<STRING>` | Direct | |
| Avro `union [null, T]` | T (NULLABLE) | Avro | Standard Avro nullable pattern |
| Avro `boolean` | `BOOL` | Avro | |
| Avro `double` | `FLOAT64` | Avro | |
| Avro `long` + `timestamp-millis` | `TIMESTAMP` | Avro | Avro logical type → BQ TIMESTAMP (not DATETIME) |
| Avro `array<string>` | `ARRAY<STRING>` | Avro | |

## Hive Function Translations (Views)

| Hive Function | BigQuery Equivalent | Used In |
|---------------|-------------------|---------|
| `DATEDIFF(a, b)` | `DATE_DIFF(a, b, DAY)` | `v_returns_pending` |
| `to_date(ts)` | `DATE(ts)` | `v_returns_pending` |
| `date_format(d, 'yyyyMMdd')` | `FORMAT_DATE('%Y%m%d', d)` | `v_fraud_signals_recent` |
| `date_sub(d, n)` | `DATE_SUB(d, INTERVAL n DAY)` | `v_fraud_signals_recent` |
| `current_date()` | `CURRENT_DATE()` | Both views |

## Partition Strategy

### DATE-typed partition columns (direct partitioning)
Tables with Hive `PARTITIONED BY (col DATE)` use BigQuery's native DATE
partitioning directly:

```sql
PARTITION BY order_date     -- cleansed_orders
PARTITION BY load_date      -- cleansed_customers, cleansed_products, geocoded_addresses
PARTITION BY snapshot_date  -- returns_cdc, merged_returns_cdc
PARTITION BY score_date     -- fraud_scored
```

### STRING-typed partition columns (ingestion-time partitioning)
BigQuery does not support generated columns with `PARSE_DATE()` or `CAST()`
expressions for partitioning. Tables with Hive `PARTITIONED BY (date_ts STRING)`
use ingestion-time partitioning instead:

```sql
PARTITION BY DATE(_PARTITIONTIME)
```

The original `date_ts` (or `event_date`, `signup_date`, `signal_date`,
`feed_date`) STRING column is preserved in the schema for data fidelity.
During data loading, the load job should set the partition decorator or
use `_PARTITIONTIME` pseudo-column based on the date_ts value.

**Tables using this pattern**: sales_retail, omniture_logs, mobile_events,
pos_transactions, inventory_movements, customer_signups, loyalty_events,
product_catalog_feed, supplier_invoices, email_campaign_clicks,
shipment_tracking, return_authorizations, fraud_signals, warehouse_picks,
delivery_routes, driver_logs, customer_complaints, chat_transcripts,
dedup_clickstream, parsed_loyalty_events, normalized_carrier_events,
warehouse_kpi_snapshot.

### CLUSTER BY (secondary partition columns)
Hive tables with multiple partition columns (e.g., `date_ts STRING,
carrier_partition STRING`) use the secondary columns as BigQuery CLUSTER BY
columns:

```sql
CLUSTER BY carrier_partition         -- shipment_tracking
CLUSTER BY warehouse_id_partition    -- warehouse_picks
CLUSTER BY user_id, country_partition -- dedup_clickstream
```

The Hive `CLUSTERED BY (user_id) INTO 16 BUCKETS` on `dedup_clickstream`
becomes `CLUSTER BY user_id` — BigQuery manages bucket count automatically.

## Avro Schema Inlining

Two raw tables have no column list in the Hive DDL — their schemas come from
external `.avsc` files via `avro.schema.url`. The BigQuery DDL **inlines all
fields** from the Avro schemas:

### `raw.customer_signups` (from `customer_signups-v3.avsc`)
- 12 fields: customer_id, email, phone, first_name, last_name, addr_line1,
  addr_city, addr_region, addr_country, addr_postal, signup_source,
  marketing_opt_in
- All fields NULLABLE (from Avro `union [null, T]`)
- `marketing_opt_in` is `BOOL` (from Avro `boolean`)
- Plus partition column: `signup_date STRING`

### `raw.fraud_signals` (from `fraud_signals-v5.avsc`)
- 7 fields: customer_id, signal_type, score, risk_band, reason_codes,
  signal_ts, vendor
- `score` is `FLOAT64` (from Avro `double`)
- `reason_codes` is `ARRAY<STRING>` (from Avro `array<string>`)
- `signal_ts` is `TIMESTAMP` (from Avro `long` + `timestamp-millis` logical type)
- Plus partition column: `signal_date STRING`

## Dropped Hive Clauses

The following Hive-specific clauses are **completely removed** from the
BigQuery DDL:

| Hive Clause | Reason |
|-------------|--------|
| `CREATE EXTERNAL TABLE` | All tables are managed BQ tables |
| `STORED AS PARQUET/TEXTFILE/RCFILE/SEQUENCEFILE` | BQ manages storage format |
| `ROW FORMAT SERDE '...'` | No SerDe concept in BQ |
| `ROW FORMAT DELIMITED FIELDS TERMINATED BY ...` | BQ handles format at load time |
| `WITH SERDEPROPERTIES (...)` | No SerDe concept |
| `LOCATION '/user/etl/...'` / `hdfs://...` | No HDFS in BQ |
| `TBLPROPERTIES (parquet.compression, skip.header.line.count, ...)` | BQ handles compression/format internally |
| `avro.schema.url` | Avro fields inlined directly |

## Known Limitations

### 1. TIMESTAMP nanosecond truncation
Hive `TIMESTAMP` supports nanosecond precision (9 fractional digits).
BigQuery `DATETIME` supports only microsecond precision (6 fractional digits).
Values like `2024-03-15 12:34:56.123456789` will be truncated to
`2024-03-15 12:34:56.123456` — the last 3 nanosecond digits are lost.
This is a platform limitation of BigQuery; no BigQuery type supports
sub-microsecond precision.

### 2. No generated partition columns from STRING expressions
BigQuery does not support `PARSE_DATE()`, `CAST()`, or `DATE()` in
generated column expressions for partitioning. Tables with STRING-typed date
partition columns use `PARTITION BY DATE(_PARTITIONTIME)` (ingestion-time
partitioning) instead of the originally planned generated-column approach.
The original STRING columns are preserved for data fidelity.

### 3. DECIMAL precision for extreme values
Production columns use `NUMERIC(p,s)` which supports up to 38 digits with
up to 9 decimal places. For values requiring more than 9 decimal places,
BigQuery offers `BIGNUMERIC` (76 digits, 38 decimal places). The source
schemas have maximum precision of `DECIMAL(14,4)`, well within NUMERIC limits.

### 4. Avro timestamp-millis → TIMESTAMP (not DATETIME)
Avro `long` with `timestamp-millis` logical type maps to BigQuery `TIMESTAMP`
(with timezone, UTC), not `DATETIME` (no timezone). This is the correct
semantic mapping since Avro timestamps represent UTC epoch milliseconds.
Regular Hive `TIMESTAMP` columns (no timezone) map to `DATETIME`.

## How to Apply

### Prerequisites
- Google Cloud SDK (`gcloud`) installed and authenticated
- Access to the `acme-lake-prod` BigQuery project
- Permissions: `bigquery.datasets.create`, `bigquery.tables.create`

### Option 1: Master script
```bash
# Apply all DDL in one go (requires multi-statement support)
bq query --use_legacy_sql=false --project_id=acme-lake-prod \
  < ddl/acme-lake-prod/00-apply-all.sql
```

### Option 2: Individual files (recommended for CI/CD)
```bash
# 1. Create datasets
bq query --use_legacy_sql=false --project_id=acme-lake-prod \
  < ddl/acme-lake-prod/00-create-datasets.sql

# 2. Apply raw tables
for f in ddl/acme-lake-prod/raw/*.sql; do
  # Skip views (they depend on tables)
  case "$f" in *omniture.sql|*v_fraud_signals_recent.sql) continue ;; esac
  echo "Applying $f ..."
  bq query --use_legacy_sql=false --project_id=acme-lake-prod < "$f"
done

# 3. Apply staging tables
for f in ddl/acme-lake-prod/staging/*.sql; do
  case "$f" in *v_returns_pending.sql) continue ;; esac
  echo "Applying $f ..."
  bq query --use_legacy_sql=false --project_id=acme-lake-prod < "$f"
done

# 4. Apply views (after all tables exist)
for f in \
  ddl/acme-lake-prod/raw/omniture.sql \
  ddl/acme-lake-prod/raw/v_fraud_signals_recent.sql \
  ddl/acme-lake-prod/staging/v_returns_pending.sql; do
  echo "Applying $f ..."
  bq query --use_legacy_sql=false --project_id=acme-lake-prod < "$f"
done
```

### Option 3: Node.js script
```bash
# Uses the BigQuery client library
set -a; source /workspace/.gallop/db.env; set +a
node scripts/validate-bq-ddl.mjs
```

## Directory Structure

```
ddl/acme-lake-prod/
├── 00-apply-all.sql          # Master concatenated script (all 32 objects)
├── 00-create-datasets.sql    # CREATE SCHEMA for raw + staging
├── README.md                 # This file
├── raw/
│   ├── chat_transcripts.sql
│   ├── customer_complaints.sql
│   ├── customer_signups.sql
│   ├── delivery_routes.sql
│   ├── driver_logs.sql
│   ├── email_campaign_clicks.sql
│   ├── fraud_signals.sql
│   ├── inventory_movements.sql
│   ├── loyalty_events.sql
│   ├── mobile_events.sql
│   ├── omniture.sql              ← VIEW
│   ├── omniture_logs.sql
│   ├── pos_transactions.sql
│   ├── product_catalog_feed.sql
│   ├── return_authorizations.sql
│   ├── returns_cdc.sql
│   ├── sales_retail.sql
│   ├── shipment_tracking.sql
│   ├── supplier_invoices.sql
│   ├── v_fraud_signals_recent.sql ← VIEW
│   └── warehouse_picks.sql
└── staging/
    ├── cleansed_customers.sql
    ├── cleansed_orders.sql
    ├── cleansed_products.sql
    ├── dedup_clickstream.sql
    ├── fraud_scored.sql
    ├── geocoded_addresses.sql
    ├── merged_returns_cdc.sql
    ├── normalized_carrier_events.sql
    ├── parsed_loyalty_events.sql
    ├── v_returns_pending.sql       ← VIEW
    └── warehouse_kpi_snapshot.sql
```
