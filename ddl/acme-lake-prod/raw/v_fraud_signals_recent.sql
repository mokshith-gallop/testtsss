-- Source: raw.v_fraud_signals_recent view (05-additional-raw-feeds.hql)
-- Hive→BQ translations applied:
--   date_format(date_sub(current_date(), 1), 'yyyyMMdd')
--     → FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
-- Fully qualified table reference to acme-lake-prod.raw.fraud_signals
CREATE OR REPLACE VIEW `acme-lake-prod.raw.v_fraud_signals_recent` AS
SELECT *
FROM `acme-lake-prod.raw.fraud_signals`
WHERE signal_date >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY));
