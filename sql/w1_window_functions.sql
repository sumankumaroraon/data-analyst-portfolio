-- ================================================
-- Topic: Window Functions
-- Dataset: Superstore (9994 rows)
-- ================================================


-- ================================================
-- SECTION 1: RANKING FUNCTIONS
-- ROW_NUMBER, RANK, DENSE_RANK
-- ================================================

-- ROW_NUMBER: Unique number per row within partition
-- Business Question: Number each order within category by sales
SELECT order_id,
       customer_name,
       category,
       ROUND(sales, 2) AS sales,
       ROW_NUMBER() OVER (
           PARTITION BY category
           ORDER BY sales DESC
       ) AS row_num
FROM superstore
ORDER BY category, row_num;

-- Compare all three ranking functions side by side
-- Shows difference when there are tied values
SELECT customer_name,
       category,
       ROUND(sales, 2) AS sales,
       ROW_NUMBER() OVER (
           PARTITION BY category
           ORDER BY sales DESC
       ) AS row_number,
       RANK() OVER (
           PARTITION BY category
           ORDER BY sales DESC
       ) AS rank,
       DENSE_RANK() OVER (
           PARTITION BY category
           ORDER BY sales DESC
       ) AS dense_rank
FROM superstore
WHERE category = 'Furniture'
ORDER BY sales DESC
LIMIT 20;

-- Top 3 products per category by total sales
-- Cannot filter on window function in WHERE directly
-- Must use CTE first then filter
WITH ranked_products AS (
    SELECT category,
           product_name,
           ROUND(SUM(sales), 2) AS total_sales,
           RANK() OVER (
               PARTITION BY category
               ORDER BY SUM(sales) DESC
           ) AS sales_rank
    FROM superstore
    GROUP BY category, product_name
)
SELECT category,
       product_name,
       total_sales,
       sales_rank
FROM ranked_products
WHERE sales_rank <= 3
ORDER BY category, sales_rank;

-- Result:
-- Technology: Canon imageCLASS, Cisco, Hewlett
-- Furniture: HON 5400, Riverside Palais, Bretford Rectangular
-- Office Supplies: Fellowes, GBC, GBC (tied)


-- ================================================
-- SECTION 2: OFFSET FUNCTIONS
-- LAG, LEAD
-- ================================================

-- LAG: Access previous row value
-- Business Question: Month over month revenue growth
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        ROUND(SUM(sales), 2)            AS monthly_revenue
    FROM superstore
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY month
    ) AS prev_month_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
        / LAG(monthly_revenue) OVER (ORDER BY month) * 100
    , 2) AS growth_pct
FROM monthly_sales
ORDER BY month;

-- Result: March had highest growth
-- Multiple months had negative growth throughout 3 years
-- Normal retail cyclical pattern


-- ================================================
-- SECTION 3: AGGREGATE WINDOW FUNCTIONS
-- Running totals, moving averages
-- ================================================

-- Running total of revenue by month
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- means from first row to current row
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        ROUND(SUM(sales), 2)            AS monthly_revenue
    FROM superstore
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;

-- Result: End of 2014 cumulative: 484,247
-- Total all years: 2,297,201

-- 3-month moving average
-- Smooths out monthly peaks and valleys
-- Shows underlying trend
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        ROUND(SUM(sales), 2)            AS monthly_revenue
    FROM superstore
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    monthly_revenue,
    ROUND(AVG(monthly_revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3month
FROM monthly_sales
ORDER BY month;

-- Result: Moving average much smoother than raw monthly
-- Last month moving average: 93,351


-- ================================================
-- SECTION 4: DISTRIBUTION FUNCTIONS
-- NTILE
-- ================================================

-- Divide customers into 4 spending quartiles
-- NTILE(4) creates 4 equal groups
WITH customer_spending AS (
    SELECT
        customer_name,
        segment,
        ROUND(SUM(sales), 2) AS total_spending
    FROM superstore
    GROUP BY customer_name, segment
),
customer_quartiles AS (
    SELECT
        customer_name,
        segment,
        total_spending,
        NTILE(4) OVER (
            ORDER BY total_spending DESC
        ) AS spending_quartile
    FROM customer_spending
)
SELECT
    spending_quartile,
    CASE spending_quartile
        WHEN 1 THEN 'Top 25% -- High Value'
        WHEN 2 THEN 'Upper Middle 25%'
        WHEN 3 THEN 'Lower Middle 25%'
        WHEN 4 THEN 'Bottom 25% -- Low Value'
    END                           AS customer_tier,
    COUNT(*)                      AS customer_count,
    ROUND(AVG(total_spending), 2) AS avg_spending,
    ROUND(MIN(total_spending), 2) AS min_spending,
    ROUND(MAX(total_spending), 2) AS max_spending
FROM customer_quartiles
GROUP BY spending_quartile
ORDER BY spending_quartile;

-- Result: Top 25% avg spending: 6,364
-- Bottom 25% avg spending: 633
-- Top customers spend 10x more than bottom customers
-- Foundation of customer segmentation strategy