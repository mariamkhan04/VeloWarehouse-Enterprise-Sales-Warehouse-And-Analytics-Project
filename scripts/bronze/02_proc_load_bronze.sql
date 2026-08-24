/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY` command (PostgreSQL's equivalent of SQL Server's BULK INSERT)
      to load data from CSV files into bronze tables.
 
Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.
 
Usage Example:
    CALL bronze.load_bronze();
 
IMPORTANT — READ BEFORE RUNNING:
    COPY runs on the PostgreSQL SERVER, not your client machine. The file paths below
    must be readable by the OS user that the Postgres server process runs as (not
    necessarily your own Windows/Mac user). If Postgres is running locally on the same
    machine you're working on, this usually works fine — but if you get a "permission
    denied" or "could not open file" error, it's a file-permission issue, not a syntax
    issue. Update the paths below to match where YOUR CSVs actually live.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time       TIMESTAMP;
    end_time         TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time   TIMESTAMP;
BEGIN
	BEGIN 
	    batch_start_time := clock_timestamp();
	    RAISE NOTICE '==========================';
		RAISE NOTICE 'LOADING BRONZE LAYER';
		RAISE NOTICE '==========================';
	
		RAISE NOTICE '--------------------------';
		RAISE NOTICE 'LOADING CRM TABLES';
		RAISE NOTICE '--------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE '>> TRUNCATING TABLE: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		
		RAISE NOTICE '>> INSERTING DATA INTO: bronze.crm_cust_info';
		COPY bronze.crm_cust_info
		FROM 'C:/Users/PMLS/Desktop/SQL Projects/VeloWarehouse-Data-Warehouse-And-Analytics-Project/datasets/source_crm/cust_info.csv'
		WITH (
			FORMAT csv, 
			HEADER true,
			DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
        RAISE NOTICE '>> -------------';

		start_time := clock_timestamp();
		RAISE NOTICE '>> TRUNCATING TABLE: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;
		
		RAISE NOTICE '>> INSERTING DATA INTO: bronze.crm_prd_info';
		COPY bronze.crm_prd_info
		FROM 'C:/Users/PMLS/Desktop/SQL Projects/VeloWarehouse-Data-Warehouse-And-Analytics-Project/datasets/source_crm/prd_info.csv'
		WITH (
			FORMAT csv, 
			HEADER true,
			DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
        RAISE NOTICE '>> -------------';

		start_time := clock_timestamp();
		RAISE NOTICE '>> TRUNCATING TABLE: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
	
		RAISE NOTICE '>> INSERTING DATA INTO: bronze.crm_sales_details';
		COPY bronze.crm_sales_details
		FROM 'C:/Users/PMLS/Desktop/SQL Projects/VeloWarehouse-Data-Warehouse-And-Analytics-Project/datasets/source_crm/sales_details.csv'
		WITH (
			FORMAT csv, 
			HEADER true,
			DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
        RAISE NOTICE '>> -------------';
	
		RAISE NOTICE '--------------------------';
		RAISE NOTICE 'LOADING ERP TABLES';
		RAISE NOTICE '--------------------------';

		start_time := clock_timestamp();
		RAISE NOTICE '>> TRUNCATING TABLE: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
	
		RAISE NOTICE '>> INSERTING DATA INTO: bronze.erp_loc_a101';
		COPY bronze.erp_loc_a101
		FROM 'C:/Users/PMLS/Desktop/SQL Projects/VeloWarehouse-Data-Warehouse-And-Analytics-Project/datasets/source_erp/LOC_A101.csv'
		WITH (
			FORMAT csv, 
			HEADER true,
			DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
        RAISE NOTICE '>> -------------';

		start_time := clock_timestamp();
		RAISE NOTICE '>> TRUNCATING TABLE: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	
		RAISE NOTICE '>> INSERTING DATA INTO: bronze.erp_px_cat_g1v2';
		COPY bronze.erp_px_cat_g1v2
		FROM 'C:/Users/PMLS/Desktop/SQL Projects/VeloWarehouse-Data-Warehouse-And-Analytics-Project/datasets/source_erp/PX_CAT_G1V2.csv'
		WITH (
			FORMAT csv, 
			HEADER true,
			DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
        RAISE NOTICE '>> -------------';

		start_time := clock_timestamp();
		RAISE NOTICE '>> TRUNCATING TABLE: bronze.erp_cust_az12';	
		TRUNCATE TABLE bronze.erp_cust_az12;
	
		RAISE NOTICE '>> INSERTING DATA INTO: bronze.erp_cust_az12';
		COPY bronze.erp_cust_az12
		FROM 'C:/Users/PMLS/Desktop/SQL Projects/VeloWarehouse-Data-Warehouse-And-Analytics-Project/datasets/source_erp/CUST_AZ12.csv'
		WITH (
			FORMAT csv, 
			HEADER true,
			DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 2);
        RAISE NOTICE '>> -------------';

		batch_end_time := clock_timestamp();
		RAISE NOTICE '==========================================';
        RAISE NOTICE 'Loading Bronze Layer is Completed';
        RAISE NOTICE ' - Total Load Duration: % seconds', ROUND(EXTRACT(EPOCH FROM (batch_end_time - batch_start_time))::numeric, 2);
        RAISE NOTICE '==========================================';
		
	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE 'Error State (SQLSTATE): %', SQLSTATE;
        RAISE NOTICE '==========================================';
	END;
END;
$$;