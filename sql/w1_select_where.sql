-- Topic: SELECT and WHERE Clauses
-- Dataset: Superstore (9994 rows)
-- ================================================

-- BASIC SELECT
-- Explore first 10 rows of data
SELECT *
FROM superstore
LIMIT 10;

-- SELECT specific columns only
SELECT customer_name, sales, profit
FROM superstore
LIMIT 10;

-- ================================================
-- BUSINESS INSIGHTS
-- ================================================

-- Q1: Which category generates most revenue?
SELECT category,
       SUM(sales) AS total_revenue
FROM superstore
GROUP BY category
ORDER BY total_revenue DESC;

-- Q2: Revenue, profit and margin by category
SELECT category,
       SUM(sales) AS total_revenue,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY category
ORDER BY total_profit DESC;

-- Q3: Revenue and profit by region
SELECT region,
       SUM(sales) AS total_revenue,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct,
       COUNT(DISTINCT order_id) AS total_orders
FROM superstore
GROUP BY region
ORDER BY total_revenue DESC;

-- Q4: Most valuable customer segment
SELECT segment,
       COUNT(DISTINCT customer_id) AS total_customers,
       COUNT(DISTINCT order_id) AS total_orders,
       SUM(sales) AS total_revenue,
       SUM(profit) AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct
FROM superstore
GROUP BY segment
ORDER BY total_revenue DESC;

-- ================================================
-- WHERE CLAUSE
-- ================================================

-- Q5: Orders with negative profit (losses)
SELECT order_id,
       customer_name,
       category,
       sales,
       profit
FROM superstore
WHERE profit < 0
ORDER BY profit ASC;

-- Q6: Impact of discounts on profit
SELECT 
    CASE 
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low Discount (up to 20%)'
        WHEN discount <= 0.4 THEN 'Medium Discount (21-40%)'
        ELSE 'High Discount (above 40%)'
    END AS discount_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(profit), 2) AS avg_profit,
    SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) AS loss_orders
FROM superstore
GROUP BY discount_category
ORDER BY avg_profit DESC;

-- Q7: Loss making Furniture orders in West (AND)
SELECT order_id,
       customer_name,
       sub_category,
       sales,
       discount,
       profit
FROM superstore
WHERE category = 'Furniture'
AND region = 'West'
AND profit < 0
ORDER BY profit ASC;

-- Q8: Loss making orders using IN
SELECT order_id,
       customer_name,
       category,
       sub_category,
       sales,
       discount,
       profit
FROM superstore
WHERE category IN ('Furniture', 'Office Supplies')
AND profit < 0
ORDER BY profit ASC;

-- Q9: Orders with sales BETWEEN 500 and 1000
SELECT order_id,
       customer_name,
       category,
       sales,
       profit
FROM superstore
WHERE sales BETWEEN 500 AND 1000
ORDER BY sales DESC;

-- Q10: Customers whose name starts with A (LIKE)
SELECT DISTINCT customer_name,
       segment,
       city,
       state
FROM superstore
WHERE customer_name LIKE 'A%'
ORDER BY customer_name;

-- Q11: Phone products (LIKE with % on both sides)
SELECT DISTINCT product_name,
       category,
       sub_category,
       sales,
       profit
FROM superstore
WHERE product_name LIKE '%Phone%'
ORDER BY sales DESC;

-- Q12: Data quality check - NULL values
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(row_id) AS missing_row_id,
    COUNT(*) - COUNT(order_id) AS missing_order_id,
    COUNT(*) - COUNT(customer_name) AS missing_customer_name,
    COUNT(*) - COUNT(postal_code) AS missing_postal_code,
    COUNT(*) - COUNT(sales) AS missing_sales,
    COUNT(*) - COUNT(profit) AS missing_profit
FROM superstore;