/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'velo_warehouse' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'velo_warehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.
*/

-- Step 1: Connect to the default 'postgres' database first (can't drop a database while connected to it)

-- Step 2: Terminate any active connections to 'velo_warehouse' so the drop doesn't fail
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'velo_warehouse' AND pid <> pg_backend_pid();

-- Step 3: Drop the 'velo_warehouse' database if it exists
DROP DATABASE IF EXISTS velo_warehouse;

-- Step 4: Create the 'velo_warehouse' database
CREATE DATABASE velo_warehouse;

-- Step 5: Connect to the newly created database

-- Step 6: Create Schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;