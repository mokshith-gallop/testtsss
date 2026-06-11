-- Source: retail.agg_daily_carrier_otd (12-aggregates-rollups.hql)
-- Storage: Parquet → managed BQ table
-- Partition: PARTITIONED BY (ship_date DATE) → PARTITION BY ship_date
-- Type mappings applied:
--   INT shipments_total, delivered_on_time, delivered_late, in_transit → INT64
--   DECIMAL(5,4) otd_pct → NUMERIC(5,4)
--   DECIMAL(8,2) avg_transit_hours → NUMERIC(8,2)
CREATE TABLE `acme-analytics-prod.retail.agg_daily_carrier_otd` (
  carrier           STRING,
  shipments_total   INT64,
  delivered_on_time INT64,
  delivered_late    INT64,
  in_transit        INT64,
  otd_pct           NUMERIC(5,4),
  avg_transit_hours NUMERIC(8,2),
  ship_date         DATE
)
PARTITION BY ship_date;
