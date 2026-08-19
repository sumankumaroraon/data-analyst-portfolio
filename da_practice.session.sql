-- When did each customer first order?
SELECT customer_id,
       MIN(order_date) AS first_order_date,
       DATE_TRUNC('month', MIN(order_date)) AS cohort_month
FROM orders
GROUP BY customer_id
ORDER BY cohort_month;


-- For each order calculate how many months
-- since that customer's first order

WITH first_order AS(
    SELECT customer_id,
       MIN(order_date) AS first_order_date,
       DATE_TRUNC('month', MIN(order_date)) AS cohort_month
FROM orders
GROUP BY customer_id
)
SELECT o.customer_id,
       f.cohort_month,
       DATE_TRUNC('month', o.order_date) AS order_month,
       EXTRACT( YEAR FROM AGE(
        DATE_TRUNC('month', o.order_date),
        f.cohort_month)) *12 + 
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.order_date),
            f.cohort_month
        )) AS months_since_first
FROM orders o
JOIN first_order f ON o.customer_id = f.customer_id
ORDER BY f.cohort_month, o.customer_id, months_since_first;



WITH first_order AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
cohort_data AS (
    SELECT o.customer_id,
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
WHERE cohort_month = '1996-07-01'
GROUP BY cohort_month, month_since_first
ORDER BY month_since_first;

            