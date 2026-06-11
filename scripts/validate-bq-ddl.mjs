// Validate all staging tables + views by creating them in the test dataset
// and then cleaning up.

import { createRequire } from 'module';
const require = createRequire('/opt/workspace-mcp/node_modules/.package-lock.json');
const { BigQuery } = require('@google-cloud/bigquery');
const { OAuth2Client } = require('google-auth-library');

const authClient = new OAuth2Client();
authClient.setCredentials({ access_token: process.env.CLD_BQ_TOKEN });
const bq = new BigQuery({ projectId: process.env.CLD_BQ_PROJECT, authClient });

const dataset = 'test';

// All remaining staging tables + views to validate
const ddlStatements = [
  // Staging tables not yet validated
  {
    name: 'stg__parsed_loyalty_events',
    ddl: `CREATE TABLE \`${dataset}.stg__parsed_loyalty_events\` (
      event_ts DATETIME, member_id STRING, event_type STRING,
      points INT64, store_id STRING, tx_id STRING, meta JSON, date_ts STRING
    ) PARTITION BY DATE(_PARTITIONTIME)`
  },
  {
    name: 'stg__merged_returns_cdc',
    ddl: `CREATE TABLE \`${dataset}.stg__merged_returns_cdc\` (
      return_id INT64, invoice_no STRING, customer_sk INT64,
      return_ts DATETIME, refund_amount NUMERIC(12,2),
      reason_code STRING, status STRING, is_deleted BOOL, snapshot_date DATE
    ) PARTITION BY snapshot_date`
  },
  {
    name: 'stg__normalized_carrier_events',
    ddl: `CREATE TABLE \`${dataset}.stg__normalized_carrier_events\` (
      tracking_no STRING, carrier STRING, event_type STRING,
      event_ts DATETIME, location_city STRING, location_region STRING,
      location_country STRING, date_ts STRING
    ) PARTITION BY DATE(_PARTITIONTIME)`
  },
  {
    name: 'stg__fraud_scored',
    ddl: `CREATE TABLE \`${dataset}.stg__fraud_scored\` (
      txn_id INT64, customer_id STRING, fraud_score NUMERIC(5,4),
      risk_band STRING, signals ARRAY<STRING>, scored_at DATETIME, score_date DATE
    ) PARTITION BY score_date`
  },
  {
    name: 'stg__warehouse_kpi_snapshot',
    ddl: `CREATE TABLE \`${dataset}.stg__warehouse_kpi_snapshot\` (
      warehouse_id STRING, snapshot_ts DATETIME, units_in INT64,
      units_picked INT64, units_shipped INT64, pick_rate_uph NUMERIC(8,2),
      backlog_units INT64, avg_pick_ms INT64, date_ts STRING
    ) PARTITION BY DATE(_PARTITIONTIME)`
  },
  // Views - need base tables first, so test with test dataset references
  {
    name: 'raw__omniture_view',
    ddl: `CREATE OR REPLACE VIEW \`${dataset}.raw__omniture_view\` AS
      SELECT col_2 AS event_ts, col_8 AS ip, col_13 AS url,
             col_14 AS user_id, col_50 AS city, col_51 AS country,
             col_53 AS state, date_ts
      FROM \`${dataset}.stg__view_base_omniture\``
  },
  {
    name: 'stg__v_returns_pending_view',
    ddl: `CREATE OR REPLACE VIEW \`${dataset}.stg__v_returns_pending_view\` AS
      SELECT r.rma_id, r.customer_id, r.invoice_no, r.stock_code,
             r.quantity, r.requested_at,
             DATE_DIFF(CURRENT_DATE(), DATE(r.requested_at), DAY) AS days_pending
      FROM \`${dataset}.stg__view_base_returns\` r
      WHERE r.approved IS NULL OR r.approved = FALSE`
  },
  {
    name: 'raw__v_fraud_signals_recent_view',
    ddl: `CREATE OR REPLACE VIEW \`${dataset}.raw__v_fraud_signals_recent_view\` AS
      SELECT * FROM \`${dataset}.stg__view_base_fraud\`
      WHERE signal_date >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))`
  }
];

// Base tables needed for view validation
const baseTables = [
  {
    name: 'stg__view_base_omniture',
    ddl: `CREATE TABLE \`${dataset}.stg__view_base_omniture\` (
      col_1 STRING, col_2 STRING, col_3 STRING, col_4 STRING, col_5 STRING,
      col_6 STRING, col_7 STRING, col_8 STRING, col_9 STRING, col_10 STRING,
      col_11 STRING, col_12 STRING, col_13 STRING, col_14 STRING, col_15 STRING,
      col_16 STRING, col_17 STRING, col_18 STRING, col_19 STRING, col_20 STRING,
      col_21 STRING, col_22 STRING, col_23 STRING, col_24 STRING, col_25 STRING,
      col_26 STRING, col_27 STRING, col_28 STRING, col_29 STRING, col_30 STRING,
      col_31 STRING, col_32 STRING, col_33 STRING, col_34 STRING, col_35 STRING,
      col_36 STRING, col_37 STRING, col_38 STRING, col_39 STRING, col_40 STRING,
      col_41 STRING, col_42 STRING, col_43 STRING, col_44 STRING, col_45 STRING,
      col_46 STRING, col_47 STRING, col_48 STRING, col_49 STRING, col_50 STRING,
      col_51 STRING, col_52 STRING, col_53 STRING, col_54 STRING, col_55 STRING,
      col_56 STRING, col_57 STRING, col_58 STRING, col_59 STRING, col_60 STRING,
      date_ts STRING
    )`
  },
  {
    name: 'stg__view_base_returns',
    ddl: `CREATE TABLE \`${dataset}.stg__view_base_returns\` (
      rma_id STRING, customer_id STRING, invoice_no STRING, stock_code STRING,
      quantity INT64, reason_code STRING, reason_text STRING,
      requested_at DATETIME, approved BOOL, refund_amount NUMERIC(12,2), date_ts STRING
    ) PARTITION BY DATE(_PARTITIONTIME)`
  },
  {
    name: 'stg__view_base_fraud',
    ddl: `CREATE TABLE \`${dataset}.stg__view_base_fraud\` (
      customer_id STRING, signal_type STRING, score FLOAT64, risk_band STRING,
      reason_codes ARRAY<STRING>, signal_ts TIMESTAMP, vendor STRING, signal_date STRING
    ) PARTITION BY DATE(_PARTITIONTIME)`
  }
];

async function run() {
  let passed = 0;
  let failed = 0;
  const allObjects = [];

  // Create base tables for views first
  console.log('=== Creating base tables for view validation ===');
  for (const bt of baseTables) {
    try {
      await bq.query({ query: `DROP TABLE IF EXISTS \`${dataset}.${bt.name}\``, useLegacySql: false });
      await bq.query({ query: bt.ddl, useLegacySql: false });
      console.log(`  ✓ base: ${bt.name}`);
    } catch (e) {
      console.error(`  ✗ base: ${bt.name} — ${e.message}`);
    }
  }

  // Create staging tables and views
  console.log('\n=== Validating staging tables and views ===');
  for (const stmt of ddlStatements) {
    try {
      await bq.query({ query: `DROP TABLE IF EXISTS \`${dataset}.${stmt.name}\``, useLegacySql: false });
      await bq.query({ query: `DROP VIEW IF EXISTS \`${dataset}.${stmt.name}\``, useLegacySql: false });
      await bq.query({ query: stmt.ddl, useLegacySql: false });
      console.log(`  ✓ ${stmt.name}`);
      passed++;
      allObjects.push(stmt.name);
    } catch (e) {
      console.error(`  ✗ ${stmt.name} — ${e.message}`);
      failed++;
    }
  }

  // Describe key tables to verify schema
  console.log('\n=== Schema verification for key tables ===');
  for (const tbl of ['stg__fraud_scored', 'stg__merged_returns_cdc', 'stg__warehouse_kpi_snapshot']) {
    try {
      const [metadata] = await bq.dataset(dataset).table(tbl).getMetadata();
      const fields = metadata.schema.fields.map(f => `${f.name} ${f.type}${f.mode === 'REPEATED' ? ' REPEATED' : ''}`);
      console.log(`  ${tbl}: ${fields.join(', ')}`);
    } catch (e) {
      console.error(`  ✗ describe ${tbl}: ${e.message}`);
    }
  }

  // Cleanup
  console.log('\n=== Cleanup ===');
  // Drop views first (they depend on tables)
  for (const stmt of ddlStatements) {
    if (stmt.name.includes('view')) {
      try {
        await bq.query({ query: `DROP VIEW IF EXISTS \`${dataset}.${stmt.name}\``, useLegacySql: false });
      } catch (e) { /* ignore */ }
    }
  }
  // Drop tables
  const allTables = [...ddlStatements.filter(s => !s.name.includes('view')), ...baseTables];
  for (const stmt of allTables) {
    try {
      await bq.query({ query: `DROP TABLE IF EXISTS \`${dataset}.${stmt.name}\``, useLegacySql: false });
    } catch (e) { /* ignore */ }
  }
  // Also drop test tables from step 1 validation that ran via MCP
  const step1Tables = [
    'stg__cleansed_orders', 'stg__cleansed_customers', 'stg__cleansed_products',
    'stg__dedup_clickstream', 'stg__geocoded_addresses'
  ];
  for (const t of step1Tables) {
    try {
      await bq.query({ query: `DROP TABLE IF EXISTS \`${dataset}.${t}\``, useLegacySql: false });
    } catch (e) { /* ignore */ }
  }
  console.log('  Cleanup complete.');

  console.log(`\n=== RESULTS: ${passed} passed, ${failed} failed ===`);
  if (failed > 0) process.exit(1);
}

run().catch(e => { console.error(e); process.exit(1); });
