-- ============================================================
-- SECTION 1: ENVIRONMENT SETUP & DATA CLEANING
-- ============================================================

CREATE DATABASE IF NOT EXISTS sales_analysis;
USE sales_analysis;

-- ── Remove Duplicates Using Window Functions ────────────────
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

-- ── Handle Missing Values via Imputation ────────────────────
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
