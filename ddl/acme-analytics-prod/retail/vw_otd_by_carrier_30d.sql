-- Source: retail.vw_otd_by_carrier_30d (16-additional-views.hql)
-- Function translations applied:
--   R9: shipped_ts + INTERVAL '48' HOUR → DATETIME_ADD(shipped_ts, INTERVAL 48 HOUR)
--   unix_timestamp(x) → UNIX_SECONDS(CAST(x AS TIMESTAMP))
--     (BQ UNIX_SECONDS requires TIMESTAMP; shipped_ts/delivered_ts are DATETIME)
--   date_sub(current_date(), 30) → DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
--   shipped_ts >= date_sub(...) comparison: CAST shipped_ts DATETIME to DATE
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_otd_by_carrier_30d` AS
SELECT
    carrier,
    COUNT(*)                                                                              AS shipments,
    AVG(CASE WHEN delivered_ts <= DATETIME_ADD(shipped_ts, INTERVAL 48 HOUR)
             THEN 1.0 ELSE 0.0 END)                                                      AS otd_rate,
    AVG(UNIX_SECONDS(CAST(delivered_ts AS TIMESTAMP)) - UNIX_SECONDS(CAST(shipped_ts AS TIMESTAMP))) / 3600.0 AS avg_transit_hours
FROM `acme-analytics-prod.retail.fact_shipments`
WHERE CAST(shipped_ts AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY carrier;
