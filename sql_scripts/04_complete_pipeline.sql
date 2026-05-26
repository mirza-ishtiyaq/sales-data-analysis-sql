-- ============================================================
--   SALES DATA ANALYSIS — SQL PROJECT
--   Tool    : MySQL Workbench
--   Dataset : customers, orders, transactions
--   Author  : Data Analyst
--   Date    : 2026
-- ============================================================


-- ============================================================
-- SECTION 0 : SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS sales_analysis;
USE sales_analysis;


-- ============================================================
-- SECTION 1 : DATA EXPLORATION
-- ============================================================

-- 1.1 list all tables
SHOW TABLES;

-- 1.2 table structure
DESCRIBE customers;
DESCRIBE orders;
DESCRIBE transactions;

-- 1.3 preview rows
SELECT * FROM customers    LIMIT 5;
SELECT * FROM orders       LIMIT 5;
SELECT * FROM transactions LIMIT 5;

-- 1.4 row counts
SELECT COUNT(*) AS total_rows FROM customers;
SELECT COUNT(*) AS total_rows FROM orders;
SELECT COUNT(*) AS total_rows FROM transactions;


-- ============================================================
-- SECTION 2 : DATA CLEANING
-- ============================================================

-- ── 2.1 Duplicate Check ─────────────────────────────────────

SELECT customer_id, COUNT(*) AS count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- orders — no duplicates found
SELECT order_id, COUNT(*) AS count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- transactions — no duplicates found
SELECT transaction_id, COUNT(*) AS count
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- ── 2.2 Remove Duplicates ───────────────────────────────────
-- Using ROW_NUMBER() to keep first occurrence of each customer

CREATE TABLE customers_cleaned AS
SELECT * FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY customer_id
           ) AS row_num
    FROM customers
) ranked
WHERE row_num = 1;

-- verify
SELECT COUNT(*) AS original_rows FROM customers;
SELECT COUNT(*) AS cleaned_rows  FROM customers_cleaned;


-- ── 2.3 Missing Value Check ─────────────────────────────────

SELECT
    COUNT(*)                                                    AS total_rows,
    SUM(CASE WHEN customer_name   IS NULL THEN 1 ELSE 0 END)   AS missing_name,
    SUM(CASE WHEN email           IS NULL THEN 1 ELSE 0 END)   AS missing_email,
    SUM(CASE WHEN phone_primary   IS NULL THEN 1 ELSE 0 END)   AS missing_phone_primary,
    SUM(CASE WHEN phone_secondary IS NULL THEN 1 ELSE 0 END)   AS missing_phone_secondary,
    SUM(CASE WHEN city            IS NULL THEN 1 ELSE 0 END)   AS missing_city,
    SUM(CASE WHEN country         IS NULL THEN 1 ELSE 0 END)   AS missing_country
FROM customers_cleaned;


-- ── 2.4 Fill Missing Values ─────────────────────────────────
-- Using COALESCE to replace NULLs with meaningful defaults

CREATE TABLE customers_final AS (
    SELECT
        customer_id,
        customer_name,
        COALESCE(email,           'unknown@email.com') AS email,
        COALESCE(phone_primary,   'Not Provided')      AS phone_primary,
        COALESCE(phone_secondary, 'Not Provided')      AS phone_secondary,
        COALESCE(city,            'Unknown')            AS city,
        country,
        created_date,
        purchase_amount
    FROM customers_cleaned
);


-- ── 2.5 Standardise Country Names ───────────────────────────

SELECT DISTINCT country
FROM customers_final
ORDER BY country;

-- disable safe update mode temporarily
SET sql_safe_updates = 0;

UPDATE customers_final
SET country =
    CASE
        WHEN country IN ('US', 'U.S.A.', 'us', 'USA', 'UNITED STATES') THEN 'United States'
        WHEN country IN ('UK', 'Great Britain', 'united kingdom')        THEN 'United Kingdom'
        ELSE country
    END
WHERE country IN (
    'US', 'U.S.A.', 'us', 'USA', 'UNITED STATES',
    'UK', 'Great Britain', 'united kingdom'
);

-- verify
SELECT DISTINCT country FROM customers_final ORDER BY country;


-- ── 2.6 Fix Date Columns in Orders ──────────────────────────

UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%m/%d/%Y'),
    ship_date  = STR_TO_DATE(ship_date,  '%m/%d/%Y');

ALTER TABLE orders
MODIFY COLUMN order_date DATE,
MODIFY COLUMN ship_date  DATE;


-- ── 2.7 Drop Unnecessary Column ─────────────────────────────

ALTER TABLE orders
DROP COLUMN email;


-- ============================================================
-- SECTION 3 : DATA QUALITY FLAGS
-- ============================================================

-- [FINDING] 3 orders have no matching customer_id in customers_final
-- [IMPACT]  INNER JOIN silently drops these rows — understates revenue
-- [FIX]     Use LEFT JOIN in revenue views to retain all orders

CREATE VIEW vw_missing_customer_orders AS
SELECT o.*
FROM orders o
LEFT JOIN customers_final c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT * FROM vw_missing_customer_orders;


-- ============================================================
-- SECTION 4 : ANALYSIS VIEWS
-- ============================================================

-- ── View 1 : Total Revenue ──────────────────────────────────

CREATE VIEW vw_total_revenue AS
SELECT
    ROUND(SUM(o.total_amount),     2) AS total_revenue,
    COUNT(DISTINCT o.order_id)        AS total_orders,
    COUNT(DISTINCT c.customer_id)     AS total_customers
FROM orders o
LEFT JOIN customers_final c
    ON o.customer_id = c.customer_id;

SELECT * FROM vw_total_revenue;


-- ── View 2 : Top Customers ──────────────────────────────────

CREATE VIEW vw_top_customers AS
SELECT
    c.customer_name,
    c.customer_id,
    c.city,
    c.country,
    SUM(o.quantity)               AS total_quantity,
    ROUND(SUM(o.total_amount), 2) AS total_spend
FROM customers_final c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name, c.customer_id, c.city, c.country
ORDER BY total_spend DESC;

SELECT * FROM vw_top_customers LIMIT 5;


-- ── View 3 : Revenue by Country ─────────────────────────────

CREATE VIEW vw_revenue_by_country AS
SELECT
    c.country,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(o.quantity)               AS total_quantity,
    ROUND(SUM(o.total_amount), 2) AS total_revenue
FROM customers_final c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC;

SELECT * FROM vw_revenue_by_country;


-- ── View 4 : Monthly Revenue Trend ──────────────────────────

CREATE VIEW vw_monthly_revenue AS
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id)         AS total_orders,
    COUNT(DISTINCT c.customer_id)      AS unique_customers,
    ROUND(SUM(o.total_amount),  2)     AS total_revenue,
    ROUND(AVG(o.total_amount),  2)     AS avg_order_value
FROM customers_final c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month ASC;

SELECT * FROM vw_monthly_revenue;


-- ── View 5 : Shipping Analysis ──────────────────────────────

CREATE VIEW vw_shipping_analysis AS (
    SELECT
        o.order_id,
        c.customer_name,
        c.city,
        c.country,
        o.order_date,
        o.ship_date,
        DATEDIFF(o.ship_date, o.order_date) AS ship_days,
        CASE
            WHEN DATEDIFF(o.ship_date, o.order_date) < 0  THEN 'Flagged'
            WHEN DATEDIFF(o.ship_date, o.order_date) <= 2 THEN 'Fast'
            WHEN DATEDIFF(o.ship_date, o.order_date) <= 3 THEN 'Normal'
            ELSE 'Slow'
        END AS shipping_status
    FROM customers_final c
    INNER JOIN orders o ON c.customer_id = o.customer_id
);

SELECT * FROM vw_shipping_analysis;


-- ── View 6 : Project Summary ─────────────────────────────────

CREATE VIEW vw_project_summary AS

SELECT 'Total Revenue' AS metric,
        CAST(ROUND(SUM(total_amount), 2) AS CHAR) AS value
FROM orders

UNION ALL

SELECT 'Total Orders',
        CAST(COUNT(DISTINCT order_id) AS CHAR)
FROM orders

UNION ALL

SELECT 'Total Customers',
        CAST(COUNT(DISTINCT customer_id) AS CHAR)
FROM customers_final

UNION ALL

SELECT 'Average Order Value',
        CAST(ROUND(AVG(total_amount), 2) AS CHAR)
FROM orders

UNION ALL

SELECT 'Top Country', country
FROM (
    SELECT c.country
    FROM customers_final c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.country
    ORDER BY SUM(o.total_amount) DESC
    LIMIT 1
) AS top_country

UNION ALL

SELECT 'Top Customer', customer_name
FROM (
    SELECT c.customer_name
    FROM customers_final c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_name
    ORDER BY SUM(o.total_amount) DESC
    LIMIT 1
) AS top_customer;

SELECT * FROM vw_project_summary;


-- ============================================================
-- SECTION 5 : FINAL REPORT
-- ============================================================

SELECT '── PROJECT SUMMARY ──'      AS '';
SELECT * FROM vw_project_summary;

SELECT '── REVENUE BY COUNTRY ──'   AS '';
SELECT * FROM vw_revenue_by_country;

SELECT '── TOP 5 CUSTOMERS ──'      AS '';
SELECT * FROM vw_top_customers LIMIT 5;

SELECT '── MONTHLY REVENUE ──'      AS '';
SELECT * FROM vw_monthly_revenue;

SELECT '── SHIPPING SUMMARY ──'     AS '';
SELECT
    shipping_status,
    COUNT(*)                    AS total_orders,
    ROUND(AVG(ship_days), 1)    AS avg_days
FROM vw_shipping_analysis
GROUP BY shipping_status
ORDER BY total_orders DESC;

-- ============================================================
-- END OF PROJECT
-- ============================================================
