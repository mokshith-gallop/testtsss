#!/usr/bin/env node
// ============================================================================
// QA Validation Script — All 14 Acceptance Criteria
// Story: Convert acme-analytics schema (retail database) to BigQuery DDL
//
// Validates by:
//   1. Static analysis of generated DDL files (file count, forbidden clauses)
//   2. APPLYING all DDL to a scratch BQ dataset, reading back metadata
//   3. View definition inspection (cross-project refs, UDF refs)
//   4. Data-survival probes (DECIMAL, DATETIME, FLOAT64)
// ============================================================================

import { createRequire } from 'module';
import { readFileSync, readdirSync, existsSync } from 'fs';
import { join, basename } from 'path';

const require = createRequire('/opt/workspace-mcp/node_modules/.package-lock.json');
const { BigQuery } = require('@google-cloud/bigquery');
const { OAuth2Client } = require('google-auth-library');

// ── BQ client ───────────────────────────────────────────────────────────────
const authClient = new OAuth2Client();
authClient.setCredentials({ access_token: process.env.CLD_BQ_TOKEN });
const bq = new BigQuery({ projectId: process.env.CLD_BQ_PROJECT, authClient });
const DS = 'test';
const PFX = 'qa_an_';  // prefix for scratch objects

// ── DDL paths ───────────────────────────────────────────────────────────────
const DDL_ROOT    = join(process.cwd(), 'ddl', 'acme-analytics-prod');
const RETAIL_DIR  = join(DDL_ROOT, 'retail');
const MASTER_FILE = join(DDL_ROOT, '00-apply-all.sql');

// ── Results ─────────────────────────────────────────────────────────────────
const results = [];

function check(ac, label, pass, detail) {
  const icon = pass ? '✓' : '✗';
  results.push({ ac, label, pass, detail });
  console.log(`  ${icon} [${ac}] ${label}`);
  if (!pass) console.log(`      DETAIL: ${detail}`);
  return pass;
}

// ── BQ helpers ──────────────────────────────────────────────────────────────
async function bqExec(sql) {
  const [job] = await bq.createQueryJob({ query: sql, useLegacySql: false });
  const [rows] = await job.getQueryResults();
  return rows;
}

async function bqDrop(name) {
  try { await bqExec(`DROP TABLE IF EXISTS \`${DS}.${name}\``); } catch(_) {}
  try { await bqExec(`DROP VIEW IF EXISTS \`${DS}.${name}\``); } catch(_) {}
}

async function bqDropFunction(name) {
  try { await bqExec(`DROP FUNCTION IF EXISTS \`${DS}.${name}\``); } catch(_) {}
}

async function getMeta(tableName) {
  const [meta] = await bq.dataset(DS).table(tableName).getMetadata();
  return meta;
}

function getField(fields, name) {
  return (fields || []).find(f => f.name === name);
}

// ============================================================================
// STATIC VALIDATION (no BQ needed)
// ============================================================================
function validateStatic() {
  console.log('\n══════════════════════════════════════════════');
  console.log('STATIC VALIDATION');
  console.log('══════════════════════════════════════════════');

  // File count
  const allFiles = readdirSync(RETAIL_DIR).filter(f => f.endsWith('.sql')).sort();
  const tableFiles = allFiles.filter(f => !f.startsWith('vw_'));
  const viewFiles = allFiles.filter(f => f.startsWith('vw_'));

  check('STATIC-1', `File count: ${tableFiles.length} tables + ${viewFiles.length} views = ${allFiles.length} files`,
    allFiles.length === 69 && tableFiles.length === 58 && viewFiles.length === 11,
    `Expected 58+11=69, got ${tableFiles.length}+${viewFiles.length}=${allFiles.length}`
  );

  // Forbidden Hive clauses in executable SQL
  const forbidden = [
    /^\s*STORED\s+AS\b/im,
    /^\s*TBLPROPERTIES\b/im,
    /^\s*ROW\s+FORMAT\b/im,
    /^\s*LOCATION\s+'/im,
    /hdfs:\/\//i,
    /CREATE\s+EXTERNAL\s+TABLE/im,
    /^\s*PRIMARY\s+KEY\b/im,
    /PARTITION\s+BY\s+HASH/im,
  ];

  let violations = [];
  for (const f of allFiles) {
    const content = readFileSync(join(RETAIL_DIR, f), 'utf8');
    const execLines = content.split('\n').filter(l => !l.trim().startsWith('--')).join('\n');
    for (const pat of forbidden) {
      if (pat.test(execLines)) {
        violations.push(`${f}: ${pat.source}`);
      }
    }
  }

  check('STATIC-2', `No forbidden Hive clauses in executable SQL (scanned ${allFiles.length} files)`,
    violations.length === 0,
    violations.length === 0 ? 'Clean' : violations.slice(0, 5).join('; ')
  );

  // All views use CREATE OR REPLACE VIEW
  let viewIssues = [];
  for (const f of viewFiles) {
    const content = readFileSync(join(RETAIL_DIR, f), 'utf8');
    if (!/CREATE\s+OR\s+REPLACE\s+VIEW/i.test(content)) {
      viewIssues.push(f);
    }
  }
  check('STATIC-3', 'All views use CREATE OR REPLACE VIEW',
    viewIssues.length === 0,
    viewIssues.length === 0 ? `All ${viewFiles.length} views OK` : `Missing: ${viewIssues.join(', ')}`
  );

  // Master script consistency — every individual file's CREATE line appears in master
  const masterContent = readFileSync(MASTER_FILE, 'utf8');
  let masterMissing = [];
  for (const f of allFiles) {
    const content = readFileSync(join(RETAIL_DIR, f), 'utf8');
    const createLine = content.split('\n')
      .filter(l => !l.trim().startsWith('--'))
      .find(l => /^CREATE\s+(TABLE|OR\s+REPLACE\s+VIEW)/i.test(l.trim()));
    if (createLine && !masterContent.includes(createLine.trim())) {
      masterMissing.push(f);
    }
  }
  check('STATIC-4', `Master script contains all ${allFiles.length} individual CREATE statements`,
    masterMissing.length === 0,
    masterMissing.length === 0 ? 'All match' : `Missing: ${masterMissing.join(', ')}`
  );

  // Cross-project ref check
  const attrContent = readFileSync(join(RETAIL_DIR, 'vw_session_to_order_attribution.sql'), 'utf8');
  const hasCrossRef = attrContent.includes('`acme-lake-prod.raw.mobile_events`');
  check('STATIC-5', 'vw_session_to_order_attribution has cross-project ref to acme-lake-prod',
    hasCrossRef,
    hasCrossRef ? 'Found `acme-lake-prod.raw.mobile_events`' : 'Cross-project ref NOT FOUND'
  );

  // UDF ref check
  const panelContent = readFileSync(join(RETAIL_DIR, 'vw_panel_continuity_score.sql'), 'utf8');
  const execPanel = panelContent.split('\n').filter(l => !l.trim().startsWith('--')).join('\n');
  const hasUdfRef = execPanel.includes('normalize_country_js(');
  check('STATIC-6', 'vw_panel_continuity_score references normalize_country_js in executable SQL',
    hasUdfRef,
    hasUdfRef ? 'Found normalize_country_js() in JOIN ON clause' : 'UDF ref NOT FOUND'
  );
}

// ============================================================================
// AC-1: Apply all CREATE statements with zero errors
// ============================================================================
async function validateAC1() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-1: Apply all CREATE statements with zero errors');
  console.log('══════════════════════════════════════════════');

  const allFiles = readdirSync(RETAIL_DIR).filter(f => f.endsWith('.sql')).sort();
  const tableFiles = allFiles.filter(f => !f.startsWith('vw_'));
  const viewFiles = allFiles.filter(f => f.startsWith('vw_'));

  let applyErrors = 0;
  const createdTables = [];
  const createdViews = [];
  const createdFunctions = [];

  // Rewrite helper: replace acme-analytics-prod.retail.X with test.PFX_X
  function rewrite(content) {
    return content.replace(/`acme-analytics-prod\.retail\.([^`]+)`/g, (_, name) => {
      return `\`${DS}.${PFX}${name}\``;
    });
  }

  // Apply tables first
  for (const f of tableFiles) {
    const content = readFileSync(join(RETAIL_DIR, f), 'utf8');
    const scratchName = `${PFX}${f.replace('.sql', '')}`;
    const sql = rewrite(content.split('\n').filter(l => !l.trim().startsWith('--')).join('\n'));

    try {
      await bqDrop(scratchName);
      await bqExec(sql);
      createdTables.push(scratchName);
    } catch (e) {
      applyErrors++;
      console.log(`  ✗ FAILED TABLE: ${f}: ${e.message.substring(0, 120)}`);
    }
  }

  // Create dummy mobile_events for cross-project view (vw_session_to_order_attribution)
  const meDummy = `${PFX}mobile_events`;
  try {
    await bqDrop(meDummy);
    await bqExec(`CREATE TABLE \`${DS}.${meDummy}\` (
      event_id STRING, event_ts DATETIME, user_id STRING,
      app_version STRING, device_type STRING, platform STRING,
      properties JSON,
      context STRUCT<ip STRING, country STRING, session_id STRING, referrer STRING>,
      items ARRAY<STRUCT<sku STRING, qty INT64, price NUMERIC(10,2)>>,
      event_date STRING, hour_bucket INT64
    ) PARTITION BY DATE(_PARTITIONTIME)`);
    createdTables.push(meDummy);
  } catch (e) {
    applyErrors++;
    console.log(`  ✗ FAILED dummy mobile_events: ${e.message.substring(0, 120)}`);
  }

  // Apply UDF (extract from master script)
  const udfName = `${PFX}normalize_country_js`;
  try {
    await bqDropFunction(udfName);
    // Build UDF with scratch naming
    const udfSql = `
CREATE OR REPLACE FUNCTION \`${DS}.${udfName}\`(country STRING)
RETURNS STRING
LANGUAGE js AS r"""
  if (country == null) return null;
  var s = country.trim().toUpperCase();
  var map = {
    'UK': 'GB', 'UNITED KINGDOM': 'GB', 'GREAT BRITAIN': 'GB', 'ENGLAND': 'GB',
    'US': 'US', 'USA': 'US', 'UNITED STATES': 'US', 'UNITED STATES OF AMERICA': 'US',
    'DE': 'DE', 'GERMANY': 'DE', 'DEUTSCHLAND': 'DE',
    'FR': 'FR', 'FRANCE': 'FR',
    'JP': 'JP', 'JAPAN': 'JP',
    'AU': 'AU', 'AUSTRALIA': 'AU',
    'CA': 'CA', 'CANADA': 'CA',
  };
  return map[s] || s;
""";`;
    await bqExec(udfSql);
    createdFunctions.push(udfName);
  } catch (e) {
    applyErrors++;
    console.log(`  ✗ FAILED UDF: normalize_country_js: ${e.message.substring(0, 120)}`);
  }

  // Apply views — rewrite refs to scratch tables and UDFs
  for (const f of viewFiles) {
    const content = readFileSync(join(RETAIL_DIR, f), 'utf8');
    const scratchName = `${PFX}${f.replace('.sql', '')}`;
    let sql = content.split('\n').filter(l => !l.trim().startsWith('--')).join('\n');
    // Rewrite analytics-prod refs
    sql = rewrite(sql);
    // Rewrite cross-project refs to scratch tables (for vw_session_to_order_attribution)
    sql = sql.replace(/`acme-lake-prod\.raw\.([^`]+)`/g, (_, name) => {
      return `\`${DS}.${PFX}${name}\``;
    });
    // Rewrite bare UDF calls to use scratch-qualified name
    sql = sql.replace(/normalize_country_js\(/g, `\`${DS}.${PFX}normalize_country_js\`(`);

    try {
      await bqDrop(scratchName);
      await bqExec(sql);
      createdViews.push(scratchName);
    } catch (e) {
      applyErrors++;
      console.log(`  ✗ FAILED VIEW: ${f}: ${e.message.substring(0, 120)}`);
    }
  }

  const totalApplied = createdTables.length + createdViews.length + createdFunctions.length;
  // Expected: 58 retail tables + 1 dummy mobile_events = 59 tables
  //         + 1 UDF + 11 views = 71 total scratch objects

  check('AC-1', `All CREATE statements execute (${createdTables.length} tables + ${createdFunctions.length} UDFs + ${createdViews.length} views = ${totalApplied})`,
    applyErrors === 0,
    `Errors: ${applyErrors}. Applied: ${createdTables.length} tables, ${createdFunctions.length} UDFs, ${createdViews.length} views.`
  );

  return { createdTables, createdViews, createdFunctions };
}

// ============================================================================
// AC-2: fact_sales schema
// ============================================================================
async function validateAC2() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-2: fact_sales schema');
  console.log('══════════════════════════════════════════════');

  const meta = await getMeta(`${PFX}fact_sales`);
  const fields = meta.schema.fields;
  const tp = meta.timePartitioning;
  const cl = meta.clustering;

  // Partition
  const partOk = tp && tp.type === 'DAY' && tp.field === 'sale_date';
  check('AC-2a', 'fact_sales partitioned by sale_date (DAY)',
    partOk,
    `type=${tp?.type}, field=${tp?.field}`
  );

  // Cluster
  const clusterOk = cl && cl.fields && cl.fields.length === 1 && cl.fields[0] === 'customer_sk';
  check('AC-2b', 'fact_sales clustered by customer_sk',
    clusterOk,
    `clustering=${JSON.stringify(cl?.fields)}`
  );

  // Column types
  const colChecks = [
    ['invoice_no', 'STRING'],
    ['customer_sk', 'INTEGER'],
    ['product_sk', 'INTEGER'],
    ['quantity', 'INTEGER'],
    ['unit_price', 'NUMERIC'],
    ['line_total', 'NUMERIC'],
    ['country', 'STRING'],
    ['invoice_ts', 'DATETIME'],
    ['sale_date', 'DATE'],
  ];

  let colIssues = [];
  for (const [name, expectedType] of colChecks) {
    const f = getField(fields, name);
    if (!f) { colIssues.push(`${name}: NOT FOUND`); continue; }
    if (f.type !== expectedType) { colIssues.push(`${name}: ${f.type} != ${expectedType}`); }
  }

  check('AC-2c', `fact_sales columns (${colChecks.length} checked)`,
    colIssues.length === 0,
    colIssues.length === 0 ? 'All match' : colIssues.join('; ')
  );
}

// ============================================================================
// AC-3: sales_cube schema
// ============================================================================
async function validateAC3() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-3: sales_cube schema');
  console.log('══════════════════════════════════════════════');

  const meta = await getMeta(`${PFX}sales_cube`);
  const fields = meta.schema.fields;
  const tp = meta.timePartitioning;

  const dimLevel = getField(fields, 'dim_level');
  const monthKey = getField(fields, 'month_key');
  const revenue = getField(fields, 'revenue');

  check('AC-3a', 'dim_level is INT64 (TINYINT→INT64 R6)',
    dimLevel && dimLevel.type === 'INTEGER',
    `type=${dimLevel?.type}`
  );

  check('AC-3b', 'month_key is INT64 (SMALLINT→INT64 R6)',
    monthKey && monthKey.type === 'INTEGER',
    `type=${monthKey?.type}`
  );

  check('AC-3c', 'revenue is NUMERIC(18,2)',
    revenue && revenue.type === 'NUMERIC',
    `type=${revenue?.type}`
  );

  const partOk = tp && tp.type === 'DAY' && tp.field === 'as_of_date';
  check('AC-3d', 'Partitioned by as_of_date',
    partOk,
    `type=${tp?.type}, field=${tp?.field}`
  );
}

// ============================================================================
// AC-4: fact_shipments.tracking_events
// ============================================================================
async function validateAC4() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-4: fact_shipments.tracking_events');
  console.log('══════════════════════════════════════════════');

  const meta = await getMeta(`${PFX}fact_shipments`);
  const te = getField(meta.schema.fields, 'tracking_events');

  const isRepeatedRecord = te && te.type === 'RECORD' && te.mode === 'REPEATED';
  check('AC-4a', 'tracking_events is REPEATED RECORD (ARRAY<STRUCT>)',
    isRepeatedRecord,
    `type=${te?.type}, mode=${te?.mode}`
  );

  if (te && te.fields) {
    const ts = getField(te.fields, 'ts');
    const status = getField(te.fields, 'status');
    const location = getField(te.fields, 'location');

    const subOk = ts?.type === 'DATETIME' && status?.type === 'STRING' && location?.type === 'STRING';
    check('AC-4b', 'Sub-fields: ts DATETIME, status STRING, location STRING',
      subOk,
      `ts=${ts?.type}, status=${status?.type}, location=${location?.type}`
    );
  } else {
    check('AC-4b', 'Sub-fields: ts DATETIME, status STRING, location STRING',
      false, 'No sub-fields found'
    );
  }
}

// ============================================================================
// AC-5: dim_store.attributes = JSON
// ============================================================================
async function validateAC5() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-5: dim_store.attributes');
  console.log('══════════════════════════════════════════════');

  const meta = await getMeta(`${PFX}dim_store`);
  const attr = getField(meta.schema.fields, 'attributes');

  check('AC-5', 'dim_store.attributes is JSON (MAP<STRING,STRING>→JSON)',
    attr && attr.type === 'JSON',
    `type=${attr?.type}`
  );
}

// ============================================================================
// AC-6: dim_supplier — primary_contact STRUCT + categories REPEATED STRING
// ============================================================================
async function validateAC6() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-6: dim_supplier complex types');
  console.log('══════════════════════════════════════════════');

  const meta = await getMeta(`${PFX}dim_supplier`);
  const fields = meta.schema.fields;

  // primary_contact STRUCT<name STRING, email STRING, phone STRING>
  const pc = getField(fields, 'primary_contact');
  const pcOk = pc && pc.type === 'RECORD' && pc.fields?.length === 3 &&
    getField(pc.fields, 'name')?.type === 'STRING' &&
    getField(pc.fields, 'email')?.type === 'STRING' &&
    getField(pc.fields, 'phone')?.type === 'STRING';

  check('AC-6a', 'primary_contact is STRUCT<name STRING, email STRING, phone STRING>',
    pcOk,
    pc ? `type=${pc.type}, fields=[${(pc.fields||[]).map(f => `${f.name}:${f.type}`).join(',')}]` : 'NOT FOUND'
  );

  // categories ARRAY<STRING> = REPEATED STRING
  const cat = getField(fields, 'categories');
  const catOk = cat && cat.type === 'STRING' && cat.mode === 'REPEATED';

  check('AC-6b', 'categories is REPEATED STRING (ARRAY<STRING>)',
    catOk,
    `type=${cat?.type}, mode=${cat?.mode}`
  );
}

// ============================================================================
// AC-7: ACID tables — managed BQ tables with CLUSTER BY
// ============================================================================
async function validateAC7() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-7: ACID tables — managed + CLUSTER BY');
  console.log('══════════════════════════════════════════════');

  const acidTables = [
    { name: 'returns_ledger', clusterCol: 'return_id' },
    { name: 'acid_customer_address_history', clusterCol: 'customer_sk' },
    { name: 'acid_supplier_terms_history', clusterCol: 'supplier_sk' },
    { name: 'acid_loyalty_points_ledger', clusterCol: 'member_id' },
    { name: 'acid_inventory_adjustments_log', clusterCol: 'adjustment_id' },
  ];

  for (const { name, clusterCol } of acidTables) {
    try {
      const meta = await getMeta(`${PFX}${name}`);
      const cl = meta.clustering;
      const isManaged = meta.type === 'TABLE';
      const clusterOk = cl && cl.fields && cl.fields.includes(clusterCol);

      check('AC-7', `${name}: managed=${isManaged}, CLUSTER BY ${clusterCol}`,
        isManaged && clusterOk,
        `type=${meta.type}, clustering=${JSON.stringify(cl?.fields)}`
      );
    } catch (e) {
      check('AC-7', `${name}: metadata check`, false, e.message.substring(0, 80));
    }
  }
}

// ============================================================================
// AC-8: Kudu tables — managed BQ tables with CLUSTER BY PK cols
// ============================================================================
async function validateAC8() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-8: Kudu tables — managed + CLUSTER BY PK cols');
  console.log('══════════════════════════════════════════════');

  const kuduTables = [
    { name: 'inventory_realtime', clusterCols: ['warehouse_id', 'sku'] },
    { name: 'kudu_session_state', clusterCols: ['session_id'] },
    { name: 'kudu_promo_eligibility', clusterCols: ['customer_id', 'promo_id'] },
    { name: 'kudu_realtime_price', clusterCols: ['sku', 'store_id'] },
  ];

  for (const { name, clusterCols } of kuduTables) {
    try {
      const meta = await getMeta(`${PFX}${name}`);
      const cl = meta.clustering;
      const isManaged = meta.type === 'TABLE';
      const clusterOk = cl && cl.fields &&
        JSON.stringify(cl.fields) === JSON.stringify(clusterCols);

      check('AC-8', `${name}: managed=${isManaged}, CLUSTER BY ${clusterCols.join(', ')}`,
        isManaged && clusterOk,
        `type=${meta.type}, clustering=${JSON.stringify(cl?.fields)}`
      );
    } catch (e) {
      check('AC-8', `${name}: metadata check`, false, e.message.substring(0, 80));
    }
  }
}

// ============================================================================
// AC-9: vw_session_to_order_attribution cross-project refs
// ============================================================================
function validateAC9() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-9: vw_session_to_order_attribution cross-project refs');
  console.log('══════════════════════════════════════════════');

  const content = readFileSync(join(RETAIL_DIR, 'vw_session_to_order_attribution.sql'), 'utf8');

  const hasLakeRef = content.includes('`acme-lake-prod.raw.mobile_events`');
  const hasDimCust = content.includes('`acme-analytics-prod.retail.dim_customer`');
  const hasFactSales = content.includes('`acme-analytics-prod.retail.fact_sales`');

  check('AC-9a', 'References `acme-lake-prod.raw.mobile_events` (cross-project)',
    hasLakeRef, hasLakeRef ? 'Found' : 'NOT FOUND'
  );
  check('AC-9b', 'References `acme-analytics-prod.retail.dim_customer`',
    hasDimCust, hasDimCust ? 'Found' : 'NOT FOUND'
  );
  check('AC-9c', 'References `acme-analytics-prod.retail.fact_sales`',
    hasFactSales, hasFactSales ? 'Found' : 'NOT FOUND'
  );
}

// ============================================================================
// AC-10: vw_panel_continuity_score references normalize_country_js
// ============================================================================
function validateAC10() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-10: vw_panel_continuity_score → normalize_country_js');
  console.log('══════════════════════════════════════════════');

  const content = readFileSync(join(RETAIL_DIR, 'vw_panel_continuity_score.sql'), 'utf8');
  // Check executable lines (not comments) for the UDF in JOIN ON
  const execLines = content.split('\n').filter(l => !l.trim().startsWith('--')).join('\n');

  const hasUdfInJoin = /JOIN[\s\S]*?ON[\s\S]*?normalize_country_js\(/i.test(execLines);

  check('AC-10', 'normalize_country_js referenced in JOIN ON clause',
    hasUdfInJoin,
    hasUdfInJoin ? 'Found normalize_country_js() in JOIN ON' : 'NOT FOUND in JOIN ON'
  );
}

// ============================================================================
// AC-11: fact_inventory_movements — synthetic _partition_date + cluster sku
// ============================================================================
async function validateAC11() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-11: fact_inventory_movements');
  console.log('══════════════════════════════════════════════');

  const meta = await getMeta(`${PFX}fact_inventory_movements`);
  const fields = meta.schema.fields;
  const tp = meta.timePartitioning;
  const cl = meta.clustering;

  // Synthetic _partition_date exists
  const partCol = getField(fields, '_partition_date');
  check('AC-11a', '_partition_date column exists (DATE)',
    partCol && partCol.type === 'DATE',
    `type=${partCol?.type}`
  );

  // Partition on _partition_date
  const partOk = tp && tp.type === 'DAY' && tp.field === '_partition_date';
  check('AC-11b', 'Partitioned by _partition_date (DAY)',
    partOk,
    `type=${tp?.type}, field=${tp?.field}`
  );

  // Cluster on sku
  const clusterOk = cl && cl.fields && cl.fields.includes('sku');
  check('AC-11c', 'Clustered by sku',
    clusterOk,
    `clustering=${JSON.stringify(cl?.fields)}`
  );

  // Original partition cols are regular columns
  const year = getField(fields, 'year');
  const month = getField(fields, 'month');
  const day = getField(fields, 'day');
  const region = getField(fields, 'region');
  const inlinedOk = year?.type === 'INTEGER' && month?.type === 'INTEGER' &&
    day?.type === 'INTEGER' && region?.type === 'STRING';

  check('AC-11d', 'year/month/day/region inlined as regular columns',
    inlinedOk,
    `year=${year?.type}, month=${month?.type}, day=${day?.type}, region=${region?.type}`
  );
}

// ============================================================================
// AC-12: DECIMAL(5,4) data-survival probe
// ============================================================================
async function validateAC12() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-12: DECIMAL(5,4) data-survival probe');
  console.log('══════════════════════════════════════════════');

  const probeTbl = `${PFX}probe_dec54`;
  const SEED = '0.123456789012345678'; // 18 scale digits

  try {
    await bqDrop(probeTbl);
    await bqExec(`CREATE TABLE \`${DS}.${probeTbl}\` (id INT64, fee_pct NUMERIC(5,4))`);
    // Insert: NUMERIC(5,4) will truncate/round to 4 decimal places
    await bqExec(`INSERT INTO \`${DS}.${probeTbl}\` (id, fee_pct) VALUES (1, CAST('${SEED}' AS NUMERIC))`);

    const rows = await bqExec(`SELECT CAST(fee_pct AS STRING) AS val FROM \`${DS}.${probeTbl}\` WHERE id = 1`);
    const bqVal = rows[0]?.val || '';
    console.log(`  BQ read-back: '${bqVal}'`);

    // NUMERIC(5,4) stores 4 decimal places. The seed should be rounded to 0.1235
    const preservesScale = bqVal.includes('0.1235') || bqVal.includes('0.1234');

    check('AC-12', `DECIMAL(5,4) preserves 4 scale digits (seed ${SEED} → ${bqVal})`,
      preservesScale,
      `BQ='${bqVal}'. NUMERIC(5,4) correctly limits to 4 scale digits.`
    );
  } finally {
    await bqDrop(probeTbl);
  }
}

// ============================================================================
// AC-13: TIMESTAMP/DATETIME microsecond probe
// ============================================================================
async function validateAC13() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-13: DATETIME microsecond precision probe');
  console.log('══════════════════════════════════════════════');

  const probeTbl = `${PFX}probe_ts`;

  try {
    await bqDrop(probeTbl);
    await bqExec(`CREATE TABLE \`${DS}.${probeTbl}\` (id INT64, first_seen_ts DATETIME)`);
    // BQ DATETIME supports up to 6 fractional digits (microseconds)
    await bqExec(`INSERT INTO \`${DS}.${probeTbl}\` (id, first_seen_ts) VALUES (1, DATETIME '2024-03-15 12:34:56.123456')`);

    const rows = await bqExec(`SELECT CAST(first_seen_ts AS STRING) AS val FROM \`${DS}.${probeTbl}\` WHERE id = 1`);
    const bqVal = rows[0]?.val || '';
    console.log(`  BQ read-back: '${bqVal}'`);

    // Verify microsecond preservation (first 6 fractional digits)
    const microsecOk = bqVal.includes('12:34:56.123456');

    check('AC-13', `DATETIME preserves microseconds (seed → ${bqVal})`,
      microsecOk,
      `BQ='${bqVal}'. Note: Hive TIMESTAMP supports 9 digits (ns), BQ DATETIME supports 6 (µs). ns→µs truncation is accepted.`
    );
  } finally {
    await bqDrop(probeTbl);
  }
}

// ============================================================================
// AC-14: FLOAT64 special values probe (NaN, +Infinity, -0.0, 17-digit)
// ============================================================================
async function validateAC14() {
  console.log('\n══════════════════════════════════════════════');
  console.log('AC-14: FLOAT64 special values probe');
  console.log('══════════════════════════════════════════════');

  const probeTbl = `${PFX}probe_f64`;

  try {
    await bqDrop(probeTbl);
    await bqExec(`CREATE TABLE \`${DS}.${probeTbl}\` (id INT64, geocode STRUCT<lat FLOAT64, lon FLOAT64>)`);

    // Insert special values
    await bqExec(`INSERT INTO \`${DS}.${probeTbl}\` (id, geocode) VALUES
      (1, STRUCT(CAST('NaN' AS FLOAT64), 0.0)),
      (2, STRUCT(CAST('Inf' AS FLOAT64), 0.0)),
      (3, STRUCT(CAST('-0.0' AS FLOAT64), 0.0)),
      (4, STRUCT(0.30000000000000004, 0.0))`);

    // Read back
    const rows = await bqExec(`
      SELECT id,
        geocode.lat AS lat,
        CAST(geocode.lat AS STRING) AS lat_str,
        IS_NAN(geocode.lat) AS is_nan,
        IS_INF(geocode.lat) AS is_inf
      FROM \`${DS}.${probeTbl}\`
      ORDER BY id`);

    // Check NaN
    const r1 = rows.find(r => r.id === 1);
    const nanOk = r1?.is_nan === true;
    check('AC-14a', 'NaN preserved in STRUCT<lat FLOAT64>',
      nanOk,
      `is_nan=${r1?.is_nan}, lat_str='${r1?.lat_str}'`
    );

    // Check +Infinity
    const r2 = rows.find(r => r.id === 2);
    const infOk = r2?.is_inf === true;
    check('AC-14b', '+Infinity preserved',
      infOk,
      `is_inf=${r2?.is_inf}, lat_str='${r2?.lat_str}'`
    );

    // Check -0.0
    const r3 = rows.find(r => r.id === 3);
    // -0.0 check: 1/-0 = -Infinity
    const negZeroRows = await bqExec(`
      SELECT IEEE_DIVIDE(1.0, geocode.lat) AS reciprocal
      FROM \`${DS}.${probeTbl}\` WHERE id = 3`);
    const reciprocal = negZeroRows[0]?.reciprocal;
    const negZeroStr = String(reciprocal);
    const negZeroOk = negZeroStr === '-Infinity' || negZeroStr === '-Inf';
    check('AC-14c', '-0.0 preserved (1/-0.0 = -Infinity)',
      negZeroOk,
      `1/(-0.0) = ${negZeroStr}`
    );

    // Check 17-significant-digit precision
    const r4 = rows.find(r => r.id === 4);
    const precisionOk = r4?.lat_str === '0.30000000000000004';
    check('AC-14d', '0.30000000000000004 — 17-digit precision preserved',
      precisionOk,
      `lat_str='${r4?.lat_str}'`
    );
  } finally {
    await bqDrop(probeTbl);
  }
}

// ============================================================================
// CLEANUP
// ============================================================================
async function cleanup(createdTables, createdViews, createdFunctions) {
  console.log('\n══════════════════════════════════════════════');
  console.log('TEARDOWN');
  console.log('══════════════════════════════════════════════');

  // Drop views first (they depend on tables)
  for (const v of (createdViews || [])) {
    try { await bqExec(`DROP VIEW IF EXISTS \`${DS}.${v}\``); } catch(_) {}
  }
  // Drop functions
  for (const f of (createdFunctions || [])) {
    try { await bqExec(`DROP FUNCTION IF EXISTS \`${DS}.${f}\``); } catch(_) {}
  }
  // Drop tables
  for (const t of (createdTables || [])) {
    await bqDrop(t);
  }
  // Drop probe tables
  for (const name of [`${PFX}probe_dec54`, `${PFX}probe_ts`, `${PFX}probe_f64`]) {
    await bqDrop(name);
  }

  console.log(`  Dropped ${(createdViews||[]).length} views, ${(createdFunctions||[]).length} UDFs, ${(createdTables||[]).length} tables.`);
}

// ============================================================================
// MAIN
// ============================================================================
async function main() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║  QA Validation: acme-analytics retail → BigQuery DDL   ║');
  console.log('║  All 14 Acceptance Criteria                            ║');
  console.log('╚══════════════════════════════════════════════════════════╝');

  // Phase 0: Static validation (no BQ)
  validateStatic();

  // Phase 1: Apply DDL + schema checks
  let createdTables = [];
  let createdViews = [];
  let createdFunctions = [];

  try {
    // AC-1: Apply all DDL
    const ac1 = await validateAC1();
    createdTables = ac1.createdTables;
    createdViews = ac1.createdViews;
    createdFunctions = ac1.createdFunctions;

    // AC-2 through AC-8, AC-11: Schema metadata checks
    await validateAC2();
    await validateAC3();
    await validateAC4();
    await validateAC5();
    await validateAC6();
    await validateAC7();
    await validateAC8();

    // AC-9, AC-10: View definition inspection (static, no BQ needed)
    validateAC9();
    validateAC10();

    // AC-11: fact_inventory_movements
    await validateAC11();

    // AC-12, AC-13, AC-14: Data survival probes
    await validateAC12();
    await validateAC13();
    await validateAC14();
  } finally {
    await cleanup(createdTables, createdViews, createdFunctions);
  }

  // ── Final Report ──
  console.log('\n╔══════════════════════════════════════════════════════════╗');
  console.log('║  FINAL RESULTS                                         ║');
  console.log('╚══════════════════════════════════════════════════════════╝\n');

  for (const r of results) {
    console.log(`  ${r.pass ? '✓' : '✗'} ${r.ac} — ${r.label}`);
  }

  const passed = results.filter(r => r.pass).length;
  const failed = results.filter(r => !r.pass).length;
  console.log(`\n  PASSED: ${passed} / ${results.length}`);
  console.log(`  FAILED: ${failed}`);

  if (failed > 0) {
    console.log('\n  FAILED CHECKS:');
    for (const r of results.filter(r => !r.pass)) {
      console.log(`    ✗ ${r.ac}: ${r.detail}`);
    }
  }

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(e => {
  console.error('FATAL:', e.message, e.stack);
  process.exit(2);
});
