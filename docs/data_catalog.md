# Data Catalog — Gold Layer

## Overview

The gold layer is the business-ready layer of VeloWarehouse, built as a star schema on top of the cleaned silver-layer tables. It consists of two dimension views and one fact view, exposed for direct use in analytics, reporting, and BI tools.

| Object | Type | Role |
|---|---|---|
| `gold.dim_customers` | View | Dimension — customer attributes |
| `gold.dim_products` | View | Dimension — current product attributes |
| `gold.fact_sales` | View | Fact — one row per sales order line |

---

## 1. `gold.dim_customers`

**Purpose:** Provides a single, deduplicated view of each customer, combining CRM customer records with ERP demographic (birth date, gender) and location (country) data. CRM is treated as the master source for gender; the ERP value is only used as a fallback when CRM has no value.

| Column | Data Type | Description |
|---|---|---|
| `customer_key` | `BIGINT` | Surrogate key generated for this warehouse, used to join to `gold.fact_sales`. Not a value from any source system. E.g. `1`, `2`, `3` |
| `customer_id` | `INTEGER` | Source system customer ID from CRM (`cst_id`). E.g. `21768` |
| `customer_number` | `VARCHAR` | CRM business key for the customer (`cst_key`), also used to match this customer to ERP records. E.g. `AW00021768` |
| `first_name` | `VARCHAR` | Customer's first name, trimmed of whitespace. E.g. `Jon` |
| `last_name` | `VARCHAR` | Customer's last name, trimmed of whitespace. E.g. `Yang` |
| `country` | `VARCHAR` | Customer's country, standardized from ERP location data. E.g. `Germany`, `United States`, `n/a` if unknown |
| `marital_status` | `VARCHAR` | Standardized marital status. One of `Married`, `Single`, `n/a` |
| `gender` | `VARCHAR` | Standardized gender. CRM value used if present; otherwise falls back to ERP value. One of `Male`, `Female`, `n/a` |
| `birth_date` | `DATE` | Customer's date of birth, from ERP. Future dates were nulled out during silver-layer cleaning. E.g. `1971-10-06` |
| `create_date` | `DATE` | Date the customer record was first created in the CRM source system. E.g. `2015-03-24` |

---

## 2. `gold.dim_products`

**Purpose:** Provides current product information only — historical versions of a product (tracked via `prd_start_dt`/`prd_end_dt` in silver) are filtered out, keeping just the active record per product. Combines CRM product data with ERP category/subcategory/maintenance reference data.

| Column | Data Type | Description |
|---|---|---|
| `product_key` | `BIGINT` | Surrogate key generated for this warehouse, used to join to `gold.fact_sales`. E.g. `1`, `2`, `3` |
| `product_id` | `INTEGER` | Source system product ID from CRM (`prd_id`). E.g. `310` |
| `product_number` | `VARCHAR` | CRM product key, with the category prefix stripped during silver-layer cleaning (`prd_key`). Matches `sls_prd_key` in sales data. E.g. `R93R-62` |
| `product_name` | `VARCHAR` | Descriptive product name. E.g. `Road-150 Red- 62` |
| `category_id` | `VARCHAR` | Derived category code, used to join to ERP category reference data. E.g. `BI_RB` |
| `category` | `VARCHAR` | Product category from ERP. E.g. `Bikes` |
| `sub_category` | `VARCHAR` | Product subcategory from ERP. E.g. `Road Bikes` |
| `maintenance` | `VARCHAR` | Whether the product requires maintenance, from ERP. One of `Yes`, `No` |
| `cost` | `INTEGER` | Product cost. Nulls were coalesced to `0` during silver-layer cleaning. E.g. `2171` |
| `product_line` | `VARCHAR` | Standardized product line. One of `Mountain`, `Road`, `Other Sales`, `Touring`, `n/a` |
| `start_date` | `DATE` | Date this product version became active. E.g. `2011-07-01` |

---

## 3. `gold.fact_sales`

**Purpose:** One row per sales order line — the transactional core of the warehouse. Connects to both dimension views via their surrogate keys, following standard star schema design (fact table holds keys and measures, dimensions hold descriptive attributes).

| Column | Data Type | Description |
|---|---|---|
| `order_number` | `VARCHAR` | Sales order identifier. A single order can span multiple rows (one per product line). E.g. `SO43697` |
| `product_key` | `BIGINT` | Foreign key to `gold.dim_products.product_key` |
| `customer_key` | `BIGINT` | Foreign key to `gold.dim_customers.customer_key` |
| `order_date` | `DATE` | Date the order was placed. E.g. `2010-12-29` |
| `shipping_date` | `DATE` | Date the order shipped. E.g. `2011-01-05` |
| `due_date` | `DATE` | Expected/promised delivery date. E.g. `2011-01-10` |
| `sales_amount` | `INTEGER` | Total sales value for this order line. Recalculated during silver-layer cleaning wherever the stored value didn't reconcile with `quantity * price`. Business rule: `sales_amount = quantity × price`. E.g. `3578` |
| `quantity` | `INTEGER` | Number of units ordered on this line. E.g. `1` |
| `price` | `INTEGER` | Unit price for this order line. E.g. `3578` |