-- Source: staging.geocoded_addresses (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: DOUBLE→FLOAT64, DECIMAL→NUMERIC
-- Partition: load_date DATE → direct DATE partitioning
CREATE TABLE `acme-lake-prod.staging.geocoded_addresses` (
  raw_addr_hash  STRING,
  addr_line1     STRING,
  addr_city      STRING,
  addr_region    STRING,
  addr_country   STRING,
  addr_postal    STRING,
  lat            FLOAT64,
  lon            FLOAT64,
  confidence     NUMERIC(4,3),
  provider       STRING,
  -- Hive partition column inlined (DATE type maps directly)
  load_date      DATE
)
PARTITION BY load_date;
