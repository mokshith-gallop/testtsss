-- Source: staging.cleansed_products (06-staging-tables.hql)
-- Storage: PARQUET → managed BQ table
-- Type mappings: BOOLEAN→BOOL, DECIMAL→NUMERIC
-- Partition: load_date DATE → direct DATE partitioning
CREATE TABLE `acme-lake-prod.staging.cleansed_products` (
  sku            STRING,
  upc            STRING,
  name_norm      STRING,
  category_norm  STRING,
  subcategory    STRING,
  color_norm     STRING,
  size_norm      STRING,
  msrp           NUMERIC(10,2),
  cost           NUMERIC(10,2),
  supplier_id    STRING,
  available      BOOL,
  -- Hive partition column inlined (DATE type maps directly)
  load_date      DATE
)
PARTITION BY load_date;
