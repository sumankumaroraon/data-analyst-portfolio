-- ================================================
-- Topic: Query Optimization
-- Dataset: Superstore + large_orders (500K rows)

-- ================================================


-- ================================================
-- SECTION 1: EXPLAIN AND EXPLAIN ANALYZE
-- ================================================

-- EXPLAIN: shows plan without running query
EXPLAIN
SELECT *
FROM superstore
WHERE category = 'Technology';

-- EXPLAIN ANALYZE: runs query and shows actual time
EXPLAIN ANALYZE
SELECT *
FROM superstore
WHERE category = 'Technology';


-- ================================================
-- SECTION 2: INDEX DEMONSTRATION
-- ================================================

-- Without index on large table (500K rows)
-- Seq Scan reads ALL rows -- very slow
EXPLAIN ANALYZE
SELECT *
FROM large_orders
WHERE category = 'Technology';
-- Result: Seq Scan, 416321 rows wasted, 58.617 ms

-- Create single column index
CREATE INDEX idx_large_category
ON large_orders(category);

-- With index -- much faster
EXPLAIN ANALYZE
SELECT *
FROM large_orders
WHERE category = 'Technology';
-- Result: Bitmap Index Scan, 26.246 ms
-- Improvement: 55% faster

-- Drop index for cleanup
DROP INDEX idx_large_category;


-- ================================================
-- SECTION 3: COMPOSITE INDEX
-- ================================================

-- Create composite index on two columns
-- Column order matters -- first column must be in WHERE
CREATE INDEX idx_category_region
ON superstore(category, region);

-- Query using both indexed columns
-- Much faster than single column index
EXPLAIN ANALYZE
SELECT *
FROM superstore
WHERE category = 'Technology'
AND region = 'West';
-- Result: Bitmap Index Scan on idx_category_region
-- Execution Time: 1.176 ms
-- 3x faster than single column index


-- ================================================
-- SECTION 4: QUERY WRITING BEST PRACTICES
-- ================================================

-- Best Practice 1: SELECT specific columns not *
-- SLOW version
EXPLAIN ANALYZE
SELECT *
FROM superstore
WHERE category = 'Technology';

-- FAST version
EXPLAIN ANALYZE
SELECT order_id, customer_name, sales, profit
FROM superstore
WHERE category = 'Technology';

-- Best Practice 2: Avoid functions on indexed columns
-- SLOW: function prevents index use
EXPLAIN ANALYZE
SELECT *
FROM superstore
WHERE UPPER(category) = 'TECHNOLOGY';

-- FAST: no function -- index can be used
EXPLAIN ANALYZE
SELECT *
FROM superstore
WHERE category = 'Technology';

-- Best Practice 3: Filter early before joining
-- SLOW: join all then filter
EXPLAIN ANALYZE
SELECT s.order_id, s.customer_name, s.sales
FROM superstore s
JOIN large_orders l ON s.order_id = l.order_id
WHERE s.category = 'Technology';

-- FAST: filter first then join
EXPLAIN ANALYZE
SELECT s.order_id, s.customer_name, s.sales
FROM (
    SELECT order_id, customer_name, sales
    FROM superstore
    WHERE category = 'Technology'
) s
JOIN large_orders l ON s.order_id = l.order_id;


-- ================================================
-- SECTION 5: INDEX MANAGEMENT
-- ================================================

-- View all indexes on superstore table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'superstore';

-- Drop an index when no longer needed
-- DROP INDEX idx_category_region;

-- When TO create an index:
-- 1. Column frequently used in WHERE clause
-- 2. Column used in JOIN conditions
-- 3. Column used in ORDER BY on large tables
-- 4. Table has millions of rows

-- When NOT to create an index:
-- 1. Small tables (under 10K rows)
-- 2. Columns with very few unique values
-- 3. Columns that change very frequently
-- 4. Too many indexes on same table


-