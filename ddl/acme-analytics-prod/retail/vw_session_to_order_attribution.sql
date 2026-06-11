-- Source: retail.vw_session_to_order_attribution (09-analytics-views.hql)
-- Cross-cluster federation: raw.mobile_events (acme-lake) → fully qualified cross-project ref
-- Function translations applied:
--   R9: s.event_ts + INTERVAL '1' DAY → DATETIME_ADD(s.event_ts, INTERVAL 1 DAY)
-- Table refs:
--   raw.mobile_events → `acme-lake-prod.raw.mobile_events` (cross-project)
--   retail.dim_customer → `acme-analytics-prod.retail.dim_customer`
--   retail.fact_sales → `acme-analytics-prod.retail.fact_sales`
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_session_to_order_attribution` AS
SELECT
  s.user_id,
  s.event_ts                                AS session_ts,
  s.context.referrer                        AS referrer,
  f.invoice_no,
  f.invoice_ts                              AS order_ts,
  f.line_total
FROM `acme-lake-prod.raw.mobile_events` s
LEFT JOIN `acme-analytics-prod.retail.dim_customer` dc ON dc.customer_id = s.user_id
LEFT JOIN `acme-analytics-prod.retail.fact_sales` f
       ON  f.customer_sk = dc.customer_sk
       AND f.invoice_ts BETWEEN s.event_ts AND DATETIME_ADD(s.event_ts, INTERVAL 1 DAY);
