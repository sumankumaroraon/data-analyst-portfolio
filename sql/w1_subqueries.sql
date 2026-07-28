-- ================================================
-- Topic: Subqueries
-- Dataset: Superstore (9994 rows)
-- Business Focus: Customer and Product Analysis
-- ================================================


-- ================================================
-- TYPE 1: SUBQUERY IN WHERE CLAUSE
-- Used when you need one value to compare against
-- ================================================

-- Business Question 1:
-- Which orders have sales above the overall average?
-- We cannot write WHERE sales > AVG(sales) directly
-- So we use a subquery to calculate average first

SELECT order_id,
       customer_name,
       category,
       sales,
       ROUND((SELECT AVG(sales) FROM superstore), 2) AS overall_avg_sales
FROM superstore
WHERE sales > (SELECT AVG(sales) FROM superstore)
ORDER BY sales DESC;

-- Result: 2360 orders are above average sales


-- ================================================
-- TYPE 2: CORRELATED SUBQUERY IN WHERE CLAUSE
-- Used when you need a different value per row
-- Inner query runs once per row of outer query
-- ================================================

-- Business Question 2:
-- Which orders beat their OWN category average margin?
-- Each category has its own benchmark
-- Technology vs Technology average
-- Furniture vs Furniture average
-- Office Supplies vs Office Supplies average

SELECT order_id,
       customer_name,
       category,
       product_name,
       sales,
       profit,
       ROUND(profit/sales * 100, 2) AS profit_margin_pct
FROM superstore s1
WHERE (profit/sales) > (
    SELECT AVG(profit/sales)
    FROM superstore s2
    WHERE s2.category = s1.category  -- links inner to outer
)
ORDER BY category, profit_margin_pct DESC;

-- Result: 6671 orders perform above their category average
-- s1 = outer superstore table
-- s2 = inner superstore table
-- s2.category = s1.category ensures category-specific comparison


-- ================================================
-- TYPE 3: SUBQUERY IN FROM CLAUSE (DERIVED TABLE)
-- Used when you need to filter on aggregated values
-- Cannot use WHERE SUM(sales) > value directly
-- So calculate totals first in subquery
-- then filter in outer query
-- ================================================

-- Business Question 3:
-- Who are our top 20 customers by revenue
-- and what is their profit margin?

SELECT customer_name,
       total_revenue,
       total_profit,
       ROUND(total_profit / total_revenue * 100, 2) AS margin_pct
FROM (
    -- Inner query: calculate totals per customer
    SELECT customer_name,
           SUM(sales)  AS total_revenue,
           SUM(profit) AS total_profit
    FROM superstore
    GROUP BY customer_name
) AS customer_summary       -- give subquery a name
ORDER BY total_revenue DESC
LIMIT 20;

-- Result: Top 20 customers by revenue with profit margins


-- ================================================
-- BUSINESS INSIGHT 1: TOP CUSTOMER PROFITABILITY
-- High revenue does not always mean high profit
-- ================================================

-- Business Question 4:
-- Is our top revenue customer actually profitable?

SELECT customer_name,
       COUNT(DISTINCT order_id) AS total_orders,
       ROUND(SUM(sales), 2)     AS total_revenue,
       ROUND(SUM(profit), 2)    AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct
FROM superstore
WHERE customer_name = 'Sean Miller'
GROUP BY customer_name;

-- Result: Sean Miller is top revenue customer
-- but has -1980 total profit
-- We are LOSING money on our biggest customer


-- ================================================
-- BUSINESS INSIGHT 2: UNPROFITABLE TOP CUSTOMERS
-- Finding hidden losses among top revenue customers
-- ================================================

-- Business Question 5:
-- Which of our top 20 revenue customers
-- are actually losing us money?

SELECT customer_name,
       COUNT(DISTINCT order_id) AS total_orders,
       ROUND(SUM(sales), 2)     AS total_revenue,
       ROUND(SUM(profit), 2)    AS total_profit,
       ROUND(SUM(profit) / SUM(sales) * 100, 2) AS margin_pct
FROM superstore
GROUP BY customer_name
ORDER BY total_revenue DESC
LIMIT 20;

-- Result: 2 out of top 20 customers are loss-making
-- Sean Miller:  -1980 profit
-- Becky Martin: -1659 profit
-- Combined loss: -3639
-- Recommendation: Review discounting strategy for these customers


-- ================================================
-- BONUS: Products consistently above category average
-- Combining correlated subquery with aggregation
-- ================================================

-- Business Question 6:
-- Which products consistently perform above
-- their category average profit margin?

WITH category_avg AS (
    SELECT category,
           AVG(profit/sales) AS avg_margin
    FROM superstore
    GROUP BY category
)
SELECT s.product_name,
       s.category,
       COUNT(*)                                    AS times_ordered,
       ROUND(AVG(s.profit/s.sales * 100), 2)      AS avg_margin_pct
FROM superstore s
JOIN category_avg c ON s.category = c.category
WHERE (s.profit/s.sales) > c.avg_margin
GROUP BY s.product_name, s.category
ORDER BY times_ordered DESC
LIMIT 20;

-- Result: Staple Envelope ordered 48 times
-- consistently above Office Supplies average
-- Cheap everyday products deliver consistent margins
