/*
===============================================================================
Reports Validation
===============================================================================
Script Purpose:
    Sanity-check the report_customers and report_products views by
    cross-checking their aggregated totals against a direct aggregation over
    fact_sales/dim_products. If the two approaches agree, the report views'
    internal logic (joins, filters, grouping) is confirmed consistent.
===============================================================================
*/

SELECT *
FROM gold.report_customers;

SELECT *
FROM gold.report_products;

-- Category totals as computed by the report_products view
SELECT category,
       SUM(total_sales)
FROM gold.report_products
GROUP BY category;
-- "Accessories"  699909
-- "Bikes"        28311657
-- "Clothing"     339692

-- Same category totals computed directly from fact_sales/dim_products,
-- using the same order_date filter report_products uses internally
SELECT p.category,
       SUM(f.sales_amount)
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY p.category;
-- "Clothing"     339692
-- "Accessories"  699909
-- "Bikes"        28311657
-- Matches exactly — confirms report_products' totals are correct and
-- consistent with a direct aggregation over the underlying tables.