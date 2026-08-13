-- ================================================
-- Week 2 | Day 6 | Topic: Set Operations
-- Dataset: Northwind
-- ================================================

-- ================================================
-- SECTION 1: UNION
-- Combines results removing duplicates
-- ================================================

-- Business Question 1:
-- All cities where we have customers OR suppliers
SELECT city,
       country,
       'Customer' AS source
FROM customers

UNION

SELECT city,
       country,
       'Supplier' AS source
FROM suppliers

ORDER BY country, city;
-- Result: 98 unique city-source combinations


-- ================================================
-- SECTION 2: INTERSECT
-- Returns rows that exist in BOTH queries
-- ================================================

-- Business Question 2:
-- Cities that have BOTH customers AND suppliers
-- Strategic locations for Northwind
SELECT city, country
FROM customers

INTERSECT

SELECT city, country
FROM suppliers

ORDER BY country, city;
-- Result: 5 cities
-- Sao Paulo (Brazil), Montreal (Canada)
-- Paris (France), Berlin (Germany), London (UK)


-- ================================================
-- SECTION 3: EXCEPT
-- Returns rows in first query NOT in second
-- ================================================

-- Business Question 3:
-- Cities with customers but NO suppliers
-- Potential locations to expand supplier network
SELECT city, country
FROM customers

EXCEPT

SELECT city, country
FROM suppliers

ORDER BY country, city;
-- Result: 64 cities have customers but no suppliers
-- Opportunity to expand supplier network


-- ================================================
-- SECTION 4: UNION ALL
-- Combines results keeping ALL rows including duplicates
-- Faster than UNION -- use when duplicates are ok
-- ================================================

-- Business Question 4:
-- Compare orders from two different years
SELECT
    order_date,
    COUNT(*) AS order_count,
    '1996' AS year
FROM orders
WHERE order_date BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY order_date

UNION ALL

SELECT
    order_date,
    COUNT(*) AS order_count,
    '1997' AS year
FROM orders
WHERE order_date BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY order_date

ORDER BY order_date;
-- UNION ALL keeps all rows from both years
-- Useful for combining same structure data from different periods