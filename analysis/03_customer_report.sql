/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    Consolidates key customer metrics and behaviors into a single queryable
    view, built on top of gold.fact_sales and gold.dim_customers.

Highlights:
    1. Gathers essential fields: names, age, customer number.
    2. Segments customers by age group and by spending behavior
       (VIP / Regular / New), matching the segmentation logic explored in
       02_advance_analysis.sql.
    3. Aggregates customer-level metrics:
       - total orders
       - total sales
       - total quantity purchased
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last order)
       - average order value (AOV)
       - average monthly spend
===============================================================================
*/

-- ==============================================================================
-- Create Report: gold.report_customers
-- ==============================================================================
DROP VIEW IF EXISTS gold.report_customers;
CREATE OR REPLACE VIEW gold.report_customers AS
(
    WITH base_query AS (
        /*-----------------------------------------------------------------------
        1) Base Query: Retrieves core columns from fact_sales and dim_customers
        -----------------------------------------------------------------------*/
        SELECT
            f.order_number,
            f.product_key,
            f.order_date,
            f.sales_amount,
            f.quantity,
            c.customer_key,
            c.customer_number,
            CONCAT(c.first_name, ' ', c.last_name) customer_name,
            EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) age
        FROM gold.fact_sales f
        LEFT JOIN gold.dim_customers c
            ON f.customer_key = c.customer_key
        WHERE f.order_date IS NOT NULL
    ),
    customer_aggregations AS (
        /*-----------------------------------------------------------------------
        2) Customer Aggregations: Summarizes key metrics at the customer level
        -----------------------------------------------------------------------*/
        SELECT customer_key,
               customer_number,
               customer_name,
               age,
               COUNT(DISTINCT order_number) total_orders,
               SUM(sales_amount) total_sales,
               SUM(quantity) total_quantity,
               MAX(order_date) latest_order,
               (
                   EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12
                   + EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date)))
               ) AS lifespan_months
        FROM base_query
        GROUP BY
            customer_key,
            customer_number,
            customer_name,
            age
    )
    /*---------------------------------------------------------------------------
    3) Final Query: Combines all customer results into one output, with
       age/spending segmentation and derived KPIs
    ---------------------------------------------------------------------------*/
    SELECT customer_key,
           customer_number,
           customer_name,
           age,
           CASE
               WHEN age < 20 THEN 'Under 20'
               WHEN age BETWEEN 20 AND 29 THEN '20-29'
               WHEN age BETWEEN 30 AND 39 THEN '30-39'
               WHEN age BETWEEN 40 AND 49 THEN '40-49'
               ELSE '50 and above'
           END AS age_group,
           CASE WHEN lifespan_months >= 12 AND total_sales > 5000 THEN 'VIP'
                WHEN lifespan_months >= 12 AND total_sales <= 5000 THEN 'Regular'
                ELSE 'New'
           END customer_segments,
           total_orders,
           total_sales,
           total_quantity,
           latest_order,
           lifespan_months,
           (
               EXTRACT(YEAR FROM AGE(CURRENT_DATE, latest_order)) * 12
               + EXTRACT(MONTH FROM AGE(CURRENT_DATE, latest_order))
           ) AS recency_months,
           -- Average Order Value (AOV)
           CASE WHEN total_orders = 0 THEN 0
                ELSE total_sales / total_orders
           END AS avg_order_value,
           -- Average monthly spend
           CASE WHEN lifespan_months = 0 THEN total_sales
                ELSE ROUND(total_sales / lifespan_months, 2)
           END AS avg_monthly_spend
    FROM customer_aggregations
);

-- ==============================================================================
-- Example Usage: Top customers by revenue (via the view)
-- ==============================================================================
-- Demonstrates how gold.report_customers simplifies ranking queries — no joins
-- needed, since total_sales is already pre-aggregated per customer.
SELECT *
FROM (
    SELECT customer_name,
           total_sales,
           customer_segments,
           DENSE_RANK() OVER (ORDER BY total_sales DESC) rn
    FROM gold.report_customers
) t
WHERE rn <= 3;
-- "Nichole Nara"	13294	"VIP"	1
-- "Kaitlyn Henderson"	13294	"VIP"	1
-- "Margaret He"	13268	"VIP"	2
-- "Randall Dominguez"	13265	"VIP"	3