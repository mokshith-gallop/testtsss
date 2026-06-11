-- Source: staging.v_returns_pending view (06-staging-tables.hql)
-- Hive→BQ translations applied:
--   DATEDIFF(current_date(), to_date(r.requested_at))
--     → DATE_DIFF(CURRENT_DATE(), DATE(r.requested_at), DAY)
-- Fully qualified table reference to acme-lake-prod.raw.return_authorizations
CREATE OR REPLACE VIEW `acme-lake-prod.staging.v_returns_pending` AS
SELECT
    r.rma_id,
    r.customer_id,
    r.invoice_no,
    r.stock_code,
    r.quantity,
    r.requested_at,
    DATE_DIFF(CURRENT_DATE(), DATE(r.requested_at), DAY) AS days_pending
FROM `acme-lake-prod.raw.return_authorizations` r
WHERE r.approved IS NULL OR r.approved = FALSE;
