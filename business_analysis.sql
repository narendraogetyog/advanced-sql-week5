-- ============================================================
-- Week 5: Business Dataset Analysis & KPI Identification
-- Analyst: Narendra Ogety | Hashclick Solutions LLC
-- Date: June 2026
-- Description: Business-driven SQL analysis on Sales/Customers/Revenue
-- ============================================================

-- ============================================================
-- SECTION 1: REVENUE ANALYSIS
-- ============================================================

-- KPI 1: Total Revenue by Month and Year
SELECT
  YEAR(order_date) AS year,
  MONTH(order_date) AS month,
  SUM(order_amount) AS total_revenue,
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  ROUND(SUM(order_amount) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM orders
WHERE order_status = 'COMPLETED'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year, month;

-- KPI 2: Revenue Growth Rate (Month-over-Month)
WITH monthly_rev AS (
  SELECT
    DATE_TRUNC('month', order_date) AS month,
    SUM(order_amount) AS revenue
  FROM orders
  WHERE order_status = 'COMPLETED'
  GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
  month,
  revenue,
  LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
  ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2) AS growth_pct
FROM monthly_rev
ORDER BY month;

-- ============================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- ============================================================

-- KPI 3: Customer Lifetime Value (CLV) Calculation
WITH clv_calc AS (
  SELECT
    customer_id,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(order_amount) AS total_revenue,
    AVG(order_amount) AS avg_order_value,
    MIN(order_date) AS first_purchase,
    MAX(order_date) AS last_purchase,
    DATEDIFF('day', MIN(order_date), MAX(order_date)) AS customer_tenure_days
  FROM orders
  WHERE order_status = 'COMPLETED'
  GROUP BY customer_id
)
SELECT
  c.customer_id,
  c.customer_name,
  c.region,
  clv.total_orders,
  ROUND(clv.total_revenue, 2) AS lifetime_value,
  ROUND(clv.avg_order_value, 2) AS avg_order_value,
  clv.customer_tenure_days,
  CASE
    WHEN clv.total_revenue >= 10000 THEN 'High Value'
    WHEN clv.total_revenue >= 5000 THEN 'Medium Value'
    WHEN clv.total_revenue >= 1000 THEN 'Low Value'
    ELSE 'At Risk'
  END AS customer_segment
FROM clv_calc clv
JOIN customers c ON clv.customer_id = c.customer_id
ORDER BY lifetime_value DESC;

-- KPI 4: Customer Acquisition Rate by Month
SELECT
  DATE_TRUNC('month', first_order_date) AS acquisition_month,
  COUNT(*) AS new_customers
FROM (
  SELECT customer_id, MIN(order_date) AS first_order_date
  FROM orders
  GROUP BY customer_id
) first_orders
GROUP BY DATE_TRUNC('month', first_order_date)
ORDER BY acquisition_month;

-- KPI 5: Customer Churn Analysis (inactive 60+ days)
WITH last_orders AS (
  SELECT
    customer_id,
    MAX(order_date) AS last_order_date,
    DATEDIFF('day', MAX(order_date), CURRENT_DATE) AS days_since_last_order
  FROM orders
  GROUP BY customer_id
)
SELECT
  c.customer_id,
  c.customer_name,
  c.region,
  lo.last_order_date,
  lo.days_since_last_order,
  CASE
    WHEN lo.days_since_last_order > 90 THEN 'High Churn Risk'
    WHEN lo.days_since_last_order > 60 THEN 'Medium Churn Risk'
    WHEN lo.days_since_last_order > 30 THEN 'Low Churn Risk'
    ELSE 'Active'
  END AS churn_status
FROM last_orders lo
JOIN customers c ON lo.customer_id = c.customer_id
ORDER BY lo.days_since_last_order DESC;

-- ============================================================
-- SECTION 3: PRODUCT PERFORMANCE ANALYSIS
-- ============================================================

-- KPI 6: Top 10 Products by Revenue
WITH product_rev AS (
  SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    COUNT(DISTINCT oi.order_id) AS order_count,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
  FROM products p
  JOIN order_items oi ON p.product_id = oi.product_id
  JOIN orders o ON oi.order_id = o.order_id
  WHERE o.order_status = 'COMPLETED'
  GROUP BY p.product_id, p.product_name, p.category, p.unit_price
)
SELECT
  revenue_rank,
  product_name,
  category,
  total_units_sold,
  ROUND(total_revenue, 2) AS total_revenue,
  order_count,
  ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 2) AS revenue_share_pct
FROM product_rev
WHERE revenue_rank <= 10
ORDER BY revenue_rank;

-- KPI 7: Category Performance Summary
SELECT
  p.category,
  COUNT(DISTINCT p.product_id) AS product_count,
  SUM(oi.quantity) AS total_units_sold,
  ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue,
  ROUND(AVG(oi.unit_price), 2) AS avg_price,
  ROUND(SUM(oi.quantity * oi.unit_price) / SUM(SUM(oi.quantity * oi.unit_price)) OVER () * 100, 2) AS revenue_share_pct
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'COMPLETED'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- ============================================================
-- SECTION 4: REGIONAL & GEOGRAPHIC ANALYSIS
-- ============================================================

-- KPI 8: Revenue by Region with Quarterly Breakdown
SELECT
  c.region,
  YEAR(o.order_date) AS year,
  QUARTER(o.order_date) AS quarter,
  ROUND(SUM(o.order_amount), 2) AS quarterly_revenue,
  COUNT(DISTINCT o.order_id) AS order_count,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  ROUND(SUM(o.order_amount) / COUNT(DISTINCT o.customer_id), 2) AS revenue_per_customer
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'COMPLETED'
GROUP BY c.region, YEAR(o.order_date), QUARTER(o.order_date)
ORDER BY c.region, year, quarter;

-- ============================================================
-- SECTION 5: MARKETING ROI ANALYSIS
-- ============================================================

-- KPI 9: Marketing ROI by Channel
SELECT
  marketing_channel,
  SUM(marketing_spend) AS total_spend,
  SUM(attributed_revenue) AS total_revenue,
  ROUND(SUM(attributed_revenue) / NULLIF(SUM(marketing_spend), 0), 2) AS roi_ratio,
  ROUND((SUM(attributed_revenue) - SUM(marketing_spend)) / NULLIF(SUM(marketing_spend), 0) * 100, 2) AS roi_pct,
  COUNT(DISTINCT customer_id) AS customers_acquired
FROM marketing_campaigns
GROUP BY marketing_channel
ORDER BY roi_ratio DESC;

-- KPI 10: Overall Business Health Dashboard Query
WITH business_kpis AS (
  SELECT
    ROUND(SUM(order_amount), 0) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(AVG(order_amount), 2) AS avg_order_value,
    ROUND(SUM(order_amount) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
  FROM orders
  WHERE order_status = 'COMPLETED'
    AND order_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '12 months')
)
SELECT
  'Total Revenue (12M)' AS kpi_name, CAST(total_revenue AS VARCHAR) AS kpi_value FROM business_kpis
UNION ALL
SELECT 'Total Orders (12M)', CAST(total_orders AS VARCHAR) FROM business_kpis
UNION ALL
SELECT 'Total Customers (12M)', CAST(total_customers AS VARCHAR) FROM business_kpis
UNION ALL
SELECT 'Avg Order Value', CAST(avg_order_value AS VARCHAR) FROM business_kpis
UNION ALL
SELECT 'Revenue per Customer', CAST(revenue_per_customer AS VARCHAR) FROM business_kpis;
