/*
===============================================================================
Run + Verify: Silver Layer Load
===============================================================================
Script Purpose:
    Quick post-load sanity check — run this right after CALL silver.load_silver()
    to confirm the load ran. Row counts should generally match bronze, EXCEPT
    crm_cust_info, which will be lower than bronze because the transformation
    deduplicates customers (keeps only the most recent record per cst_id).
    This is NOT a data quality check (see quality_checks_silver.sql for that).
===============================================================================
*/

CALL silver.load_silver();

SELECT COUNT(*) FROM silver.crm_cust_info;
SELECT COUNT(*) FROM silver.crm_prd_info;
SELECT COUNT(*) FROM silver.crm_sales_details;
SELECT COUNT(*) FROM silver.erp_loc_a101;
SELECT COUNT(*) FROM silver.erp_px_cat_g1v2;
SELECT COUNT(*) FROM silver.erp_cust_az12;