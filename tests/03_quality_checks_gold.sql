/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Script Purpose:
    Run these checks against the 'gold' schema views after creating them in
    ddl_gold.sql, to validate the integrity, consistency, and accuracy of the
    final star schema before it's used for analytics or reporting. Checks
    include:
    - Uniqueness of surrogate keys in dimension tables
    - Referential integrity between fact and dimension views (every fact row
      should successfully join back to both dimensions)
    - Validation of relationships in the data model for analytical purposes
===============================================================================
*/

-- ------------------------
-- gold.dim_customers
-- ------------------------
SELECT *
FROM gold.dim_customers;

-- Sanity check on the gender standardization logic (CRM-master-with-ERP-fallback)
-- Expectation: only 'Female', 'Male', 'n/a'
SELECT DISTINCT gender
FROM gold.dim_customers;

-- ------------------------
-- gold.dim_products
-- ------------------------
SELECT *
FROM gold.dim_products;

-- ------------------------
-- gold.fact_sales
-- ------------------------
SELECT *
FROM gold.fact_sales;

-- ------------------------
-- Foreign key integrity (Dimensions)
-- ------------------------
-- Confirms every row in fact_sales successfully matches a customer_key and a
-- product_key in the dimension views. A LEFT JOIN with a NULL result means the
-- fact row's source business key (sls_cust_id / sls_prd_key) didn't find a
-- match in the corresponding dimension — a break in the star schema's model
-- integrity that would silently drop that row from any BI join.
-- Expectation: no results
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL;