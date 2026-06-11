# Validation

## Validation Strategy

### 1. DDL Execution Validation (AC1)
- Apply all `CREATE TABLE` and `CREATE VIEW` statements against scratch BQ datasets (`raw_scratch`, `staging_scratch`) in the `acme-lake-prod` project
- Every statement must execute with zero errors
- Validation script: `bq query --use_legacy_sql=false < ddl/acme-lake-prod/raw/{table}.sql` for each file
- Master apply script `00-apply-all.sql` runs all DDL in order (tables before views)
- **Automated check**: count of successfully created tables + views must equal 31 + 3 = 34

### 2. Schema Metadata Validation (AC2, AC3, AC4, AC5)
After DDL is applied, run `bq show --schema --format=json acme-lake-prod:raw.{table}` for each table and validate:
- Every source column exists in the BQ schema
- Type mappings are correct per the mapping rules:
  - STRING→STRING, INT→INT64, BIGINT→INT64, TINYINT→INT64 (R6)
  - DECIMAL(p,s)→NUMERIC(p,s), TIMESTAMP→DATETIME, DATE→DATE
  - BOOLEAN→BOOL, DOUBLE→FLOAT64
  - MAP<STRING,STRING>→JSON
  - STRUCT<...>→STRUCT<...> with recursively mapped field types
  - ARRAY<STRUCT<...>>→REPEATED STRUCT with recursively mapped field types

**Specific validations per AC:**
- **AC3**: `raw.mobile_events.hour_bucket` must be `INT64` (not TINYINT — BQ doesn't have TINYINT)
- **AC4**: `raw.mobile_events.properties` = JSON, `.context` = STRUCT<ip STRING, country STRING, session_id STRING, referrer STRING>, `.items` = REPEATED STRUCT<sku STRING, qty INT64, price NUMERIC(10,2)>
- **AC5**: `raw.supplier_invoices.line_items` = REPEATED STRUCT<sku STRING, qty INT64, unit_price NUMERIC(10,2)>

### 3. Storage Format Clause Validation (AC6, AC8)
- **AC6**: Verify that generated DDL for `product_catalog_feed` (was RCFILE), `supplier_invoices` (was SEQUENCEFILE), and `loyalty_events` (was RegexSerDe) contains NO `STORED AS` or `ROW FORMAT SERDE` clauses. Grep the output DDL files for these patterns — must return zero matches.
- **AC8**: Verify no `LOCATION 'hdfs://...'` or `TBLPROPERTIES` with `parquet.compression` / `skip.header.line.count` appear in any generated DDL file.

### 4. Avro Schema Validation (AC7)
- `raw.customer_signups`: all 12 fields from `customer_signups-v3.avsc` present, all NULLABLE, `marketing_opt_in` is BOOL
- `raw.fraud_signals`: 7 fields from `fraud_signals-v5.avsc` present, `reason_codes` is REPEATED STRING (from Avro array), `signal_ts` is TIMESTAMP (from Avro timestamp-millis), `score` is FLOAT64 (from Avro double)

### 5. Partition Strategy Validation (AC9)
- `raw.sales_retail`: must have partition metadata referencing `date_ts`. Verify via `bq show --format=json` that `timePartitioning` or `rangePartitioning` is present.
- All tables with DATE partition columns (`order_date`, `load_date`, `snapshot_date`, `score_date`) should use `PARTITION BY {col}` directly.

### 6. Data-Survival Probes (AC10, AC11, AC12)
These validate data fidelity, not just schema. Run after DDL is applied:

**AC10 — TIMESTAMP precision:**
```sql
-- Insert into BQ scratch table
INSERT INTO raw_scratch.returns_cdc (return_id, return_ts, ...)
VALUES (1, DATETIME '2024-03-15 12:34:56.123456');
-- Note: BQ DATETIME supports microsecond precision (6 digits).
-- Hive TIMESTAMP supports nanosecond (9 digits).
-- '2024-03-15 12:34:56.123456789' → truncated to '2024-03-15 12:34:56.123456' in BQ.
-- This is a KNOWN PRECISION LOSS. Document and validate that 6-digit precision matches.
```
**Risk**: AC10 says "exactly equals" with 9 nanosecond digits. BQ DATETIME only supports 6 digits (microseconds). This AC may need adjustment — either accept microsecond truncation or use `TIMESTAMP` type (which also caps at microseconds in BQ). **Recommendation**: Document the nanosecond truncation as an accepted limitation of BQ. No BigQuery type supports sub-microsecond precision.

**AC11 — DECIMAL precision:**
```sql
-- DECIMAL(38,18) seed: 0.123456789012345678
-- NUMERIC(38,18) in BQ? No — BQ NUMERIC is (38,9). BIGNUMERIC is (76,38).
-- For raw.sales_retail.unit_price which is DECIMAL(10,2), the seed value
-- 0.123456789012345678 has 18 scale digits which exceeds NUMERIC(10,2).
-- The probe tests whether the PLATFORM can preserve 18-scale-digit values.
-- Resolution: use a scratch column typed as BIGNUMERIC for the probe.
-- The actual table column stays NUMERIC(10,2) for normal use.
```
**Action**: Create a scratch probe table with a `BIGNUMERIC` column. Verify 18-digit scale preservation. Document that production columns use `NUMERIC(p,s)` per source schema, and BIGNUMERIC is available if wider precision is needed.

**AC12 — NULL vs empty string:**
```sql
INSERT INTO raw_scratch.sales_retail (description) VALUES (NULL);
INSERT INTO raw_scratch.sales_retail (description) VALUES ('');
SELECT description, description IS NULL AS is_null, description = '' AS is_empty
FROM raw_scratch.sales_retail;
-- Expect: row 1 → NULL, true, null; row 2 → '', false, true
```
BQ natively distinguishes NULL from empty string. This probe should pass with no issues.

### 7. View SQL Validation
- Each view's translated SQL must parse and execute without error
- `staging.v_returns_pending` references `raw.return_authorizations` — cross-dataset reference within the same project (works natively)
- `raw.v_fraud_signals_recent` references `raw.fraud_signals` — same dataset
- `raw.omniture` references `raw.omniture_logs` — same dataset

### Edge Cases & Error Handling
- **Empty table DDL**: All tables are created with schema only (no data). DDL must not fail on empty tables.
- **Reserved words**: Check that no column names conflict with BQ reserved words (e.g., `status` is not reserved in BQ Standard SQL but verify)
- **Column name collisions**: Hive partition columns are added to the BQ column list. Verify no name collision with existing columns.
- **NUMERIC precision bounds**: All source DECIMAL types have p≤14, s≤4, well within BQ NUMERIC(38,9). No BIGNUMERIC needed for table DDL (only for AC11 probe).

### Validation Automation
Generate a validation script (`validate-schema.sh` or `validate-schema.py`) that:
1. Applies all DDL to scratch datasets
2. For each table, reads back schema via BQ API
3. Compares against expected schema (column names, types, modes)
4. Runs data-survival probe inserts + reads
5. Reports pass/fail per acceptance criterion
