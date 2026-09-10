/*
===============================================================================
Exploratory Data Analysis (EDA) — Gold Layer
===============================================================================
Script Purpose:
    First step of the analytics phase. Explores the gold
    layer to understand its structure, ranges, and key business metrics before
    building any advanced analysis, reports, or a dashboard on top of it.

    Sections:
    1. Database Exploration      — what schemas/tables/columns exist
    2. Dimension Exploration     — distinct values in dim_customers/dim_products
    3. Date Exploration          — order date range, customer age range
    4. Measures Exploration      — core business KPIs (sales, orders, customers)
    5. Magnitude Analysis        — totals broken down by category (country,
                                   gender, product category)
    6. Ranking Analysis          — best/worst performing products and customers

    Actual result values from running this against the VeloWarehouse gold
    layer are recorded in comments below each query for reference.
===============================================================================
*/

-- ==============================================================================
-- 1. Database Exploration
-- ==============================================================================

-- Explore all objects in the database
SELECT *
FROM information_schema.tables;

-- Explore all columns in the database, scoped to this project's schemas
SELECT table_catalog,
       table_schema,
       table_name,
       column_name,
       data_type,
       is_nullable
FROM information_schema.columns
WHERE table_schema IN ('bronze', 'silver', 'gold')
ORDER BY table_schema, table_name;

-- ==============================================================================
-- 2. Dimension Exploration
-- ==============================================================================

SELECT *
FROM gold.dim_customers;

-- Explore all countries customers come from
SELECT DISTINCT country
FROM gold.dim_customers;
-- 6 countries

-- Explore all product categories (the major divisions) in products
SELECT *
FROM gold.dim_products;

SELECT DISTINCT category, sub_category, product_line, product_name
FROM gold.dim_products
ORDER BY 1, 2, 3;
-- 4 categories
-- 295 products

-- ==============================================================================
-- 3. Date Exploration
-- ==============================================================================

-- Find the first and last order date, and how many years/months of sales exist
SELECT
    MIN(order_date) first_order,
    MAX(order_date) last_order,
    EXTRACT(YEAR FROM MAX(order_date)) - EXTRACT(YEAR FROM MIN(order_date)) AS order_range_years,
    (EXTRACT(YEAR FROM MAX(order_date)) * 12 + EXTRACT(MONTH FROM MAX(order_date)))
    -
    (EXTRACT(YEAR FROM MIN(order_date)) * 12 + EXTRACT(MONTH FROM MIN(order_date))) AS order_range_months
FROM gold.fact_sales;
-- "2010-12-29"  "2014-01-28"  4  37

-- Find the youngest and oldest customer by birth date
SELECT MIN(birth_date) oldest_cust,
       MAX(birth_date) youngest_cust,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, MIN(birth_date))) oldest_age,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAX(birth_date))) youngest_age
FROM gold.dim_customers;
-- "1916-02-10"  "1986-06-25"  110  40

-- ==============================================================================
-- 4. Measures Exploration
-- ==============================================================================

-- Total sales/revenue
SELECT SUM(sales_amount) total_sales
FROM gold.fact_sales;
-- 29356250

-- Total items sold
SELECT SUM(quantity) total_items_sold
FROM gold.fact_sales;
-- 60423

-- Average selling price
SELECT ROUND(AVG(price), 2) avg_selling_price
FROM gold.fact_sales;
-- 486.04

-- Total number of order LINES (not unique orders — see distinct version below)
SELECT COUNT(order_number) total_order_lines
FROM gold.fact_sales;
-- 60398

-- Total number of unique orders (an order can span multiple lines)
SELECT COUNT(DISTINCT order_number) total_orders
FROM gold.fact_sales;
-- 27659

-- Total number of products
SELECT COUNT(product_name) total_products
FROM gold.dim_products;
-- 295

SELECT COUNT(DISTINCT product_name) total_distinct_products
FROM gold.dim_products;
-- 295 (matches above — no duplicate product names)

-- Total number of customers
SELECT COUNT(customer_key) total_customers
FROM gold.dim_customers;
-- 18484

-- Total number of customers that have placed an order
-- Matches total_customers exactly — every customer in the dimension has an order
SELECT COUNT(DISTINCT customer_key) customers_with_orders
FROM gold.fact_sales;
-- 18484

-- Generate a report showing all key business metrics in one result set
SELECT 'Total Sales' AS measure_name,
       SUM(sales_amount) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity Sold',
       SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECT 'Avg Selling Price',
       ROUND(AVG(price), 2)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders',
       COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECT 'Total Products',
       COUNT(DISTINCT product_name)
FROM gold.dim_products
UNION ALL
SELECT 'Total Customers',
       COUNT(customer_key)
FROM gold.dim_customers;
-- "Total Sales"          29356250
-- "Total Quantity Sold"  60423
-- "Avg Selling Price"    486.04
-- "Total Orders"         27659
-- "Total Products"       295
-- "Total Customers"      18484

-- Generate a report showing all key business metrics in one result set (Filtered)
SELECT 'Total Sales' AS measure_name,
       SUM(sales_amount) AS measure_value
FROM gold.fact_sales
where order_date is not null
UNION ALL
SELECT 'Total Quantity Sold',
       SUM(quantity)
FROM gold.fact_sales
where order_date is not null
UNION ALL
SELECT 'Avg Selling Price',
       ROUND(AVG(price), 2)
FROM gold.fact_sales
where order_date is not null
UNION ALL
SELECT 'Total Orders',
       COUNT(DISTINCT order_number)
FROM gold.fact_sales
where order_date is not null
UNION ALL
SELECT 'Total Products',
       COUNT(DISTINCT product_name)
FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(DISTINCT c.customer_key) 
FROM gold.dim_customers c
JOIN gold.fact_sales f ON f.customer_key = c.customer_key
WHERE f.order_date IS NOT NULL;

-- "Total Sales"	29351258
-- "Total Quantity Sold"	60404
-- "Avg Selling Price"	486.11
-- "Total Orders"	27657
-- "Total Products"	295
-- "Total Customers"	18482

-- ==============================================================================
-- 5. Magnitude Analysis
-- ==============================================================================

-- Total customers by country
SELECT country,
       COUNT(customer_key) total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;
-- "United States"   7482
-- "Australia"       3591
-- "United Kingdom"  1913
-- "France"          1810
-- "Germany"         1780
-- "Canada"          1571
-- "n/a"             337
-- Sums to 18484 — matches total_customers exactly

-- Total customers by gender
SELECT gender,
       COUNT(customer_key) total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;
-- "Male"    9341
-- "Female"  9128
-- "n/a"     15
-- Almost evenly split between male and female customers

-- Total products by category
SELECT category,
       COUNT(product_key) total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;
-- "Components"  127
-- "Bikes"       97
-- "Clothing"    35
-- "Accessories" 29
-- [null]        7
-- Sums to 295 — matches total_products exactly

-- Average cost per category
SELECT category,
       ROUND(AVG(cost), 2) avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;
-- "Bikes"       949.44
-- "Components"  264.72
-- [null]        28.57
-- "Clothing"    24.80
-- "Accessories" 13.17
-- Bikes is the most expensive category by far

-- Total revenue generated by each category (fact-driven — only shows
-- categories that actually appear in sales)
SELECT p.category,
       SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
-- "Bikes"        28316272
-- "Accessories"  700262
-- "Clothing"     339716
-- Components and null-category products are missing here — confirmed below
-- that this is a real finding (zero sales), not a join bug

-- Same question from the product side (dim_products LEFT JOIN fact_sales),
-- to confirm Components genuinely has zero revenue rather than being dropped
-- by the previous query's join direction
SELECT p.category,
       SUM(f.sales_amount) total_revenue
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f
    ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
-- "Bikes"        28316272
-- "Accessories"  700262
-- "Clothing"     339716
-- "Components"   [null]   -- confirmed: 127 Components products, never sold
-- [null]         [null]

-- Distribution of items sold across countries
SELECT c.country,
       SUM(f.quantity) total_quantity
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_quantity DESC;
-- "United States"   20481
-- "Australia"       13346
-- "Canada"          7630
-- "United Kingdom"  6910
-- "Germany"         5626
-- "France"          5559
-- "n/a"             871

-- ==============================================================================
-- 6. Ranking Analysis
-- ==============================================================================

-- Top 5 products generating the highest revenue
SELECT *
FROM (
    SELECT p.category,
		   p.product_line,
	       p.product_name,
           SUM(f.sales_amount) total_revenue,
           DENSE_RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS prod_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.category, p.product_line, p.product_name
) ranked_products
WHERE prod_rank <= 5;
-- "Bikes"	"Mountain"	"Mountain-200 Black- 46"	1373454	1
-- "Bikes"	"Mountain"	"Mountain-200 Black- 42"	1363128	2
-- "Bikes"	"Mountain"	"Mountain-200 Silver- 38"	1339394	3
-- "Bikes"	"Mountain"	"Mountain-200 Silver- 46"	1301029	4
-- "Bikes"	"Mountain"	"Mountain-200 Black- 38"	1294854	5
-- Top 5 products generating highest revenue belongs to Bikes category

-- 5 bottom-performing products by revenue
SELECT *
FROM (
    SELECT p.category,
		   p.product_line,
		   p.product_name,
           SUM(f.sales_amount) total_revenue,
           DENSE_RANK() OVER (ORDER BY SUM(f.sales_amount)) AS prod_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    GROUP BY p.category, p.product_line, p.product_name
) ranked_products
WHERE prod_rank <= 5;
-- "Clothing"	"Road"	"Racing Socks- L"	2430	1
-- "Clothing"	"Road"	"Racing Socks- M"	2682	2
-- "Accessories"	"Other Sales"	"Patch Kit/8 Patches"	6382	3
-- "Accessories"	"Other Sales"	"Bike Wash - Dissolver"	7272	4
-- "Accessories"	"Touring"	"Touring Tire Tube"	7440	5

-- Top 10 customers who have generated the highest revenue
SELECT *
FROM (
    SELECT c.customer_key,
           c.first_name,
           c.last_name,
           SUM(f.sales_amount) total_revenue,
           DENSE_RANK() OVER (ORDER BY SUM(f.sales_amount) DESC) AS cust_rank
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_key,
        c.first_name,
        c.last_name
) ranked_customers
WHERE cust_rank <= 10;
-- 1133  "Kaitlyn"    "Henderson"  13294  1
-- 1302  "Nichole"    "Nara"       13294  1
-- 1309  "Margaret"   "He"         13268  2
-- 1132  "Randall"    "Dominguez"  13265  3
-- 1301  "Adriana"    "Gonzalez"   13242  4
-- 1322  "Rosa"       "Hu"         13215  5
-- 1125  "Brandi"     "Gill"       13195  6
-- 1308  "Brad"       "She"        13172  7
-- 1297  "Francisco"  "Sara"       13164  8
-- 434   "Maurice"    "Shan"       12914  9
-- 440   "Janet"      "Munoz"      12488  10

-- 3 customers with the fewest orders placed
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
GROUP BY
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders
LIMIT 3;