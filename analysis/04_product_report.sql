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