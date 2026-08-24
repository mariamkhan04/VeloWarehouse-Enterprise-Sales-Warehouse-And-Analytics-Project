# Naming Conventions

This document defines the naming conventions used for schemas, tables, views, columns, and stored procedures throughout the VeloWarehouse project.

## General Principles

- **Case:** `snake_case`, all lowercase, with underscores separating words (e.g. `customer_info`)
- **Language:** English, for all object and column names
- **Reserved words:** Never use SQL reserved words as object or column names

## Table Naming by Layer

Table names follow a layer-specific pattern that reflects each layer's role in the medallion architecture.

### Bronze Layer
Pattern: `<sourcesystem>_<entity>`

- `<sourcesystem>`: the source system the data comes from (e.g. `crm`, `erp`)
- `<entity>`: the exact table name from the source system

Example: `crm_cust_info`, `erp_loc_a101`

### Silver Layer
Pattern: `<sourcesystem>_<entity>`

Same convention as bronze — table structure mirrors the source, only the data inside is cleaned and standardized.

Example: `crm_cust_info`, `erp_loc_a101`

### Gold Layer
Pattern: `<category>_<entity>`

- `<category>`: describes the role of the table in the data model
  - `dim_` — dimension table
  - `fact_` — fact table
  - `agg_` — aggregated/summary table
- `<entity>`: descriptive, business-aligned name

Example: `dim_customers`, `fact_sales`

## Column Naming Conventions

| Column type | Convention | Example |
|---|---|---|
| Surrogate keys | `<table_name>_key` | `customer_key`, `product_key` |
| Technical columns (added by the warehouse, not from the source system) | `dwh_<column_name>` | `dwh_create_date` |

## Stored Procedure Naming

Pattern: `load_<layer>`

- `load_bronze` — loads raw data into the bronze layer
- `load_silver` — loads cleaned/transformed data into the silver layer

(Gold layer objects are views, not loaded via procedure — see Architecture note below.)