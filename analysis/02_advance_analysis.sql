/*
===============================================================================
Advanced Analysis — Gold Layer
===============================================================================
Script Purpose:
    Second stage of the analytics phase, following EDA (01_eda.sql). Goes
    beyond simple exploration into time-based trends, running totals,
    year-over-year product performance, part-to-whole contribution, and
    segmentation — the analytical building blocks the customer/product
    report views (03/04) and eventual dashboard are built from.

    Sections:
    1. Changes Over Time Analysis — yearly and monthly sales trends
    2. Cumulative Analysis        — running totals and moving averages
    3. Performance Analysis       — year-over-year product comparison
    4. Part-to-Whole Analysis     — category contribution to overall sales
    5. Data Segmentation          — products by cost range, customers by
                                    spending behavior
===============================================================================
*/

-- ==============================================================================
-- 1. Changes Over Time Analysis
-- ==============================================================================

-- Sales performance by year — understand overall trend
SELECT EXTRACT(YEAR FROM order_date) order_year,
       SUM(sales_amount) total_sales,
       COUNT(DISTINCT customer_key) total_customers,
       SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY EXTRACT(YEAR FROM order_date);
-- 2010  43419
-- 2011  7075088
-- 2012  5842231
-- 2013  16344878  -- highest sales year
-- 2014  45642     -- partial year, decline
-- Note: these five totals sum to 29351258, not the full 29356250 from EDA's
-- total_sales figure. The ~4992 difference is sales with a NULL order_date
-- (unparseable raw dates, nulled out in silver) — excluded here by the
-- WHERE clause, and consistently excluded from every other date-based query
-- in this file and in report_products/report_customers.

-- Sales performance by month — understand seasonality
SELECT TO_CHAR(order_date, 'Mon') order_month,
       SUM(sales_amount) total_sales,
       COUNT(DISTINCT customer_key) total_customers,
       SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date, 'Mon'), EXTRACT(MONTH FROM order_date)
ORDER BY EXTRACT(MONTH FROM order_date);

-- Same, broken out by year and month together
SELECT EXTRACT(YEAR FROM order_date) order_year,
       TO_CHAR(order_date, 'Mon') order_month,
       SUM(sales_amount) total_sales,
       COUNT(DISTINCT customer_key) total_customers,
       SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY
    EXTRACT(YEAR FROM order_date),
    TO_CHAR(order_date, 'Mon'),
    EXTRACT(MONTH FROM order_date)
ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date);

-- Same idea using date_trunc — collapses each month to its first-of-month date
SELECT DATE_TRUNC('month', order_date)::date order_month,
       SUM(sales_amount) total_sales,
       COUNT(DISTINCT customer_key) total_customers,
       SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date)::date
ORDER BY DATE_TRUNC('month', order_date)::date;

-- ==============================================================================
-- 2. Cumulative Analysis
-- ==============================================================================

-- Total sales per year, plus the running total of sales over time
SELECT
    order_year,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_year) running_sales,
    ROUND(avg_price, 2) avg_price,
    ROUND(AVG(avg_price) OVER (ORDER BY order_year), 2) moving_avg_price
FROM (
    SELECT DATE_TRUNC('year', order_date)::date order_year,
           SUM(sales_amount) total_sales,
           AVG(price) avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('year', order_date)::date
) t;

-- Total sales per month, plus the running total within each year
-- (running total resets at the start of each year via PARTITION BY)
SELECT
    order_date,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY order_date) running_sales,
    ROUND(avg_price, 2) avg_price,
    ROUND(AVG(avg_price) OVER (PARTITION BY EXTRACT(YEAR FROM order_date) ORDER BY order_date), 2) moving_avg_price
FROM (
    SELECT DATE_TRUNC('month', order_date)::date order_date,
           SUM(sales_amount) total_sales,
           AVG(price) avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY DATE_TRUNC('month', order_date)::date
) t;

-- ==============================================================================
-- 3. Performance Analysis
-- ==============================================================================

-- Analyze the yearly performance of products by comparing their sales to both
-- the product's own average sales performance and the previous year's sales
WITH yearly_product_sales AS (
    SELECT DATE_TRUNC('year', f.order_date)::date order_year,
           p.product_name,
           SUM(f.sales_amount) current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL -- exclude unparseable-date rows, consistent with the rest of this file
    GROUP BY DATE_TRUNC('year', f.order_date)::date, p.product_name
)
SELECT order_year,
       product_name,
       current_sales,
       ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 2) avg_sales_prod,
       ROUND(current_sales - AVG(current_sales) OVER (PARTITION BY product_name), 2) diff_avg,
       CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
            WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
            ELSE 'Avg'
       END avg_change,
       LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) prev_yr_sales,
       current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) diff_prev_yr,
       CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
            WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
            ELSE 'No Change'
       END prev_yr_change
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- ==============================================================================
-- 4. Part-to-Whole Analysis
-- ==============================================================================

-- Which categories contribute the most to overall sales?
WITH category_total_measures AS (
    SELECT p.category,
           SUM(f.sales_amount) total_sales,
           SUM(f.quantity) total_quantity
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.category
)
SELECT category,
       total_sales,
       SUM(total_sales) OVER () overall_sales,
       CONCAT(ROUND(total_sales::numeric / SUM(total_sales) OVER () * 100, 2), '%') percentage_of_total_sales,
       total_quantity,
       SUM(total_quantity) OVER () overall_quantity,
       CONCAT(ROUND(total_quantity::numeric / SUM(total_quantity) OVER () * 100, 2), '%') percentage_of_total_quantity
FROM category_total_measures
ORDER BY percentage_of_total_sales DESC;
-- "Bikes"        28316272  29356250  "96.46%"  15205  60423  "25.16%"
-- "Accessories"  700262    29356250  "2.39%"   36112  60423  "59.77%"
-- "Clothing"     339716    29356250  "1.16%"   9106   60423  "15.07%"
-- Most of the business revenue comes from Bikes, though most UNITS sold are
-- Accessories — Bikes are low-volume, high-value; Accessories are the opposite

-- ==============================================================================
-- 5. Data Segmentation
-- ==============================================================================

-- Segment products into cost ranges and count how many products fall into each
WITH product_segments AS (
    SELECT product_key,
           product_name,
           cost,
           CASE
               WHEN cost < 100 THEN 'Below 100'
               WHEN cost BETWEEN 100 AND 500 THEN '100-500'
               WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
               ELSE 'Above 1000'
           END AS cost_range
    FROM gold.dim_products
)
SELECT cost_range,
       COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;
-- "Below 100"   110
-- "100-500"     101
-- "500-1000"    45
-- "Above 1000"  39
-- Sums to 295 — matches total_products exactly

-- Group customers into three segments based on spending behavior:
--   VIP     — at least 12 months of history AND spending more than 5,000
--   Regular — at least 12 months of history but spending 5,000 or less
--   New     — lifespan less than 12 months
-- Find the total number of customers in each group
WITH customer_spending AS (
    SELECT c.customer_key,
           SUM(f.sales_amount) total_spending,
           MAX(f.order_date) latest_order,
           MIN(f.order_date) first_order,
           (
               EXTRACT(YEAR FROM AGE(MAX(f.order_date), MIN(f.order_date))) * 12
               + EXTRACT(MONTH FROM AGE(MAX(f.order_date), MIN(f.order_date)))
           ) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
)
SELECT customer_segments,
       COUNT(customer_key) total_customers,
	   sum(total_spending) total_revenue,
	   round(sum(total_spending)/COUNT(customer_key),2) avg_revenue
FROM (
    SELECT
        customer_key,
        total_spending,
        lifespan_months,
        CASE WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'VIP'
             WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
             ELSE 'New'
        END customer_segments
    FROM customer_spending
) t
GROUP BY customer_segments;
-- "New"	14828	11794418	795.42
-- "Regular"	2037	6999831	3436.34
-- "VIP"	1619	10562001	6523.78
-- Sums to 18484 — matches total_customers exactly

WITH customer_spending AS (
    SELECT c.customer_key,
           SUM(f.sales_amount) total_spending,
           MAX(f.order_date) latest_order,
           MIN(f.order_date) first_order,
           (
               EXTRACT(YEAR FROM AGE(MAX(f.order_date), MIN(f.order_date))) * 12
               + EXTRACT(MONTH FROM AGE(MAX(f.order_date), MIN(f.order_date)))
           ) AS lifespan_months
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
	WHERE f.order_date IS NOT NULL
    GROUP BY c.customer_key
)
SELECT customer_segments,
       COUNT(customer_key) total_customers,
	   sum(total_spending) total_revenue,
	   round(sum(total_spending)/COUNT(customer_key),2) avg_revenue
FROM (
    SELECT
        customer_key,
        total_spending,
        lifespan_months,
        CASE WHEN lifespan_months >= 12 AND total_spending > 5000 THEN 'VIP'
             WHEN lifespan_months >= 12 AND total_spending <= 5000 THEN 'Regular'
             ELSE 'New'
        END customer_segments
    FROM customer_spending
) t
GROUP BY customer_segments;
-- "New"	14826	11794065	795.50
-- "Regular"	2039	7008044	3437.00
-- "VIP"	1617	10549149	6523.90