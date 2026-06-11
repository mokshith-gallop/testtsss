-- ============================================================================
-- Dataset creation for acme-lake-prod
-- Creates the raw and staging datasets (BigQuery schemas) if they don't exist.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS `acme-lake-prod.raw`
  OPTIONS (location = 'US');

CREATE SCHEMA IF NOT EXISTS `acme-lake-prod.staging`
  OPTIONS (location = 'US');
