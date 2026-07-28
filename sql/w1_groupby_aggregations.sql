-- ================================================
-- Week 1 | Day 2 | Topic: GROUP BY and Aggregations
-- Dataset: Superstore (9994 rows)
-- Business Focus: Revenue and Profit Analysis
-- ================================================


-- ================================================
-- SECTION 1: BASIC AGGREGATIONS
-- ================================================

-- Overall business summary
-- SUM = total, AVG = average, COUNT = how many
SELECT COUNT(*)                          AS total_orders,
       COUNT(DISTINCT customer_id)       AS unique_customers,
       COUNT(DISTINCT product_id)        AS unique_products,
       ROUND(SUM(sales), 2)              AS total_revenue,
       ROUND(SUM(profit), 2)             AS total_profit,
       ROUND(AVG(sales), 2)              AS avg_order_value,
       ROUND(AVG(profit), 2)             AS avg_profit_per_order,
       ROUND(MIN(sales), 2)              AS min_order_value,
       ROUND(MAX(sales), 2)              AS max_order_value
FROM superstore;


-- ================================================
-- SECTION 2: GROUP BY SINGLE COLUMN
-- ================================================

-- Revenue and profit by category
-- GROUP BY collapses all rows into one per category
SELECT category,
       COUNT(*)                                    AS total_orders,
       ROUND(SUM(sales), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                       AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY category
ORDER BY total_revenue DESC;
-- Result: Technology has highest revenue AND profit margin

-- Revenue and profit by region
SELECT region,
       COUNT(DISTINCT order_id)                    AS total_orders,
       COUNT(DISTINCT customer_id)                 AS unique_customers,
       ROUND(SUM(sales), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                       AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY region
ORDER BY total_revenue DESC;
-- Result: West has highest revenue and profit margin

-- Revenue by customer segment
SELECT segment,
       COUNT(DISTINCT customer_id)                 AS total_customers,
       COUNT(DISTINCT order_id)                    AS total_orders,
       ROUND(SUM(sales), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                       AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY segment
ORDER BY total_revenue DESC;
-- Result: Consumer segment is most valuable


-- ================================================
-- SECTION 3: GROUP BY MULTIPLE COLUMNS
-- ================================================

-- Revenue by category and region
-- Shows which combination performs best
SELECT category,
       region,
       ROUND(SUM(sales), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                       AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY category, region
ORDER BY total_revenue DESC;

-- Revenue by year and category
-- Shows trends over time
SELECT EXTRACT(YEAR FROM order_date)               AS year,
       category,
       ROUND(SUM(sales), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                       AS total_profit
FROM superstore
GROUP BY EXTRACT(YEAR FROM order_date), category
ORDER BY year, total_revenue DESC;


-- ================================================
-- SECTION 4: HAVING CLAUSE
-- ================================================

-- HAVING filters AFTER grouping
-- WHERE filters BEFORE grouping
-- Use HAVING to filter on aggregated values

-- Find categories with profit margin above 12%
SELECT category,
       ROUND(SUM(sales), 2)                        AS total_revenue,
       ROUND(SUM(profit), 2)                       AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2)   AS profit_margin_pct
FROM superstore
GROUP BY category
HAVING ROUND(SUM(profit) / SUM(sales) * 100, 2) > 12
ORDER BY profit_margin_pct DESC;

-- Find states with more than 100 orders
SELECT state,
       COUNT(*) AS total_orders,
       ROUND(SUM(sales), 2) AS total_revenue
FROM superstore
GROUP BY state
HAVING COUNT(*) > 100
ORDER BY total_orders DESC;


-- ================================================
-- SECTION 5: CASE WHEN (if-else in SQL)
-- ================================================

-- Impact of discounts on profit
-- CASE WHEN creates categories from numeric values
SELECT
    CASE
        WHEN discount = 0    THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low (up to 20%)'
        WHEN discount <= 0.4 THEN 'Medium (21-40%)'
        ELSE                      'High (above 40%)'
    END                                            AS discount_level,
    COUNT(*)                                       AS total_orders,
    ROUND(AVG(profit), 2)                          AS avg_profit,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END)   AS loss_orders
FROM superstore
GROUP BY discount_level
ORDER BY avg_profit DESC;
-- Result: High discounts cause most losses
-- Avg profit goes down as discount increases