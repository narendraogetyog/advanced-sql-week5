-- ============================================================
-- Week 5: Advanced SQL Queries
-- Analyst: Narendra Ogety | Hashclick Solutions LLC
-- Date: June 2026
-- Description: Advanced SQL queries using Window Functions & CTEs
-- ============================================================

-- ============================================================
-- SECTION 1: ROW_NUMBER() - Assign unique sequential row numbers
-- ============================================================

-- Query 1: Rank customers by total purchase amount within each region
SELECT
  customer_id,
  customer_name,
  region,
  total_purchase,
  ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_purchase DESC) AS rank_in_region
FROM customers
ORDER BY region, rank_in_region;

-- Query 2: Identify the most recent order per customer
SELECT *
FROM (
  SELECT
    customer_id,
    order_id,
    order_date,
    order_amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rn
  FROM orders
) ranked
WHERE rn = 1;

-- ============================================================
-- SECTION 2: RANK() and DENSE_RANK() - Product Performance
-- ============================================================

-- Query 3: Rank products by sales with gap handling (RANK)
SELECT
  product_id,
  product_name,
  category,
  total_sales,
  RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank,
  DENSE_RANK() OVER (PARTITION BY category ORDER BY total_sales DESC) AS dense_sales_rank
FROM products
ORDER BY category, sales_rank;

-- Query 4: Top 3 revenue-generating products per category
SELECT *
FROM (
  SELECT
    product_name,
    category,
    revenue,
    DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS dr
  FROM product_sales
) ranked
WHERE dr <= 3
ORDER BY category, dr;

-- ============================================================
-- SECTION 3: LAG() and LEAD() - Time Series Analysis
-- ============================================================

-- Query 5: Month-over-Month revenue change
SELECT
  month,
  year,
  monthly_revenue,
  LAG(monthly_revenue, 1) OVER (ORDER BY year, month) AS prev_month_revenue,
  ROUND(
    (monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY year, month))
    / NULLIF(LAG(monthly_revenue, 1) OVER (ORDER BY year, month), 0) * 100, 2
  ) AS mom_growth_pct
FROM monthly_revenue_summary
ORDER BY year, month;

-- Query 6: Identify customers who upgraded their purchase value
SELECT
  customer_id,
  order_date,
  order_amount,
  LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_amount,
  LEAD(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_amount,
  CASE
    WHEN order_amount > LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date)
    THEN 'UPGRADE'
    WHEN order_amount < LAG(order_amount) OVER (PARTITION BY customer_id ORDER BY order_date)
    THEN 'DOWNGRADE'
    ELSE 'SAME'
  END AS purchase_trend
FROM orders
ORDER BY customer_id, order_date;

-- ============================================================
-- SECTION 4: Running Totals and Cumulative Analysis
-- ============================================================

-- Query 7: Running total of revenue by date
SELECT
  order_date,
  daily_revenue,
  SUM(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_revenue,
  AVG(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_avg
FROM daily_revenue_summary
ORDER BY order_date;

-- Query 8: Cumulative market share per product category
SELECT
  category,
  revenue,
  SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
  ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER () * 100, 2) AS cumulative_pct
FROM category_revenue
ORDER BY revenue DESC;

-- ============================================================
-- SECTION 5: CTEs (Common Table Expressions)
-- ============================================================

-- Query 9: CTE for Customer Segmentation
WITH customer_segments AS (
  SELECT
    customer_id,
    customer_name,
    SUM(order_amount) AS lifetime_value,
    COUNT(order_id) AS total_orders,
    AVG(order_amount) AS avg_order_value,
    MAX(order_date) AS last_order_date
  FROM orders
  GROUP BY customer_id, customer_name
),
customer_tier AS (
  SELECT
    *,
    CASE
      WHEN lifetime_value >= 10000 THEN 'Platinum'
      WHEN lifetime_value >= 5000 THEN 'Gold'
      WHEN lifetime_value >= 1000 THEN 'Silver'
      ELSE 'Bronze'
    END AS tier
  FROM customer_segments
)
SELECT
  tier,
  COUNT(*) AS customer_count,
  ROUND(AVG(lifetime_value), 2) AS avg_ltv,
  ROUND(AVG(avg_order_value), 2) AS avg_order_val,
  SUM(lifetime_value) AS total_revenue
FROM customer_tier
GROUP BY tier
ORDER BY total_revenue DESC;

-- Query 10: CTE for Top Products Analysis
WITH product_performance AS (
  SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    SUM(oi.quantity) AS total_units_sold,
    COUNT(DISTINCT oi.order_id) AS order_count,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
  FROM products p
  JOIN order_items oi ON p.product_id = oi.product_id
  GROUP BY p.product_id, p.product_name, p.category
),
top_10_products AS (
  SELECT * FROM product_performance WHERE revenue_rank <= 10
)
SELECT
  product_name,
  category,
  total_revenue,
  total_units_sold,
  order_count,
  revenue_rank,
  ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 2) AS revenue_share_pct
FROM top_10_products
ORDER BY revenue_rank;

-- Query 11: CTE for Cohort Analysis (Customer Retention)
WITH first_purchase AS (
  SELECT
    customer_id,
    MIN(order_date) AS first_order_date,
    DATE_TRUNC('month', MIN(order_date)) AS cohort_month
  FROM orders
  GROUP BY customer_id
),
cohort_data AS (
  SELECT
    f.customer_id,
    f.cohort_month,
    DATE_TRUNC('month', o.order_date) AS order_month,
    DATEDIFF('month', f.cohort_month, DATE_TRUNC('month', o.order_date)) AS months_since_first_purchase
  FROM first_purchase f
  JOIN orders o ON f.customer_id = o.customer_id
)
SELECT
  cohort_month,
  months_since_first_purchase,
  COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_data
GROUP BY cohort_month, months_since_first_purchase
ORDER BY cohort_month, months_since_first_purchase;
