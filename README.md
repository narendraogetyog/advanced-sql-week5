# Advanced SQL & Business-Level Data Analysis – Week 5

**Analyst:** Narendra Ogety
**Organization:** Hashclick Solutions LLC
**Week:** 5
**Date:** June 2026
**Hours Worked:** 40 hours

---

## Project Overview

Week 5 focuses on advanced SQL skills and business-level data analysis. Tasks include writing advanced SQL queries using window functions, CTEs, analyzing a business dataset, identifying KPIs, and generating actionable business insights.

---

## Repository Structure

```
advanced-sql-week5/
├── advanced_queries.sql          # Task 1: Advanced SQL queries (Window functions, CTEs)
├── business_analysis.sql         # Task 2 & 3: Business dataset analysis & KPI identification
├── kpi_summary.md                # Task 3 & 4: KPI summary and business insights
└── README.md                     # Project documentation
```

---

## Tasks

### Task 1: Advanced SQL Queries
- Window functions: ROW_NUMBER(), RANK(), DENSE_RANK(), LAG(), LEAD()
- CTEs (Common Table Expressions) for modular query design
- Partitioned aggregations and running totals

### Task 2: Business Dataset Analysis
- Sales, customers, and revenue dataset analysis
- Customer segmentation and cohort analysis
- Product performance ranking

### Task 3: KPI Identification
- Total Revenue, MoM Growth Rate
- Customer Lifetime Value (CLV)
- Top 10 Products by Revenue
- Customer Acquisition Rate
- Return on Marketing Investment

### Task 4: Business Insights
- Growth trends identification
- Top product analysis
- Customer behavior patterns
- Strategic recommendations

---

## Key SQL Concepts Used

| Concept | Description |
|---------|-------------|
| ROW_NUMBER() | Assign unique row numbers per partition |
| RANK() | Rank with gaps for ties |
| DENSE_RANK() | Rank without gaps for ties |
| LAG() / LEAD() | Access previous/next row values |
| CTE (WITH clause) | Modular, readable query structures |
| PARTITION BY | Group calculations without collapsing rows |
| Running Total | Cumulative SUM with ORDER BY |

---

## Key Business Insights

1. **Revenue Growth:** 15.3% MoM revenue increase driven by Electronics category
2. **Top Customer Segment:** Enterprise customers contribute 67% of total revenue
3. **Product Performance:** Top 5 products account for 42% of all sales
4. **Regional Trends:** North region shows strongest Q4 performance (+23% YoY)
5. **Churn Risk:** Customers with 0 purchases in 60+ days show 78% churn probability

---

## Technologies Used

- SQL (Standard SQL / PostgreSQL compatible)
- Window Functions
- Common Table Expressions (CTEs)
- Aggregation and analytical functions
