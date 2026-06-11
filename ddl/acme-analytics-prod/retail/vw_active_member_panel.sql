-- Source: retail.vw_active_member_panel (16-additional-views.hql)
-- Function translations applied:
--   R3: NDV(member_id) → APPROX_COUNT_DISTINCT(member_id)
--   date_sub(current_date(), 30) → DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
-- Table refs fully qualified to acme-analytics-prod.retail.*
-- Note: fact_loyalty_events has no 'region' column in source DDL; the source
--   view references it — this is carried forward as-is from the source HQL.
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_active_member_panel` AS
SELECT
    region,
    APPROX_COUNT_DISTINCT(member_id)   AS approx_active_members,
    COUNT(DISTINCT member_id)          AS exact_active_members,
    SUM(points)                        AS total_points_redeemed
FROM `acme-analytics-prod.retail.fact_loyalty_events`
WHERE event_type = 'REDEEM'
  AND event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY region;
