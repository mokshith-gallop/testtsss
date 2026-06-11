-- Source: raw.delivery_routes (05-additional-raw-feeds.hql)
-- Storage: TEXTFILE (CSV) → managed BQ table
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.delivery_routes` (
  route_id       STRING,
  driver_id      STRING,
  vehicle_id     STRING,
  planned_stops  INT64,
  actual_stops   INT64,
  miles_driven   NUMERIC(8,2),
  fuel_used      NUMERIC(8,2),
  start_ts       DATETIME,
  end_ts         DATETIME,
  -- Hive partition column inlined
  date_ts        STRING
)
PARTITION BY DATE(_PARTITIONTIME);
