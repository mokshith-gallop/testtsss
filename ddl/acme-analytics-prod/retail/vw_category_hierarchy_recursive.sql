-- Source: retail.vw_category_hierarchy_recursive (16-additional-views.hql)
-- R10: WITH RECURSIVE passes through to BigQuery natively
-- Table refs fully qualified to acme-analytics-prod.retail.*
CREATE OR REPLACE VIEW `acme-analytics-prod.retail.vw_category_hierarchy_recursive` AS
WITH RECURSIVE cat_tree (category_id, name, parent_id, path, depth) AS (
    SELECT category_id, name, parent_id, name AS path, 0 AS depth
    FROM `acme-analytics-prod.retail.dim_category`
    WHERE parent_id IS NULL OR parent_id = ''

    UNION ALL

    SELECT c.category_id, c.name, c.parent_id,
           CONCAT(t.path, ' > ', c.name)  AS path,
           t.depth + 1                    AS depth
    FROM `acme-analytics-prod.retail.dim_category` c
    JOIN cat_tree t ON c.parent_id = t.category_id
    WHERE t.depth < 8
)
SELECT * FROM cat_tree;
