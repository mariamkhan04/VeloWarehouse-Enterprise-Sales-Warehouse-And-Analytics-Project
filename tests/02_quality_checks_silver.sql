/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Script Purpose:
    Run these checks against the 'silver' schema AFTER running load_silver(),
    to confirm the transformations actually resolved the issues found in
    quality_checks_bronze.sql. Every check here should return no results —
    if one does, the corresponding transformation in proc_load_silver.sql
    needs revisiting.
===============================================================================
*/

-- ==========================
-- CRM TABLES
-- ==========================

-- ------------------------
-- crm_cust_info
-- ------------------------
SELECT *
FROM silver.crm_cust_info;

-- Check for null or duplicate primary key
-- Expectation: no results
SELECT cst_id,
       COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces
-- Expectation: no results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr <> TRIM(cst_gndr);

SELECT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status <> TRIM(cst_marital_status);

-- Data standardization and consistency: should only show the canonical
-- values ('Single'/'Married'/'n/a', 'Female'/'Male'/'n/a')
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;

-- ----------------
-- crm_prd_info
-- ----------------
SELECT *
FROM silver.crm_prd_info;

-- Check for null or duplicate primary key
-- Expectation: no results
SELECT prd_id,
       COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;
-- none

-- Check for unwanted spaces
-- Expectation: no results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);
-- none

-- Check for NULLs or negative costs
-- Expectation: no results (silver coalesces NULL cost to 0)
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_cost < 0;
-- none

-- Data standardization and consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

-- Check for invalid date order (end date before start date)
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ------------------
-- crm_sales_details
-- ------------------
SELECT *
FROM silver.crm_sales_details;

-- Check for invalid date order (order date after shipping/due dates)
-- Expectation: no results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check data consistency: sales must equal quantity * price
-- values must not be null, zero, or negative
-- Expectation: no results
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE (sls_sales != sls_quantity * sls_price)
   OR (sls_sales IS NULL) OR (sls_quantity IS NULL) OR (sls_price IS NULL)
   OR (sls_sales <= 0) OR (sls_quantity <= 0) OR (sls_price <= 0)
ORDER BY sls_sales, sls_quantity, sls_price;

-- ==========================
-- ERP TABLES
-- ==========================

-- ------------------------
-- erp_cust_az12
-- ------------------------
SELECT *
FROM silver.erp_cust_az12;

-- Identify out-of-range birthdates
-- Expectation: no results (future dates were nulled out in silver)
SELECT bdate
FROM silver.erp_cust_az12
WHERE
    -- bdate < '1924-01-01' OR
    bdate > CURRENT_DATE;

-- Data standardization and consistency
-- Expectation: only 'Female', 'Male', 'n/a'
SELECT DISTINCT gen, LENGTH(gen)
FROM silver.erp_cust_az12;

SELECT DISTINCT
    TRIM(gen),
    CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
         WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
         ELSE 'n/a'
    END AS gen
FROM silver.erp_cust_az12;

-- ------------------------
-- erp_loc_a101
-- ------------------------
SELECT
    cid,
    cntry
FROM silver.erp_loc_a101;

-- Data standardization and consistency
-- Expectation: standardized country names ('Germany', 'United States', 'n/a', ...)
SELECT DISTINCT
    cntry, LENGTH(cntry)
FROM silver.erp_loc_a101;

-- ------------------------
-- erp_px_cat_g1v2
-- ------------------------
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM silver.erp_px_cat_g1v2;

-- Check for unwanted spaces
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance);

-- Data standardization and consistency
SELECT DISTINCT cat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;