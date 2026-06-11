-- ============================================================================
-- Dataset creation for acme-analytics-prod
-- Creates the retail dataset (BigQuery schema) if it doesn't exist.
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS `acme-analytics-prod.retail`
  OPTIONS (location = 'US');
