-- Source: staging.cleansed_customers (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: DOUBLE→FLOAT64, TIMESTAMP→DATETIME
-- Partition: load_date DATE → direct DATE partitioning
CREATE TABLE `acme-lake-prod.staging.cleansed_customers` (
  customer_id    STRING,
  email_norm     STRING,
  phone_norm     STRING,
  first_name     STRING,
  last_name      STRING,
  addr_line1     STRING,
  addr_city      STRING,
  addr_region    STRING,
  addr_country   STRING,
  addr_postal    STRING,
  geocoded_lat   FLOAT64,
  geocoded_lon   FLOAT64,
  eff_from_ts    DATETIME,
  record_hash    STRING,
  -- Hive partition column inlined (DATE type maps directly)
  load_date      DATE
)
PARTITION BY load_date;
