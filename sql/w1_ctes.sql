-- ================================================
-- Topic: CTEs
-- Dataset: Superstore (9994 rows)
-- ================================================

-- ================================================
-- BASIC CTE
-- Used when you need to filter on calculated fields
-- ================================================

-- Business Question 1:
-- Which regions have profit margin above 12%?
-- Cannot filter on calculated margin in WHERE
-- Calculate it in CTE first then filter

WITH region_summary AS (
    SELECT region,
           SUM(sales)  AS total_revenue,
           SUM(profit) AS total_profit,
           ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct
    FROM superstore
    GROUP BY region
)
SELECT region,
       total_revenue,
       total_profit,
       margin_pct
FROM region_summary
WHERE margin_pct > 12
ORDER BY margin_pct DESC;

-- Result: West and East have margin above 12%
-- Central and South fall below 12%


-- ================================================
-- CHAINED CTEs
-- Used when calculation depends on another calculation
-- CTE 2 can reference CTE 1
-- ================================================

-- Business Question 2:
-- Who are top 10 customers in profitable regions only?
-- Step 1: Find profitable regions (margin > 12%)
-- Step 2: Find top customers in those regions

WITH profitable_regions AS (
    SELECT region,
           ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct
    FROM superstore
    GROUP BY region
    HAVING ROUND(SUM(profit) / SUM(sales) * 100, 2) > 12
),
top_customers AS (
    SELECT s.customer_name,
           s.region,
           ROUND(SUM(s.sales), 2)  AS total_revenue,
           ROUND(SUM(s.profit), 2) AS total_profit
    FROM superstore s
    JOIN profitable_regions p ON s.region = p.region
    GROUP BY s.customer_name, s.region
)
SELECT customer_name,
       region,
       total_revenue,
       total_profit
FROM top_customers
ORDER BY total_revenue DESC
LIMIT 10;

-- Result: Raymond Bush from West is top customer
-- in profitable regions


-- ================================================
-- CTE WITH DATE FUNCTIONS
-- Used for time series analysis
-- ================================================

-- Business Question 3:
-- What is monthly revenue and cumulative
-- revenue trend for 2017?
-- Step 1: Calculate monthly revenue
-- Step 2: Calculate running total

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        ROUND(SUM(sales), 2)            AS monthly_sales,
        ROUND(SUM(profit), 2)           AS monthly_profit
    FROM superstore
    WHERE EXTRACT(YEAR FROM order_date) = 2017
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    monthly_sales,
    monthly_profit,
    ROUND(SUM(monthly_sales) OVER (
        ORDER BY month
    ), 2) AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;

-- Result: December had highest monthly revenue
-- Total 2017 cumulative revenue: 733,215