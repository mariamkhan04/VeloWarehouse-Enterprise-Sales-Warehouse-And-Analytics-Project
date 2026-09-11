# VeloWarehouse — Enterprise Sales Data Warehouse & Analytics

An end-to-end data engineering and analytics project: raw CRM/ERP data → PostgreSQL data warehouse (medallion architecture) → SQL analytics → interactive Excel dashboard.

**[Interactive Dashboard Video](docs/dashboard%20screenshots%20and%20video/velowarehouse.mp4)**
<video src="https://github.com/user-attachments/assets/e57909bf-71b9-4fb8-88b2-6a4c0096d5c0" controls width="100%"></video>

---

## Executive Summary

VeloWarehouse analyzes 5 years (2010–2014) of sales data for a fictional bicycle manufacturer, built from raw CRM and ERP source files into a fully modeled PostgreSQL data warehouse, then explored through SQL analytics and visualized in a 3-page interactive Excel dashboard.

**Key finding:** the business's revenue is driven almost entirely by one product line — Bikes generate 96% of revenue from just 25% of units sold — and within that, by one specific model (Mountain-200), which alone accounts for the entire top-5 revenue list. Customer value follows the same concentration pattern: just 8.8% of customers (VIP segment) generate over a third of total revenue, at roughly 8x the value of an average customer.

---

## Problem / Purpose

Businesses often sit on transactional data without a structured way to ask "where does our value actually come from?" This project builds that structure from scratch — a proper data warehouse, not just a spreadsheet — to answer one guiding question:

> **What drives VeloWarehouse's sales performance, and where are revenue, customers, and product value concentrated — so the business knows where to focus attention?**

Every layer of this project, from the raw ETL pipeline to the final dashboard, is built to answer that question with evidence, not assumption.

---

## Approach

1. **Data ingestion (Bronze layer)** — raw CRM (`cust_info`, `prd_info`, `sales_details`) and ERP (`CUST_AZ12`, `LOC_A101`, `PX_CAT_G1V2`) CSVs loaded as-is into PostgreSQL via a stored procedure, no transformation.
2. **Cleaning & standardization (Silver layer)** — deduplication, key format reconciliation between CRM/ERP sources, date parsing, gender/marital status/country standardization, SCD Type 1 handling.
3. **Business modeling (Gold layer)** — a proper star schema (`dim_customers`, `dim_products`, `fact_sales`) with surrogate keys, built as PostgreSQL views on top of Silver.
4. **Analytics** — SQL-based EDA, advanced analysis (time trends, cumulative/running totals, year-over-year performance, part-to-whole, customer/product segmentation), and two report views (`report_customers`, `report_products`).
5. **Insights synthesis** — a structured business insights report answering 5 core questions, cross-referencing findings against each other and against raw SQL to validate every claim.
6. **Dashboard** — a 3-page interactive Excel dashboard (Power Query → Power Pivot data model → DAX measures → PivotCharts → slicers), independently built and validated against the SQL layer.

---

## Key Findings

| Metric | Value |
|---|---|
| Total Revenue | $29.35M |
| Total Orders | 27,657 |
| Total Customers | 18,482 |
| Average Order Value | $1,061 |
| Revenue from Bikes | 96% (from only 25% of units sold) |
| VIP customer share of revenue | ~36% (from 8.8% of customers) |
| Top single product | Mountain-200 Black-46 ($1.37M revenue) |

- **Revenue is bike-driven, not accessory-driven** — the appearance of a category "shift" (falling average transaction price) was a transaction-mix measurement artifact, not a real revenue shift, confirmed by decomposing average price into its underlying volume/value components.
- **A small VIP segment carries disproportionate value** — 1,617 customers (8.8%) generate over a third of revenue, at ~8x the value of an average customer.
- **Low-revenue products are not unprofitable** — margin analysis on the bottom 5 products by revenue found healthy 100–200% markups; low revenue is a function of low price point, not poor economics.
- **The Components category (43% of the catalog) generates zero revenue** — confirmed as a genuine finding (not a data bug) via a join-direction diagnostic; flagged as an open business question rather than assumed to be a dead product line.

Full narrative, evidence, and business recommendations are in [`reports/insights_report.md`](reports/insights_report.md).

---

## Dashboard

Three pages, built on a live Power Pivot data model connected directly to PostgreSQL, with cross-page navigation and Year/Category/Segment slicers:

| Page | Focus |
|---|---|
| **Performance Overview** | Revenue trend, category revenue/volume mirror comparison, quarterly and monthly seasonality|
| **Customer Insights** | Segment concentration (New/Regular/VIP), average revenue per segment, top customers, geographic distribution |
| **Product Insights** | Category and cost-range breakdown, top/bottom 5 products by revenue with margin analysis |

![Performance Overview](docs/dashboard%20screenshots%20and%20video/P1_performance_overview.png)
![Customer Insights](docs/dashboard%20screenshots%20and%20video/P2_customer_insights.png)
![Product Insights](docs/dashboard%20screenshots%20and%20video/P3_product_insights.png)

---

## Limitations

- **Time span:** only ~3 full years of dated sales data (2010–2013) plus a partial 2014 — patterns like the 2012 dip and Q4 seasonality are observed but not statistically confirmed given the limited window.
- **Data quality gaps (documented, not hidden):** ~4,992 in sales value sits on rows with unparseable order dates and is excluded from all time-based analysis; 337 customers have an unknown country; 2.4% of the product catalog has no assigned category.
- **No external business context:** the dataset cannot explain *why* patterns exist (e.g., the 2012 sales dip, the Components category's zero revenue) — these are flagged as open questions in the insights report rather than forced explanations.
- **Excel/DAX vs. SQL rounding:** minor (<0.03%) discrepancies exist between SQL and dashboard customer segment counts due to different date-boundary calculation methods between PostgreSQL and DAX — documented in the insights report, immaterial to any conclusion.

Full data quality notes: see Section 5 of [`reports/insights_report.md`](reports/insights_report.md).

---

## Tech Stack

- **Database:** PostgreSQL
- **ETL / Transformation:** PL/pgSQL stored procedures
- **Architecture:** Medallion (Bronze/Silver/Gold), star schema
- **Analytics:** SQL (window functions, CTEs, DENSE_RANK, part-to-whole analysis)
- **Dashboard:** Excel (Power Query, Power Pivot, DAX, PivotCharts, Slicers)
- **Version control:** Git / GitHub

---

## Folder Structure

<details>
<summary><strong>📂 Folder Structure</strong></summary>

```text
VeloWarehouse/
├── datasets/                  # Raw source CSVs (CRM + ERP)
├── scripts/
│   ├── init_database.sql
│   ├── bronze/                # Raw ingestion layer
│   ├── silver/                # Cleaning & transformation layer
│   └── gold/                  # Star schema views
├── analysis/                  # EDA, advanced analysis, report views
│   ├── 01_eda.sql
│   ├── 02_advance_analysis.sql
│   ├── 03_customer_report.sql
│   ├── 04_product_report.sql
│   └── 05_reports_validation.sql
├── tests/                     # Data quality checks per layer
├── dashboard/
│   └── VeloWarehouse_Dashboard.xlsx
├── docs/                      # Architecture diagrams, data catalog, screenshots
├── reports/
│   └── insights_report.md
└── README.md
```

</details>

---

## Future Work

- Automate the Bronze/Silver load process with Python (scripted orchestration in place of manual `CALL` execution)
- Host the Gold layer on a free-tier cloud PostgreSQL provider for broader accessibility
- Extend the dashboard with year-over-year DAX time-intelligence measures

---

## Ownership & Credits

Built independently by **Mariam Khan** as an end-to-end portfolio project. The initial data warehouse structure follows [Data With Baraa's SQL Data Warehouse & Analytics project](https://github.com/DataWithBaraa/sql-data-warehouse-project) as a structural reference; all implementation was rebuilt in PostgreSQL (from the tutorial's SQL Server), independently translated, debugged, and extended with original data quality investigation, an independently designed star schema and naming conventions, an original insights report, and a fully custom Excel dashboard built on a self-designed data model.

## Connect

**Mariam Khan** | [LinkedIn](https://www.linkedin.com/in/mariam-khan0424/) | [GitHub](https://github.com/mariamkhan04)
