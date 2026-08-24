/*
===============================================================================
Analyzing Bronze Data — Domain & Relationship Exploration
===============================================================================
Script Purpose:
    Before writing any transformation logic, explore each bronze table to
    understand what it represents and identify the key(s) that will be used
    to join it to other tables later (in silver/gold). This script doesn't
    check data QUALITY (see quality_checks_bronze.sql) — it's purely about
    understanding structure and relationships.
===============================================================================
*/

-- Customer master data (CRM)
-- cst_id  = numeric surrogate key, used to join to crm_sales_details.sls_cust_id
-- cst_key = business key, used to join to ERP customer tables (cust_az12, loc_a101)
SELECT cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date
FROM bronze.crm_cust_info
LIMIT 1000;
-- cst_id
-- cst_key

-- Product master data (CRM) — historized: same prd_key can appear in multiple
-- rows over time as products change, distinguished by prd_start_dt/prd_end_dt
-- prd_id  = numeric surrogate key
-- prd_key = business key, embeds the product category prefix and joins to
--           crm_sales_details.sls_prd_key
SELECT prd_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
FROM bronze.crm_prd_info
LIMIT 1000;
-- prd_id
-- prd_key

-- Transactional fact data (CRM) — one row per order line, the grain this
-- table's silver/gold fact table will be built at
-- sls_ord_num = order identifier (an order can have multiple lines)
-- sls_prd_key = joins to crm_prd_info (note: shorter format, category prefix stripped)
-- sls_cust_id = joins to crm_cust_info.cst_id
SELECT sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
FROM bronze.crm_sales_details
LIMIT 1000;
-- sls_ord_num
-- sls_prd_key
-- sls_cust_id

-- Customer demographic extension (ERP) — adds birthdate/gender not present in CRM
-- cid = business key equivalent to crm_cust_info.cst_key, but with formatting
--       differences (e.g. 'NAS' prefix) that need cleaning before joining
SELECT cid, bdate, gen
FROM bronze.erp_cust_az12
LIMIT 1000;
-- cid (similar to cst_key)

-- Customer location extension (ERP) — adds country, not present in CRM
-- cid = same business key as erp_cust_az12.cid, same cleaning needed
SELECT cid, cntry
FROM bronze.erp_loc_a101
LIMIT 1000;
-- cid (similar to cst_key)

-- Product category reference data (ERP)
-- id = matches the first segment of crm_prd_info.prd_key (category prefix,
--      dashes replaced with underscores) — this is how gold-layer dim_products
--      will bring category/subcategory/maintenance info onto each product
SELECT id, cat, subcat, maintenance
FROM bronze.erp_px_cat_g1v2
LIMIT 1000;
-- id (similar to prd_key prefix)