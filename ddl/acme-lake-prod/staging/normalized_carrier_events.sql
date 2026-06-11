-- Source: staging.normalized_carrier_events (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: TIMESTAMP→DATETIME
-- Partition: date_ts STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.staging.normalized_carrier_events` (
  tracking_no      STRING,
  carrier          STRING,
  event_type       STRING,
  event_ts         DATETIME,
  location_city    STRING,
  location_region  STRING,
  location_country STRING,
  -- Hive partition column inlined
  date_ts          STRING
)
PARTITION BY DATE(_PARTITIONTIME);
