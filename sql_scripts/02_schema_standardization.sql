-- ============================================================
-- SECTION 2: SCHEMA STANDARDIZATION
-- ============================================================

USE sales_analysis;

-- ── Standardize Inconsistent Country Strings ────────────────
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

-- ── Normalizing Date Formats and Structural Casting ────────
UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%m/%d/%Y'),
    ship_date  = STR_TO_DATE(ship_date,  '%m/%d/%Y');

ALTER TABLE orders
MODIFY COLUMN order_date DATE,
MODIFY COLUMN ship_date  DATE;

ALTER TABLE orders DROP COLUMN email;
