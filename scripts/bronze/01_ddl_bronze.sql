/*
=============================================================
DDL Script: Create Bronze Tables
=============================================================
Script Purpose:
    - This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.
    - Run this script to re-define the DDL structure of 'bronze' tables.
 
Notes:
    Bronze layer = raw, unprocessed data as-is from the source systems.
    No transformations, no data type conversions beyond what's needed to land the file.
    Source date columns (e.g. sls_order_dt) are stored as INTEGER here because that is
    how they exist in the raw CRM CSV (format YYYYMMDD) — converting them to proper
    DATE type happens in the silver layer, not here.
=============================================================
*/
 
-- ============================
-- CRM source tables
-- ============================

DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE IF NOT EXISTS bronze.crm_cust_info
(
	cst_id INTEGER,
	cst_key VARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(50),
	cst_gndr VARCHAR(50),
	cst_create_date DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE IF NOT EXISTS bronze.crm_prd_info
(
	prd_id INTEGER,
	prd_key	VARCHAR(50),
	prd_nm	VARCHAR(50),
	prd_cost INTEGER,
	prd_line VARCHAR(50),
	prd_start_dt TIMESTAMP,
	prd_end_dt TIMESTAMP
);

DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE IF NOT EXISTS bronze.crm_sales_details
(
	sls_ord_num	VARCHAR(50),
	sls_prd_key	VARCHAR(50),
	sls_cust_id	INTEGER,
	sls_order_dt INTEGER,
	sls_ship_dt	INTEGER,
	sls_due_dt INTEGER,
	sls_sales INTEGER,
	sls_quantity INTEGER,
	sls_price INTEGER
);

-- ============================
-- ERP source tables
-- ============================

DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE IF NOT EXISTS bronze.erp_loc_a101
(
	cid	VARCHAR(50),
	cntry VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE IF NOT EXISTS bronze.erp_px_cat_g1v2
(
	id VARCHAR(50),
	cat	VARCHAR(50),
	subcat VARCHAR(50),
	maintenance VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_cust_az12;
CREATE TABLE IF NOT EXISTS bronze.erp_cust_az12
(
	cid	VARCHAR(50),
	bdate DATE,
	gen VARCHAR(50)
);