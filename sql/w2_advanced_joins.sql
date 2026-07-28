-- ================================================
-- Week 1 | Day 2 | Topic: JOINs
-- Dataset: Superstore (9994 rows)
-- Note: Superstore is one table
-- We simulate joins using subqueries and CTEs
-- In Week 2 we will use Northwind for multi-table JOINs
-- ================================================


-- ================================================
-- SECTION 1: SELF JOIN
-- Joining a table to itself
-- ================================================

-- Find customers who ordered from multiple regions
-- Self join to compare same customer across different rows
SELECT DISTINCT s1.customer_name,
       s1.region AS region_1,
       s2.region AS region_2
FROM superstore s1
JOIN superstore s2
    ON s1.customer_id = s2.customer_id
    AND s1.region != s2.region
ORDER BY s1.customer_name;
-- Result: Customers who bought in multiple regions


-- ================================================
-- SECTION 2: JOIN WITH SUBQUERY
-- Joining main table to a derived table
-- ================================================

-- Show each order with its category average sales
-- Join superstore to a category summary subquery
SELECT s.order_id,
       s.customer_name,
       s.category,
       ROUND(s.sales, 2)        AS order_sales,
       cat.avg_category_sales,
       CASE
           WHEN s.sales > cat.avg_category_sales
           THEN 'Above Average'
           ELSE 'Below Average'
       END                      AS performance
FROM superstore s
JOIN (
    SELECT category,
           ROUND(AVG(sales), 2) AS avg_category_sales
    FROM superstore
    GROUP BY category
) AS cat ON s.category = cat.category
ORDER BY s.category, order_sales DESC;


-- ================================================
-- SECTION 3: LEFT JOIN WITH SUBQUERY
-- Keep all rows from left table
-- NULL where no match in right table
-- ================================================

-- Show all customers and their total orders
-- Including customers with only one order
SELECT s.customer_name,
       s.segment,
       s.region,
       ROUND(SUM(s.sales), 2)   AS total_revenue,
       COUNT(DISTINCT s.order_id) AS total_orders
FROM superstore s
LEFT JOIN (
    SELECT DISTINCT customer_id
    FROM superstore
    WHERE category = 'Technology'
) AS tech_buyers
    ON s.customer_id = tech_buyers.customer_id
GROUP BY s.customer_name, s.segment, s.region
ORDER BY total_revenue DESC
LIMIT 20;


-- ================================================
-- SECTION 4: JOINING WITH CTE
-- Cleaner alternative to subquery joins
-- ================================================

-- Find orders that are above average
-- for both sales AND profit in their category
WITH category_benchmarks AS (
    SELECT category,
           AVG(sales)  AS avg_sales,
           AVG(profit) AS avg_profit
    FROM superstore
    GROUP BY category
)
SELECT s.order_id,
       s.customer_name,
       s.category,
       ROUND(s.sales, 2)   AS sales,
       ROUND(s.profit, 2)  AS profit
FROM superstore s
JOIN category_benchmarks cb ON s.category = cb.category
WHERE s.sales  > cb.avg_sales
AND   s.profit > cb.avg_profit
ORDER BY s.category, s.profit DESC;
-- Result: Orders that beat both benchmarks in their category