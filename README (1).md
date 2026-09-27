# E-Commerce Sales Analytics — SQL Project

A complete, end-to-end SQL analytics project built on a realistic synthetic
e-commerce dataset (400 customers, 113 products, 6,000 orders, 11,200 order
line items across 2024–2025). Built for a data analyst internship portfolio.

## Why this project
Retail/e-commerce sales analysis is one of the most common real-world data
analyst tasks and one of the most common SQL interview themes. This project
demonstrates the full analyst toolkit in a single, coherent business
narrative rather than 20 disconnected snippets:

- Core aggregation & JOINs
- Subqueries (correlated and non-correlated)
- CTEs (`WITH` clauses) for readable, layered logic
- Window functions: `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `NTILE`, `LAG`,
  running totals
- Business frameworks: **RFM segmentation**, **cohort retention**,
  **Pareto/80-20 analysis**, **YoY growth**
- Classic interview questions ("Nth highest value", "customers with no
  orders", etc.)

## Files in this project

| File                       | Purpose                                                        |
|----------------------------|-----------------------------------------------------------------|
| `01_schema.sql`            | DDL — table definitions, constraints, indexes                  |
| `generate_data.py`         | Builds the realistic synthetic dataset (documented, seeded)     |
| `ecommerce.db`             | The populated SQLite database, ready to query                  |
| `02_analysis_queries.sql`  | **The core deliverable** — 18 business-question-driven queries |
| `run_and_verify.py`        | Test harness confirming every query runs without error         |
| `insights_summary.md`      | Plain-English write-up of key findings (for your resume/README)|

## Data model (ERD)

```
customers                    orders                      order_items                 products
----------                   ------                       -----------                 --------
customer_id (PK)  ───┐        order_id (PK)   ───┐          order_item_id (PK)          product_id (PK)
customer_name        └──────< customer_id          └───────< order_id                     product_name
email                          order_date                     product_id  >───────────────  category
city / state / country         ship_date                      quantity                     sub_category
signup_date                    ship_mode                      unit_price                   unit_price
customer_segment                order_status                  discount                     unit_cost
```

- One **customer** → many **orders** (1-to-many)
- One **order** → many **order_items** (1-to-many, order "header/detail" pattern)
- One **product** → many **order_items** (1-to-many)
- `order_items` is the fact table: revenue = `quantity * unit_price * (1 - discount)`

This header/detail design mirrors real production schemas (Shopify, Amazon,
Salesforce Orders, etc.) — showing you understand normalized transactional
data rather than a single flattened spreadsheet.

## How to run it

**Option A — Python (recommended, zero setup):**
```bash
python3 generate_data.py        # rebuilds ecommerce.db from scratch
python3 run_and_verify.py       # runs every query, prints results
```

**Option B — any SQLite GUI (DB Browser for SQLite, TablePlus, DBeaver):**
Open `ecommerce.db` directly and run statements from `02_analysis_queries.sql`.

**Option C — command line sqlite3** (if installed on your machine):
```bash
sqlite3 ecommerce.db < 01_schema.sql   # only needed if rebuilding schema
sqlite3 ecommerce.db
sqlite> .read 02_analysis_queries.sql
```

## How to present this in an internship application
1. Put the repo on GitHub with this README as the landing page.
2. In your resume, list it as:
   *"E-Commerce Sales Analytics (SQL, SQLite) — Designed a 4-table relational
   schema and wrote 18 analytical queries covering revenue trends, RFM
   customer segmentation, cohort retention, and YoY growth using window
   functions and CTEs."*
3. Be ready to explain **one query in depth** in an interview — Q10 (RFM) or
   Q11 (cohort retention) are the most impressive to walk through on a
   whiteboard.
4. If asked "why SQLite," explain: zero-setup, fully portable syntax to
   Postgres/MySQL, ideal for a self-contained take-home artifact.

## Extending this project (good talking points for interviews)
- Swap SQLite for PostgreSQL and add `EXPLAIN ANALYZE` query-plan discussion.
- Add a `marketing_spend` table and compute customer acquisition cost (CAC)
  and CAC-to-LTV ratio.
- Connect the output of these queries to a BI tool (Tableau/Power BI/Looker)
  for a dashboard layer on top of the SQL layer.
- Add a `reviews` table and analyze the relationship between review score
  and return rate.
