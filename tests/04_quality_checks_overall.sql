/*
===============================================================================
Quality Checks: Overall / Cross-Cutting Summary
===============================================================================
Script Purpose:
    Unlike 01/02/03_quality_checks_*.sql (which check each medallion layer as
    it's built), this file pulls together the SPECIFIC data quality findings
    that are actually cited in the final insights report — a single place to
    re-verify every caveat mentioned in insights_report.md's "Data quality
    notes worth flagging" section, with the exact figures that appear there.
===============================================================================
*/

-- ------------------------
-- Excluded sales value (unparseable order dates)
-- ------------------------
-- Total sales value sitting in rows with a NULL order_date — excluded from
-- every time-based report throughout this project (see 02_advance_analysis.sql)
SELECT SUM(sales_amount)
FROM gold.fact_sales
WHERE order_date IS NULL;
-- 4992

-- ------------------------
-- Unresolved customer gender
-- ------------------------
-- Customers where neither CRM nor the ERP fallback produced a usable gender
SELECT gender,
       COUNT(*)
FROM gold.dim_customers
GROUP BY gender;
-- "n/a"  15

-- ------------------------
-- Unresolved customer country
-- ------------------------
-- Customers with no country on file after ERP location standardization
SELECT country,
       COUNT(*)
FROM gold.dim_customers
GROUP BY country;
-- "n/a"  337

-- ------------------------
-- Uncategorized products
-- ------------------------
-- Products whose category code didn't match any entry in the ERP category
-- reference data — excluded from every category-level breakdown
SELECT category,
       COUNT(product_id)
FROM gold.dim_products
GROUP BY category;
-- [null]  7

-- ------------------------
-- Null/negative product cost in the raw source
-- ------------------------
-- Defaulted to 0 during silver-layer cleaning — margin calculations
-- involving these 2 specific products should not be trusted at face value
SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost IS NULL
   OR prd_cost < 0;
-- 210  "CO-RF-FR-R92B-58"  "HL Road Frame - Black- 58" [null] "R "  "2003-07-01 00:00:00" [null]
-- 211  "CO-RF-FR-R92R-58"  "HL Road Frame - Red- 58"  [null]  "R "  "2003-07-01 00:00:00" [null]

-- ------------------------
-- Future-dated birthdates
-- ------------------------
-- Nulled out (not corrected) during silver-layer cleaning — age/birth_date
-- is missing, not wrong, for these customers
SELECT bdate
FROM bronze.erp_cust_az12
WHERE
    -- bdate < '1924-01-01' OR
    bdate > CURRENT_DATE;
-- 16 rows