-- ============================================================
-- SECTION 3: ANALYTICAL REPORTING VIEWS (BI LAYER)
-- ============================================================

USE sales_analysis;

-- ── Quality Flag: Defensive Handling for Orphaned Records ──
CREATE VIEW vw_missing_customer_orders AS
SELECT o.*
FROM orders o
LEFT JOIN customers_final c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- ── View: Global Market Share Metrics ──────────────────────
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

-- ── View: Monthly Revenue & Trend Analysis ─────────────────
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

-- ── View: Logistics and Fulfillment Speed Audit ────────────
CREATE VIEW vw_shipping_analysis AS (
    SELECT
        o.order_id,
        c.customer_name,
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
