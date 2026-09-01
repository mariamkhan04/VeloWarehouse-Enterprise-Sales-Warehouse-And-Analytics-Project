# VeloWarehouse — Business Insights Report

## Project Objective
Understand what drives VeloWarehouse's sales performance, and identify where revenue, customers, and product value are concentrated - to surface where the business should focus attention.

---

## 1. How is the business performing over time?

- Yearly sales dipped in **2012** following a strong **2011**, then grew sharply in **2013** to reach the dataset's peak. **2014** contains only partial-year data and should not be read as a decline.
- **Bikes** generated the overwhelming majority of revenue in every year, including the **2013 peak** (bikes alone accounted for **$15.35M** of that year's **$16.3M** total), revenue was never accessory-driven.
- Average per-line transaction value fell sharply from over **$3,100** in **2011** to just **$23** by **2014**. This is driven by a growing volume of low-price accessory transactions diluting the simple per-line average, even as bike revenue continued to dominate the total, consistent with Accessories representing **~60%** of units sold but only **~2%** of revenue overall.
- Monthly patterns show stronger **Quarter 4 sales in 2012 and 2013**, though **2011 peaked mid-year** instead, suggestive of, but not confirmed, seasonality given the limited years available.

**So, Revenue growth was driven by bikes throughout the period, the falling average price is a transaction-mix artifact (many small accessory purchases), not evidence of a pricing or category shift in revenue. This dataset alone can't explain the 2012 dip or Q4 patterns; both are worth noting as open questions rather than forcing an explanation**.

## 2. Which products/categories drive the business?

- Bikes generate **~96%** of revenue from only **~25%** of units sold; high-value, low-volume. This is the category actually driving the business (consistent with Q1's finding that revenue growth tracked bikes, not accessories).
- Accessories are the inverse: **~60%** of units sold but only **~2.4%** of revenue,
high-volume, low-value. This is the category responsible for the average-price dilution seen in Q1.
- Clothing sits in between but closer to Accessories: **~15%** of units, **~1.2%** of revenue.
- **Finding:** The Components category **(127 products)** generated **zero revenue** across the entire dataset, and a further 7 products have no category assigned at all. Both were confirmed as genuine zeros, not a join bug, by checking from the product side (`dim_products LEFT JOIN fact_sales`) and getting an explicit `NULL` total either way.

**So, Bikes are the business's actual revenue engine; Accessories and Clothing contribute volume but not meaningful revenue on their own. Components generating zero revenue is worth flagging as an open question for the business. This dataset alone can't tell us whether it's a dead product line, an internal/non-retail category, or a data-entry gap (the same applies to the 7 uncategorized products), but it's a large enough share of the catalog (127 of 295 products, ~43%) to be worth someone's attention**.

## 3. Who are the most valuable customers?

- **Customer segments:** **14,828 New** / **2,037 Regular** / **1,619 VIP** (VIP = 12+ months history and >$5,000 spend). Segment revenue sums exactly to total sales, confirming the segmentation is complete and non-overlapping.
- **VIP** customers make up only **~8.8%** of the customer base but generate **~36%** of total revenue — average revenue per VIP customer **($6,524)** is roughly **8x** that of a New customer **($795)**.
- New customers are the largest group by count (**80%** of all customers) but contribute the least revenue per customer, suggesting most of the base makes only a small number of low-value purchases.
- **Top revenue-generating customers:** Nichole Nara and Kaitlyn Henderson are tied for the highest individual revenue (**$13,294** each), followed by Margaret He (**$13,268**) and Randall Dominguez (**$13,265**) — notably, all four are VIP-segment customers.

**So, Revenue is concentrated in a small VIP segment worth disproportionate attention — a retention-focused strategy targeting the ~1,619 VIP customers would protect a much larger share of revenue than their headcount suggests. The large New-customer base represents either untapped growth potential (converting more into Regular/VIP) or a churn risk worth investigating with data this warehouse doesn't currently capture (e.g., whether "New" customers return after their lifespan window, which isn't trackable without more years of data)**.

## 4. Which products are winning and losing?

- The **top 5 products by revenue** are all variants of a single model **Mountain-200** (different colors/frame sizes), confirming Q1/Q2's finding that **Bikes** drive revenue, but showing that concentration is even tighter than "the Bikes category": one specific model accounts for the entire top 5.
- The **bottom 5 products by revenue** are more spread out **two Clothing items (Racing Socks) and three Accessories items (Patch Kit, Bike Wash, Touring Tire Tube)**, spanning three different product lines rather than clustering in one.
- **Gross margin analysis (avg_selling_price − cost) confirms the bottom-5 products are NOT unprofitable**, every one carries a healthy markup (**100-200% of cost**, e.g. Racing Socks earn $6 margin on a $3 cost). Their low revenue is purely a function of low unit price, not poor margins.
- However, Mountain-200 units generate roughly **$965-981 in gross margin PER UNIT, over 150x the bottom-5 items per-unit margin**, even though its markup percentage (**~77-78% of cost**) is actually lower than the bottom-5's percentage markup. Bikes win on absolute dollars, not on margin efficiency.

**So, There's no evidence to discontinue the bottom-5 products — they're healthily marked up, just structurally low-revenue due to low price points; keeping them likely costs little and may support basket-building or customer retention. The real opportunity lies in the Mountain-200 model specifically: understanding what drives its outsized per-unit margin and revenue (positioning, popularity, or pricing) could inform whether similar economics can be replicated across other bike models, rather than assuming "sell more bikes" applies evenly across the whole category.**

## 5. Data quality notes worth flagging
[Quality Checks Overall - To Verify](/tests/04_quality_checks_overall.sql)

- **Referential integrity is clean:** every row in fact_sales successfully joins to both dim_customers and dim_products, no orphaned foreign keys.
- A small number of sales rows (**~4,992** in value) have unparseable order dates and are excluded from all time-based reporting.
- **337 customers (1.8%)** have unknown country, and **15 customers (0.08%)** have unresolved gender, both remain as 'n/a' after all standardization/fallback logic was applied.
- **7 products (2.4% of the catalog)** have no category assigned, due to their category code not matching any entry in the ERP category reference data, these are excluded from category-level breakdowns.
- **2 products had null/negative cost in the raw source**, defaulted to **0** during cleaning, **margin calculations for these 2 specific products should not be trusted at face value**.
- A small number of ERP birthdates were future-dated in the raw source and were nulled out rather than corrected, age/birth_date is missing (not wrong) for those customers.

---

## Key Findings: Answering the Project Objective

- **Where revenue is concentrated:** Almost entirely in Bikes, specifically the Mountain-200 model, which alone accounts for the entire top-5 revenue list. Bikes generated 96% of all revenue from just 25% of units sold, and this held true in every year of the dataset, including the 2013 peak. Revenue growth over time was a bikes story from start to finish, the appearance of a "shifting mix" (falling average price) was a measurement artifact caused by a flood of low-value Accessories transactions, not an actual change in what drives the business's money.

- **Where customer value is concentrated:** In a small VIP segment. Just 8.8% of customers (1,619 people) generate 36% of total revenue, at roughly 8x the value of an average New customer. The remaining 80% of the customer base (New segment) contributes the least per-customer value, representing either a large pool of untapped growth or a churn risk this dataset can't directly measure.

- **Where product value is concentrated:** Narrower than the category level suggests. Margin analysis confirms that low-revenue products (cheap Accessories/Clothing) are not underperforming on profitability, they're simply small by nature, and shouldn't be judged by revenue alone. The real value concentration sits in one specific bike model's unusually high per-unit margin, not in "bikes" as a category broadly.

- **What's unresolved:** A meaningful share of the catalog (Components + uncategorized products, ~45%) generates no measurable revenue, and this dataset alone can't explain why. A genuine open question for the business, not a data error. Several time-based patterns (the 2012 dip, Q4 strength) are visible but not explainable from sales data alone.

Together, these findings answer the original objective: **the business's success is driven by a small, specific set of high-value elements — one bike model, one customer segment - surrounded by a much larger volume of lower-value activity that doesn't meaningfully move the needle either way.** Attention and resources are best directed at protecting and understanding those concentrated pockets of value, not at the broad averages.

---

## Summary of Recommendations

1. **Investigate what makes the Mountain-200 model outperform so dramatically** (highest single-product margin and revenue in the dataset) and assess whether its pricing, positioning, or features can be replicated across other bike models, this is a more actionable lever than "sell more bikes" generally, since revenue concentration is tighter than the category level.

2. **Build a retention-focused program around the ~1,619 VIP customers.** They're under 9% of the customer base but generate over a third of total revenue, at roughly 8x the value of an average New customer, losing even a handful of these customers would have an outsized impact relative to their headcount.

3. **Do not discontinue low-revenue Accessories/Clothing items** on the assumption they're underperforming, margin analysis shows they're healthily marked up (100-200%) and structurally low-revenue only because of their low price point, not poor unit economics. They likely support basket-building and shouldn't be cut on a revenue-only view.

4. **Investigate the Components category and uncategorized products** (together ~45% of the catalog) before making any catalog decisions, this dataset can't tell us whether Components is a dead product line, an internal/non-retail category, or a data gap, and that ambiguity should be resolved with business context before assuming it's safe to prune.

5. **Treat the 2012 sales dip, 2013 Q4 pattern, and the large New-customer segment as open questions requiring more data, not conclusions.** This dataset alone (3 full years, no external context) can't explain *why* these patterns exist. Further investigation should combine this analysis with marketing calendars, promotional history, or additional years of data before acting on assumptions about seasonality or churn risk.