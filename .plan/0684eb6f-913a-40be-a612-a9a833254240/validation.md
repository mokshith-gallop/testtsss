# Validation

## Validation Strategy

### 1. DDL Execution Validation (AC-1)
**Method**: Apply all generated CREATE statements to a BQ scratch dataset (`acme-analytics-prod.retail_scratch`) and verify zero errors.
- Run `00-apply-all.sql` via `bq query --use_legacy_sql=false`
- Script exits with non-zero on any error
- Validate object count: `SELECT COUNT(*) FROM retail_scratch.INFORMATION_SCHEMA.TABLES` = 52 tables + 11 views = 63
- Existing `scripts/validate-bq-ddl.mjs` and `scripts/validate-all-ac.mjs` in the project can be extended to automate this

### 2. Schema Metadata Validation (AC-2 through AC-8, AC-11)
**Method**: For each table with specific AC requirements, query `INFORMATION_SCHEMA.COLUMNS` and `INFORMATION_SCHEMA.TABLE_OPTIONS` to verify:

| AC | Table | Checks |
|---|---|---|
| AC-2 | fact_sales | Partition: sale_date DAY; Cluster: customer_sk; Columns: invoice_no STRING, customer_sk INT64, product_sk INT64, quantity INT64, unit_price NUMERIC(10,2), line_total NUMERIC(14,2), country STRING, invoice_ts DATETIME |
| AC-3 | sales_cube | dim_level INT64 (not TINYINT), month_key INT64 (not SMALLINT), revenue NUMERIC(18,2); Partition: as_of_date |
| AC-4 | fact_shipments | tracking_events mode=REPEATED, type=RECORD; sub-fields ts DATETIME, status STRING, location STRING |
| AC-5 | dim_store | attributes column type = JSON |
| AC-6 | dim_supplier | primary_contact type=RECORD with sub-fields name STRING, email STRING, phone STRING; categories mode=REPEATED type=STRING |
| AC-7 | returns_ledger, acid_customer_address_history, acid_supplier_terms_history, acid_loyalty_points_ledger, acid_inventory_adjustments_log | Standard managed tables (not external); CLUSTER BY on bucketing column |
| AC-8 | inventory_realtime, kudu_session_state, kudu_promo_eligibility, kudu_realtime_price | Managed tables; CLUSTER BY on PK columns; no Kudu TBLPROPERTIES |
| AC-11 | fact_inventory_movements | Synthetic _partition_date exists; partition type=DAY on _partition_date; cluster on sku; year/month/day/region are regular INT64/STRING columns |

**Automation**: Generate a validation SQL script that queries INFORMATION_SCHEMA for each AC and returns PASS/FAIL per check. Extend `scripts/validate-all-ac.mjs` to run these checks programmatically.

### 3. Cross-Project View Validation (AC-9)
**Method**: After creating `vw_session_to_order_attribution`, inspect the view definition:
```sql
SELECT view_definition FROM retail.INFORMATION_SCHEMA.VIEWS
WHERE table_name = 'vw_session_to_order_attribution'
```
Assert the definition contains:
- `` `acme-lake-prod.raw.mobile_events` `` (cross-project reference)
- `` `acme-analytics-prod.retail.dim_customer` ``
- `` `acme-analytics-prod.retail.fact_sales` ``

**Pre-requisite**: The `acme-lake-prod.raw.mobile_events` table must exist and the analytics service account must have `roles/bigquery.dataViewer` on `acme-lake-prod.raw`. If the lake DDL from story P0 (acme-lake-prod) has not yet been applied, the view creation will fail — this is an expected dependency.

### 4. UDF Reference Validation (AC-10)
**Method**: Inspect `vw_panel_continuity_score` view definition and assert it contains `normalize_country_js(` in the JOIN ON clause.
**Pre-requisite**: The `normalize_country_js` JS UDF must be created before this view. UDF creation is part of a separate story but the DDL ordering in `00-apply-all.sql` must place UDFs before views.

### 5. Data-Survival Probes (AC-12, AC-13, AC-14)
These validate type fidelity at the data level, not just schema level.

**AC-12: DECIMAL precision (dim_payment_method.fee_pct)**
- Seed: `CAST('0.123456789012345678' AS DECIMAL(38,18))`
- Source check: Insert into Hive DECIMAL(5,4) column, read back — Hive truncates to DECIMAL(5,4) = `0.1235` (4 scale digits)
- Target check: Insert into BQ NUMERIC(5,4), read back
- Assertion: source read-back equals target read-back exactly
- **Note**: DECIMAL(5,4) can only store 4 decimal places. The seed has 18 digits but both source and target will truncate to 4 scale digits. The AC verifies that truncation behavior matches, not that all 18 digits survive.
- **Alternative interpretation**: If AC-12 intends to verify NUMERIC(38,18) fidelity, test against a BIGNUMERIC column. The validation script should test both: (a) NUMERIC(5,4) truncation parity and (b) a separate BIGNUMERIC(38,18) full-precision test.

**AC-13: TIMESTAMP precision (dim_customer.first_seen_ts)**
- Seed: `TIMESTAMP '2024-03-15 12:34:56.123456789'`
- Hive TIMESTAMP supports nanosecond precision (9 fractional digits)
- BQ DATETIME supports microsecond precision (6 fractional digits)
- **Expected behavior**: Hive stores `12:34:56.123456789` (9 digits). BQ DATETIME stores `12:34:56.123456` (6 digits, truncating nanoseconds).
- **Validation**: Document this as a known precision loss. If exact nanosecond fidelity is required, use BQ TIMESTAMP type instead (also 6 digits — BQ has no nanosecond type). The validation script should: (a) verify microsecond precision is preserved (first 6 fractional digits match), (b) flag the nanosecond truncation as an accepted deviation.

**AC-14: FLOAT64 special values (dim_warehouse.geocode.lat)**
- Seeds: NaN, +Infinity, -0.0, 0.30000000000000004
- BQ FLOAT64 supports NaN, +Inf, -Inf natively
- **Validation**: Insert each seed value, read back, compare bit-for-bit
- `-0.0` check: BQ FLOAT64 preserves IEEE 754 negative zero. Verify `1/val = -INFINITY` for -0.0.
- `0.30000000000000004` check: Verify all 17 significant digits preserved via `CAST(val AS STRING)` comparison
- **Note**: geocode.lat is inside a STRUCT. The probe must insert into the struct field: `STRUCT(seed_val AS lat, 0.0 AS lon)`.

### 6. Edge Cases and Error Handling

| Scenario | Expected Behavior | Validation |
|---|---|---|
| Duplicate CREATE (re-run DDL) | CREATE TABLE statements use `CREATE TABLE` (not IF NOT EXISTS) — re-run should fail | Verify 00-apply-all.sql uses CREATE OR REPLACE for views, plain CREATE for tables |
| Empty table schemas | All 52 tables created with correct schema even with zero rows | INFORMATION_SCHEMA check confirms column count per table |
| Reserved word columns | No BQ reserved words in column names (verified: none found in source) | Static analysis of generated DDL |
| Partition column placement | BQ requires partition column to be at the end of column list or use PARTITION BY expression | Verify generated DDL puts partition columns correctly |
| NUMERIC precision overflow | DECIMAL(38,18) in source exceeds BQ NUMERIC(38,9) max scale | Use BIGNUMERIC for any column with scale > 9. Current schema: max scale is 4 (fee_pct DECIMAL(5,4), margin_pct DECIMAL(5,4), on_time_pct DECIMAL(5,4)) — all within NUMERIC range |

### 7. Validation Script Structure
```
scripts/
  validate-bq-ddl.mjs          (existing — extend)
  validate-all-ac.mjs           (existing — extend)
  validate-schema-metadata.sql  (new — INFORMATION_SCHEMA queries per AC)
  validate-data-probes.sql      (new — INSERT + SELECT round-trip for AC-12,13,14)
```
