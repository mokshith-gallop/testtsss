-- Source: raw.product_catalog_feed (05-additional-raw-feeds.hql)
-- Storage: RCFILE → managed BQ table (STORED AS RCFILE dropped)
-- Type mappings: MAP<STRING,STRING> metadata → JSON
-- Partition: feed_date STRING → ingestion-time partitioning
CREATE TABLE `acme-lake-prod.raw.product_catalog_feed` (
  sku             STRING,
  supplier_id     STRING,
  upc             STRING,
  name            STRING,
  category        STRING,
  subcategory     STRING,
  color           STRING,
  size            STRING,
  msrp            NUMERIC(10,2),
  cost            NUMERIC(10,2),
  available_from  DATE,
  discontinued_at DATE,
  metadata        JSON,
  -- Hive partition column inlined
  feed_date       STRING
)
PARTITION BY DATE(_PARTITIONTIME);
