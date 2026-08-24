/*
===============================================================================
Run + Verify: Bronze Layer Load
===============================================================================
Script Purpose:
    Quick post-load sanity check — run this right after CALL bronze.load_bronze()
    to confirm the load ran and row counts look reasonable. This is NOT a data
    quality check (see quality_checks_bronze.sql for that) — it only confirms
    the load happened, not that the data inside is clean.
===============================================================================
*/

CALL bronze.load_bronze();

SELECT COUNT(*) FROM bronze.crm_cust_info;
SELECT COUNT(*) FROM bronze.crm_prd_info;
SELECT COUNT(*) FROM bronze.crm_sales_details;
SELECT COUNT(*) FROM bronze.erp_loc_a101;
SELECT COUNT(*) FROM bronze.erp_px_cat_g1v2;
SELECT COUNT(*) FROM bronze.erp_cust_az12;