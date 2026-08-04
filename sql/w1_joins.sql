-- ================================================
--Topic: JOINs Deep Dive
-- Dataset: Northwind (customers, orders, products etc)
-- ================================================


-- ================================================
-- SETUP: Understanding Northwind tables
-- ================================================

-- Row counts for all tables
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'order_details', COUNT(*) FROM order_details
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'shippers', COUNT(*) FROM shippers
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers;

-- customers: 91, orders: 830, order_details: 2155
-- products: 77, employees: 9, categories: 8
-- shippers: 6, suppliers: 29


-- ================================================
-- SECTION 1: INNER JOIN
-- Returns only rows matching in BOTH tables
-- ================================================

-- Business Question 1:
-- Which customers placed orders and when?
-- INNER JOIN excludes customers with no orders
SELECT c.customer_id,
       c.company_name,
       c.country,
       o.order_id,
       o.order_date,
       o.freight
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;
-- Result: 830 rows -- all orders with customer info

-- Which country has most orders?
SELECT c.country,
       COUNT(o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country
ORDER BY total_orders DESC;
-- Result: Germany and USA tied at 122, Brazil 83


-- ================================================
-- SECTION 2: LEFT JOIN
-- Returns ALL rows from left table
-- NULL where no match in right table
-- ================================================

-- Business Question 2:
-- Which customers have NEVER placed an order?
-- LEFT JOIN keeps all customers
-- NULL in order columns = no orders placed
-- This pattern is called an ANTI-JOIN
SELECT c.customer_id,
       c.company_name,
       c.country,
       o.order_id,
       o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.company_name;
-- Result: 2 customers never ordered
-- FISSA Fabrica Inter. Salchichas S.A. (Spain)
-- Paris specialites (France)
-- 98% customer activation rate


-- ================================================
-- SECTION 3: FULL OUTER JOIN
-- Returns ALL rows from BOTH tables
-- NULL where no match on either side
-- ================================================

-- Business Question 3:
-- Show all customers and all orders
-- Including unmatched on both sides
SELECT c.customer_id,
       c.company_name,
       o.order_id,
       o.order_date
FROM customers c
FULL OUTER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.company_name;
-- Result: 832 rows
-- 830 matched + 2 unmatched customers (FISSA and PARIS)


-- ================================================
-- SECTION 4: SELF JOIN
-- Table joined to itself
-- Used for hierarchical relationships
-- ================================================

-- Business Question 4:
-- Who reports to whom in the employee hierarchy?
-- e1 = the employee
-- e2 = the manager (also in employees table)
SELECT e1.employee_id,
       e1.first_name || ' ' || e1.last_name AS employee_name,
       e1.title AS employee_title,
       e2.first_name || ' ' || e2.last_name AS manager_name,
       e2.title AS manager_title
FROM employees e1
LEFT JOIN employees e2 ON e1.reports_to = e2.employee_id
ORDER BY e2.last_name, e1.last_name;
-- Result: Andrew Fuller is VP with no manager (CEO)
-- 5 employees report directly to Andrew Fuller


-- ================================================
-- SECTION 5: CROSS JOIN
-- Every row from table A combined with every row from B
-- Use for generating all possible combinations
-- ================================================

-- Business Question 5:
-- All possible category and shipper combinations
-- 8 categories x 6 shippers = 48 combinations
SELECT c.category_name,
       s.company_name AS shipper_name
FROM categories c
CROSS JOIN shippers s
ORDER BY c.category_name, s.company_name;
-- Result: 48 rows (8 x 6 = 48)


-- ================================================
-- SECTION 6: MULTI-TABLE JOIN (5 tables)
-- Joining multiple tables to get complete picture
-- ================================================

-- Business Question 6:
-- Complete order details with customer, employee,
-- product, category and revenue
SELECT c.company_name AS customer,
       e.first_name || ' ' || e.last_name AS employee,
       o.order_id,
       o.order_date,
       p.product_name,
       cat.category_name,
       od.quantity,
       od.unit_price,
       ROUND((od.unit_price * od.quantity *
           (1 - od.discount))::numeric, 2) AS total_amount
FROM orders o
JOIN customers c   ON o.customer_id  = c.customer_id
JOIN employees e   ON o.employee_id  = e.employee_id
JOIN order_details od ON o.order_id  = od.order_id
JOIN products p    ON od.product_id  = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
ORDER BY o.order_date DESC;
-- Result: 2155 rows
-- Beverages is highest revenue category


-- ================================================
-- SECTION 7: ADVANCED -- CTEs + JOINs + Window Functions
-- Production level query combining everything
-- ================================================

-- Business Question 7:
-- Top 5 customers by revenue with favorite category
-- Combines: 5 table JOINs, 2 CTEs, RANK window function
WITH customer_revenue AS (
    SELECT c.customer_id,
           c.company_name,
           c.country,
           ROUND(SUM(od.unit_price * od.quantity *
               (1 - od.discount))::numeric, 2) AS total_revenue
    FROM customers c
    JOIN orders o      ON c.customer_id  = o.customer_id
    JOIN order_details od ON o.order_id  = od.order_id
    GROUP BY c.customer_id, c.company_name, c.country
),
customer_top_category AS (
    SELECT c.customer_id,
           cat.category_name,
           RANK() OVER (
               PARTITION BY c.customer_id
               ORDER BY SUM(od.quantity) DESC
           ) AS category_rank
    FROM customers c
    JOIN orders o         ON c.customer_id  = o.customer_id
    JOIN order_details od ON o.order_id     = od.order_id
    JOIN products p       ON od.product_id  = p.product_id
    JOIN categories cat   ON p.category_id  = cat.category_id
    GROUP BY c.customer_id, cat.category_name
)
SELECT cr.company_name,
       cr.country,
       cr.total_revenue,
       ctc.category_name AS favorite_category
FROM customer_revenue cr
JOIN customer_top_category ctc ON cr.customer_id = ctc.customer_id
WHERE ctc.category_rank = 1
ORDER BY cr.total_revenue DESC
LIMIT 5;
-- Result:
-- QUICK-Stop (Germany) 110,277 - Beverages
-- Ernst Handel (Austria) 104,874 - Dairy Products
-- Save-a-lot Markets (USA) 104,361 - Seafood
-- Rattlesnake Canyon Grocery (USA) 51,097 - Dairy Products
-- Hungry Owl All-Night Grocers (Ireland) 49,979 - Seafood