/*
===============================================================================
Quality Checks: Bronze Layer
===============================================================================
Script Purpose:
    Run these checks against the 'bronze' schema to profile data quality issues
    in the raw source data BEFORE writing transformation logic for silver.
    Most checks state an "Expectation" comment — if the query returns rows,
    that's a data quality issue to handle in silver, not a bug in this script.
===============================================================================
*/

-- ==========================
-- CRM TABLES
-- ==========================

-- ------------------------
-- crm_cust_info
-- ------------------------
SELECT *
FROM bronze.crm_cust_info;

-- Check for null or duplicate primary key
-- Expectation: no results
SELECT cst_id,
       COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted leading/trailing spaces
-- Expectation: no results
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);
-- 17 rows

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);
-- 22 rows

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr <> TRIM(cst_gndr);
-- none

SELECT cst_marital_status
FROM bronze.crm_cust_info
WHERE cst_marital_status <> TRIM(cst_marital_status);
-- none

-- Data standardization and consistency: see which raw codes exist
-- before deciding how to map them in silver
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

-- ----------------
-- crm_prd_info
-- ----------------
SELECT *
FROM bronze.crm_prd_info;

-- Check for null or duplicate primary key
-- Expectation: no results
SELECT prd_id,
       COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;
-- none

-- Check for unwanted spaces
-- Expectation: no results
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);
-- none

-- Check for NULLs or negative costs
SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_cost < 0;
-- 2

-- Data standardization and consistency
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

-- Check for invalid date order (end date before start date)
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ------------------
-- crm_sales_details
-- ------------------
SELECT *
FROM bronze.crm_sales_details;

-- Check for invalid dates: raw dates are stored as INTEGER (YYYYMMDD), so a
-- valid value must be 8 digits, non-zero, and fall within a sane calendar range
SELECT NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
   OR LENGTH(sls_order_dt::TEXT) != 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;

SELECT NULLIF(sls_ship_dt, 0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0
   OR LENGTH(sls_ship_dt::TEXT) != 8
   OR sls_ship_dt > 20500101
   OR sls_ship_dt < 19000101;

SELECT NULLIF(sls_due_dt, 0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LENGTH(sls_due_dt::TEXT) != 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;

-- Check for invalid date order (order date after shipping/due dates)
-- Expectation: no results
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Check data consistency: sales must equal quantity * price
-- values must not be null, zero, or negative
-- Expectation: no results
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details
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
FROM bronze.erp_cust_az12;

-- Identify out-of-range birthdates (future dates are impossible;
-- an unrealistically old lower bound is left commented as an option)
SELECT bdate
FROM bronze.erp_cust_az12
WHERE
    -- bdate < '1924-01-01' OR
    bdate > CURRENT_DATE;

-- Check raw gen values for hidden whitespace variants before standardizing
SELECT DISTINCT gen, LENGTH(gen)
FROM bronze.erp_cust_az12;

-- Preview how each raw value maps to the standardized value
SELECT DISTINCT
    TRIM(gen),
    CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
         WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
         ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;

-- ------------------------
-- erp_loc_a101
-- ------------------------

-- Preview the cid cleanup (dashes removed) alongside the raw value
SELECT
    cid,
    REPLACE(cid, '-', '') cid,
    cntry
FROM bronze.erp_loc_a101;

-- Data standardization and consistency
SELECT DISTINCT
    cntry, LENGTH(cntry)
FROM bronze.erp_loc_a101;

-- ------------------------
-- erp_px_cat_g1v2
-- ------------------------
SELECT
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

-- Check for unwanted spaces
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat <> TRIM(cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance);

-- Data standardization and consistency
SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;