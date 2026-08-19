-- ================================================
-- Week 2 | Day 7 | Topic: Cohort Analysis
-- Dataset: Northwind
-- Business Focus: Customer Retention Analysis
-- ================================================

-- ================================================
-- STEP 1: Find each customer's first order month
-- This defines which cohort they belong to
-- ================================================

SELECT
    customer_id,
    DATE_TRUNC('month', MIN(order_date)) AS cohort_month
FROM orders
GROUP BY customer_id
ORDER BY cohort_month;
-- Result: 89 customers with their cohort month
-- Starting from July 1996


-- ================================================
-- STEP 2: Calculate months since first order
-- For every order, how many months after joining?
-- ================================================

WITH first_order AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
)
SELECT
    o.customer_id,
    f.cohort_month,
    DATE_TRUNC('month', o.order_date) AS order_month,
    EXTRACT(YEAR FROM AGE(
        DATE_TRUNC('month', o.order_date),
        f.cohort_month
    )) * 12 +
    EXTRACT(MONTH FROM AGE(
        DATE_TRUNC('month', o.order_date),
        f.cohort_month
    )) AS month_since_first
FROM orders o
JOIN first_order f ON o.customer_id = f.customer_id
ORDER BY f.cohort_month, o.customer_id, month_since_first;
-- Result: 830 rows -- one per order with month number


-- ================================================
-- STEP 3: Count active customers per cohort per month
-- ================================================

WITH first_order AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        o.customer_id,
        f.cohort_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) AS month_since_first
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
)
SELECT
    cohort_month,
    month_since_first,
    COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_data
GROUP BY cohort_month, month_since_first
ORDER BY cohort_month, month_since_first;


-- ================================================
-- STEP 4: Full cohort retention analysis
-- With retention percentage per cohort per month
-- ================================================

WITH first_order AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        o.customer_id,
        f.cohort_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) AS month_since_first
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
),
cohort_size AS (
    -- Count customers at month 0 per cohort
    -- This is the denominator for retention percentage
    SELECT cohort_month,
           COUNT(DISTINCT customer_id) AS total
    FROM cohort_data
    WHERE month_since_first = 0
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month,
    cd.month_since_first,
    COUNT(DISTINCT cd.customer_id)            AS active_customers,
    cs.total                                   AS cohort_size,
    ROUND(COUNT(DISTINCT cd.customer_id)::numeric
          / cs.total * 100, 1)                AS retention_pct
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
GROUP BY cd.cohort_month, cd.month_since_first, cs.total
ORDER BY cd.cohort_month, cd.month_since_first;
-- Result: 183 rows covering all cohorts
-- July 1996 cohort: 20 customers, month 1 retention 20%
-- November 1996 cohort: 10 customers, month 1 retention 70%


-- ================================================
-- BUSINESS INSIGHT: Which cohort has best retention?
-- Compare month 1 retention across all cohorts
-- Filter to cohorts with at least 5 customers
-- ================================================

WITH first_order AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_data AS (
    SELECT
        o.customer_id,
        f.cohort_month,
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) AS month_since_first
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
),
cohort_size AS (
    SELECT cohort_month,
           COUNT(DISTINCT customer_id) AS total
    FROM cohort_data
    WHERE month_since_first = 0
    GROUP BY cohort_month
)
SELECT
    cd.cohort_month,
    COUNT(DISTINCT cd.customer_id)            AS active_customers,
    cs.total                                   AS cohort_size,
    ROUND(COUNT(DISTINCT cd.customer_id)::numeric
          / cs.total * 100, 1)                AS retention_pct
FROM cohort_data cd
JOIN cohort_size cs ON cd.cohort_month = cs.cohort_month
WHERE cd.month_since_first = 1
AND   cs.total >= 5
GROUP BY cd.cohort_month, cs.total
ORDER BY retention_pct DESC;
-- Result:
-- Best:  November 1996 cohort -- 70% month 1 retention
-- Worst: July 1996 cohort -- 20% month 1 retention
-- Business question: What was different about November 1996?