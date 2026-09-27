-- ============================================================
-- E-COMMERCE SALES ANALYTICS PROJECT
-- File: 02_analysis_queries.sql
-- Purpose: Business-driven SQL analysis (the core deliverable)
-- Engine: SQLite
--
-- Each section states a BUSINESS QUESTION, then answers it in SQL.
-- Skills demonstrated: JOINs, aggregation, GROUP BY/HAVING,
-- subqueries, CTEs, window functions, CASE, date functions,
-- RFM segmentation, cohort retention, YoY growth.
-- ============================================================


-- ============================================================
-- SECTION 1: REVENUE FUNDAMENTALS
-- ============================================================

-- Q1. What is total revenue, total orders, and average order value?
-- (Revenue is computed net of discount: quantity * unit_price * (1-discount))
SELECT
    COUNT(DISTINCT o.order_id)                                   AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
          / COUNT(DISTINCT o.order_id), 2)                       AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed';


-- Q2. Monthly revenue trend (with month-over-month % growth)
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date)                              AS year_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY year_month
)
SELECT
    year_month,
    revenue,
    LAG(revenue) OVER (ORDER BY year_month) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month))
        / NULLIF(LAG(revenue) OVER (ORDER BY year_month), 0), 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY year_month;


-- Q3. Running (cumulative) revenue total by month — window function
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date)                              AS year_month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY year_month
)
SELECT
    year_month,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY year_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue
FROM monthly
ORDER BY year_month;


-- ============================================================
-- SECTION 2: PRODUCT & CATEGORY PERFORMANCE
-- ============================================================

-- Q4. Top 10 products by revenue
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity)                                              AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2)  AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;


-- Q5. Revenue and profit margin % by category
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)        AS revenue,
    ROUND(SUM(oi.quantity * p.unit_cost), 2)                              AS total_cost,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
          - SUM(oi.quantity * p.unit_cost), 2)                           AS profit,
    ROUND(100.0 * (SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
          - SUM(oi.quantity * p.unit_cost))
          / SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)     AS profit_margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN orders o   ON o.order_id = oi.order_id
WHERE o.order_status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;


-- Q6. Top 3 products within each category by revenue (window function: RANK)
-- (Wrapped in a subquery since SQLite doesn't support QUALIFY — this pattern
-- is portable to any SQL engine.)
SELECT category, product_name, revenue, rank_in_category
FROM (
    SELECT
        p.category,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue,
        RANK() OVER (
            PARTITION BY p.category
            ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) DESC
        ) AS rank_in_category
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN orders o   ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.category, p.product_name
)
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;


-- Q7. Products that have NEVER been ordered (LEFT JOIN + IS NULL pattern)
SELECT p.product_id, p.product_name, p.category
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;


-- ============================================================
-- SECTION 3: CUSTOMER ANALYSIS
-- ============================================================

-- Q8. Top 10 customers by lifetime spend
SELECT
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    COUNT(DISTINCT o.order_id)                                    AS num_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2)  AS lifetime_spend
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name, c.customer_segment
ORDER BY lifetime_spend DESC
LIMIT 10;


-- Q9. Customer segment performance (Consumer vs Corporate vs Home Office)
SELECT
    c.customer_segment,
    COUNT(DISTINCT c.customer_id)                                 AS num_customers,
    COUNT(DISTINCT o.order_id)                                    AS num_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2)  AS revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
          / COUNT(DISTINCT c.customer_id), 2)                     AS revenue_per_customer
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_segment
ORDER BY revenue DESC;


-- Q10. RFM Segmentation (Recency, Frequency, Monetary) — classic analyst task
-- Buckets customers into 1-4 scores per dimension using NTILE, then
-- combines them into a segment label.
WITH customer_orders AS (
    SELECT
        c.customer_id,
        c.customer_name,
        JULIANDAY('2025-12-31') - JULIANDAY(MAX(o.order_date))        AS recency_days,
        COUNT(DISTINCT o.order_id)                                    AS frequency,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount))          AS monetary
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
),
rfm_scores AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY recency_days ASC)  AS r_score,  -- lower recency_days = more recent = better
        NTILE(4) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(4) OVER (ORDER BY monetary DESC)      AS m_score
    FROM customer_orders
)
SELECT
    customer_id,
    customer_name,
    ROUND(recency_days) AS recency_days,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score, f_score, m_score,
    CASE
        WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Champion'
        WHEN r_score <= 2 AND f_score <= 2                THEN 'Loyal Customer'
        WHEN r_score = 1 AND f_score >= 3                 THEN 'New / Promising'
        WHEN r_score >= 3 AND f_score >= 3                THEN 'At Risk / Churned'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM rfm_scores
ORDER BY monetary DESC;


-- Q11. Cohort retention: for customers acquired in a given signup month,
-- what % placed an order in each subsequent month? (simplified cohort table)
WITH cohorts AS (
    SELECT
        customer_id,
        strftime('%Y-%m', signup_date) AS cohort_month
    FROM customers
),
customer_activity AS (
    SELECT DISTINCT
        o.customer_id,
        strftime('%Y-%m', o.order_date) AS activity_month
    FROM orders o
    WHERE o.order_status = 'Completed'
)
SELECT
    co.cohort_month,
    ca.activity_month,
    COUNT(DISTINCT ca.customer_id) AS active_customers
FROM cohorts co
JOIN customer_activity ca ON ca.customer_id = co.customer_id
WHERE ca.activity_month >= co.cohort_month
GROUP BY co.cohort_month, ca.activity_month
ORDER BY co.cohort_month, ca.activity_month;


-- Q12. Customers who ordered in 2024 but NOT in 2025 (churn candidates)
-- Demonstrates subquery + set-difference logic
SELECT DISTINCT c.customer_id, c.customer_name
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE strftime('%Y', o.order_date) = '2024'
  AND c.customer_id NOT IN (
        SELECT customer_id FROM orders
        WHERE strftime('%Y', order_date) = '2025'
  );


-- ============================================================
-- SECTION 4: OPERATIONS (SHIPPING, RETURNS, CANCELLATIONS)
-- ============================================================

-- Q13. Return / cancellation rate by ship mode
SELECT
    ship_mode,
    COUNT(*)                                                          AS total_orders,
    SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END)        AS returned_orders,
    SUM(CASE WHEN order_status = 'Cancelled' THEN 1 ELSE 0 END)       AS cancelled_orders,
    ROUND(100.0 * SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                              AS return_rate_pct
FROM orders
GROUP BY ship_mode
ORDER BY return_rate_pct DESC;


-- Q14. Average fulfillment time (days between order_date and ship_date) by ship mode
SELECT
    ship_mode,
    ROUND(AVG(JULIANDAY(ship_date) - JULIANDAY(order_date)), 2) AS avg_days_to_ship
FROM orders
WHERE ship_date IS NOT NULL
GROUP BY ship_mode
ORDER BY avg_days_to_ship;


-- ============================================================
-- SECTION 5: ADVANCED / INTERVIEW-STYLE QUESTIONS
-- ============================================================

-- Q15. Year-over-year revenue growth by category
WITH yearly AS (
    SELECT
        p.category,
        strftime('%Y', o.order_date) AS yr,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    JOIN orders o   ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.category, yr
)
SELECT
    category,
    yr,
    ROUND(revenue, 2) AS revenue,
    ROUND(revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY yr), 2) AS yoy_change,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY yr))
          / LAG(revenue) OVER (PARTITION BY category ORDER BY yr), 2)        AS yoy_pct
FROM yearly
ORDER BY category, yr;


-- Q16. Second-highest revenue day (classic "Nth highest" interview question)
SELECT order_date, revenue FROM (
    SELECT
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue,
        DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) DESC) AS rnk
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_date
)
WHERE rnk = 2;


-- Q17. Customers whose most recent order value is above their own historical average
-- (correlated subquery + window function comparison)
WITH order_values AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS order_value
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, o.customer_id, o.order_date
),
ranked AS (
    SELECT
        *,
        AVG(order_value) OVER (PARTITION BY customer_id) AS customer_avg_value,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
    FROM order_values
)
SELECT customer_id, order_id, order_date,
       ROUND(order_value, 2) AS latest_order_value,
       ROUND(customer_avg_value, 2) AS customer_avg_value
FROM ranked
WHERE rn = 1 AND order_value > customer_avg_value
ORDER BY latest_order_value DESC;


-- Q18. Pareto check: do the top 20% of customers drive ~80% of revenue?
WITH customer_rev AS (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY c.customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        NTILE(5) OVER (ORDER BY revenue DESC) AS quintile
    FROM customer_rev
)
SELECT
    quintile,
    COUNT(*)              AS num_customers,
    ROUND(SUM(revenue),2)  AS quintile_revenue,
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM customer_rev), 2) AS pct_of_total_revenue
FROM ranked
GROUP BY quintile
ORDER BY quintile;
