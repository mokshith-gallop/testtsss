-- Source: raw.omniture view (02-raw-external-tables.hql)
-- Simple column projection over omniture_logs
-- Fully qualified table reference to acme-lake-prod.raw.omniture_logs
CREATE OR REPLACE VIEW `acme-lake-prod.raw.omniture` AS
SELECT
    col_2  AS event_ts,
    col_8  AS ip,
    col_13 AS url,
    col_14 AS user_id,
    col_50 AS city,
    col_51 AS country,
    col_53 AS state,
    date_ts
FROM `acme-lake-prod.raw.omniture_logs`;
