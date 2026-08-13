-- ================================================
-- Week 2 | Day 6 | Topic: Recursive CTEs
-- Dataset: Northwind
-- ================================================

-- ================================================
-- SECTION 1: BASIC RECURSIVE CTE
-- Runs repeatedly until stopping condition met
-- ================================================

-- Generate numbers 1 to 10
-- Anchor: starts at 1
-- Recursive: adds 1 each iteration
-- Stops when n reaches 10
WITH RECURSIVE counter AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM counter
    WHERE n < 10
)
SELECT * FROM counter;
-- Result: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10


-- ================================================
-- SECTION 2: DATE SPINE
-- Most common use of recursive CTEs in analytics
-- Generates continuous sequence of dates with no gaps
-- Used to fill missing dates in time series data
-- ================================================

-- Generate every date in 1997
WITH RECURSIVE date_spine AS (
    SELECT '1997-01-01'::date AS dt
    UNION ALL
    SELECT dt + 1
    FROM date_spine
    WHERE dt < '1997-12-31'
)
SELECT
    dt AS date,
    TO_CHAR(dt, 'Day') AS day_name,
    EXTRACT(MONTH FROM dt) AS month,
    EXTRACT(DOW FROM dt) AS day_of_week
FROM date_spine
ORDER BY dt;
-- Result: 365 rows -- every day of 1997
-- January 1 1997 was a Wednesday


-- ================================================
-- SECTION 3: GAP ANALYSIS WITH DATE SPINE
-- Find missing dates in time series data
-- LEFT JOIN date spine to actual data
-- NULL = no data for that date
-- ================================================

-- Find days in 1997 with no orders
WITH RECURSIVE date_spine AS (
    SELECT '1997-01-01'::date AS dt
    UNION ALL
    SELECT dt + 1
    FROM date_spine
    WHERE dt < '1997-12-31'
),
daily_orders AS (
    SELECT
        order_date,
        COUNT(*) AS order_count,
        ROUND(SUM(od.unit_price * od.quantity *
            (1 - od.discount))::numeric, 2) AS daily_revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY order_date
)
SELECT
    ds.dt AS date,
    TO_CHAR(ds.dt, 'Day') AS day_name,
    COALESCE(dord.order_count, 0) AS orders,
    COALESCE(dord.daily_revenue, 0) AS revenue
FROM date_spine ds
LEFT JOIN daily_orders dord ON ds.dt = dord.order_date
ORDER BY ds.dt;
-- Result: 365 rows including days with 0 orders


-- Count days with zero orders
WITH RECURSIVE date_spine AS (
    SELECT '1997-01-01'::date AS dt
    UNION ALL
    SELECT dt + 1
    FROM date_spine
    WHERE dt < '1997-12-31'
),
daily_orders AS (
    SELECT order_date
    FROM orders
    WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY order_date
)
SELECT COUNT(*) AS days_with_no_orders
FROM date_spine ds
LEFT JOIN daily_orders dord ON ds.dt = dord.order_date
WHERE dord.order_date IS NULL;
-- Result: 104 days with no orders


-- Which day of week has most zero order days?
WITH RECURSIVE date_spine AS (
    SELECT '1997-01-01'::date AS dt
    UNION ALL
    SELECT dt + 1
    FROM date_spine
    WHERE dt < '1997-12-31'
),
daily_orders AS (
    SELECT order_date
    FROM orders
    WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY order_date
)
SELECT
    TO_CHAR(ds.dt, 'Day') AS day_name,
    COUNT(*) AS zero_order_days
FROM date_spine ds
LEFT JOIN daily_orders dord ON ds.dt = dord.order_date
WHERE dord.order_date IS NULL
GROUP BY TO_CHAR(ds.dt, 'Day')
ORDER BY zero_order_days DESC;
-- Result: Saturday 52, Sunday 52
-- All 104 zero-order days are weekends
-- Northwind is a purely weekday business