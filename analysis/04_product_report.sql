/*
===============================================================================
Product Report
===============================================================================
Purpose:
    Consolidates key product metrics and behaviors into a single queryable
    view, built on top of gold.fact_sales and gold.dim_products.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory,
       and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range,
       or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average selling price (ASP) — total sales ÷ total quantity, i.e.
         quantity-weighted, not an average of per-line prices
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/

-- ==============================================================================
-- Create Report: gold.report_products
-- ==============================================================================
DROP VIEW IF EXISTS gold.report_products;
CREATE OR REPLACE VIEW gold.report_products AS
(
    WITH base_query AS (
        /*-----------------------------------------------------------------------
        1) Base Query: Retrieves core columns from fact_sales and dim_products
        -----------------------------------------------------------------------*/
        SELECT f.order_number,
               f.order_date,
               f.customer_key,
               f.sales_amount,
               f.quantity,
               p.product_key,
               p.product_name,
               p.category,
               p.sub_category,
			   p.product_line,
               p.cost
        FROM gold.fact_sales f
        LEFT JOIN gold.dim_products p
            ON f.product_key = p.product_key
        WHERE f.order_date IS NOT NULL
    ),
    product_aggregations AS (
        /*-----------------------------------------------------------------------
        2) Product Aggregations: Summarizes key metrics at the product level
        -----------------------------------------------------------------------*/
        SELECT product_key,
               product_name,
               category,
               sub_category,
			   product_line,
               cost,
               (
                   EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12
                   + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
               ) AS lifespan_months,
               MAX(order_date) last_sale_order,
               COUNT(DISTINCT customer_key) total_customers,
               COUNT(DISTINCT order_number) total_orders,
               SUM(sales_amount) total_sales,
               SUM(quantity) total_quantity
        FROM base_query
        GROUP BY
            product_key,
            product_name,
            category,
            sub_category,
			product_line,
            cost
    )
    /*---------------------------------------------------------------------------
    3) Final Query: Combines all product results into one output, with
       revenue segmentation and derived KPIs
    ---------------------------------------------------------------------------*/
    SELECT
        product_key,
        product_name,
        category,
        sub_category,
		product_line,
        cost,
        last_sale_order,
        lifespan_months,
        (
            EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_sale_order)) * 12
            + EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_sale_order))
        ) AS recency_months,
        CASE
            WHEN total_sales > 50000 THEN 'High-Performer'
            WHEN total_sales >= 10000 THEN 'Mid-Range'
            ELSE 'Low-Performer'
        END AS product_segment,
        total_sales,
        total_quantity,
        total_customers,
        total_orders,
        ROUND(total_sales::numeric / NULLIF(total_quantity, 0), 1) avg_selling_price,
        -- Average Order Revenue (AOR)
        CASE
            WHEN total_orders = 0 THEN 0
            ELSE total_sales / total_orders
        END AS avg_order_revenue,
        -- Average monthly revenue
        CASE WHEN lifespan_months = 0 THEN total_sales
             ELSE ROUND(total_sales / lifespan_months, 2)
        END AS avg_monthly_revenue
    FROM product_aggregations
);

-- ==============================================================================
-- Example Usage: Are the lowest-revenue products actually unprofitable?
-- ==============================================================================
-- Total revenue alone can be misleading for cheap, low-volume items — a product
-- can rank "worst by revenue" while still earning healthy profit per unit.
-- This checks per-unit margin (avg_selling_price - cost) for the bottom 5
-- revenue products, to see whether low revenue also means low profitability.
SELECT *
FROM (
    SELECT product_name,
           category,
           product_line,
           cost,
           avg_selling_price,
           ROUND(avg_selling_price - cost, 2) AS margin_per_unit,
           total_quantity,
           total_sales,
           DENSE_RANK() OVER (ORDER BY total_sales) rn
    FROM gold.report_products
) t
WHERE rn <= 5;
-- "Racing Socks- L"	"Clothing"	"Road"	3	9.0	6.00	270	2430	1
-- "Racing Socks- M"	"Clothing"	"Road"	3	9.0	6.00	298	2682	2
-- "Patch Kit/8 Patches"	"Accessories"	"Other Sales"	1	2.0	1.00	3189	6378	3
-- "Bike Wash - Dissolver"	"Accessories"	"Other Sales"	3	8.0	5.00	909	7272	4
-- "Touring Tire Tube"	"Accessories"	"Touring"	2	5.0	3.00	1487	7435	5

-- Same check applied to the top 5 revenue products, for symmetry —
-- does high revenue also mean high gross margin per unit, or could a
-- best-seller by revenue still be a comparatively thin-margin item?
SELECT *
FROM (
    SELECT product_name,
           category,
           product_line,
           cost,
           avg_selling_price,
           ROUND(avg_selling_price - cost, 2) AS margin_per_unit,
           total_quantity,
           total_sales,
           DENSE_RANK() OVER (ORDER BY total_sales DESC) rn
    FROM gold.report_products
) t
WHERE rn <= 5;
-- "Mountain-200 Black- 46"	"Bikes"	"Mountain"	1252	2215.2	963.20	620	1373454	1
-- "Mountain-200 Black- 42"	"Bikes"	"Mountain"	1252	2220.1	968.10	614	1363128	2
-- "Mountain-200 Silver- 38"	"Bikes"	"Mountain"	1266	2247.3	981.30	596	1339394	3
-- "Mountain-200 Silver- 46"	"Bikes"	"Mountain"	1266	2243.0	977.00	579	1298709	4
-- "Mountain-200 Black- 38"	"Bikes"	"Mountain"	1252	2224.7	972.70	581	1292559	5