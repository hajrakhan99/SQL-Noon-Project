# 📦 SQL Analytics Project — `orderss` Database

> Customer & Order Analytics for a Food Delivery Platform  
> **Language:** MySQL 8.0+ | **Database:** `orderss` | **Table:** `orders`

---

## 📌 Overview

This project contains a suite of analytical SQL queries built to support **Growth, Marketing, Operations, and CRM** teams at a food delivery platform. Each query solves a specific business problem — from tracking daily customer acquisition to powering real-time loyalty triggers.

---

## 🗂️ Database Schema

**Table: `orders`**

| Column | Type | Description |
|---|---|---|
| `Customer_code` | VARCHAR | Unique customer identifier |
| `placed_at` | DATETIME | Timestamp of when the order was placed |
| `Cuisine` | VARCHAR | Type of cuisine (e.g., Italian, Chinese) |
| `Restaurant_id` | VARCHAR | Unique restaurant identifier |
| `Promo_code_Name` | VARCHAR | Promo code used — `NULL` if none |

---

## ⚙️ Setup

```sql
CREATE DATABASE orderss;
USE orderss;
```

> Requires **MySQL 8.0+** for window function support (`ROW_NUMBER`, `PARTITION BY`).

---

## 🔍 Query Index

| # | Query | Key Technique |
|---|---|---|
| 1 | Top 3 outlets by cuisine (no LIMIT/TOP) | `ROW_NUMBER()`, CTE |
| 2 | Daily new customer acquisition count | `MIN()`, CTE, date cast |
| 3 | Single-order Jan 2025 customers | `NOT IN` subquery, `HAVING` |
| 4 | Lapsed promo-acquired customers | CTE + `JOIN`, `DATE_SUB()` |
| 5 | Every-3rd-order trigger (today) | `ROW_NUMBER()`, modulo `%` |
| 6 | Customers who only order on promos | `COUNT()` vs `COUNT(column)` |
| 7 | Organic acquisition rate — Jan 2025 | Conditional aggregation, `CASE` |

---

## 📋 Query Details

### Q1 — Top 3 Outlets by Cuisine Type
**Business use:** Surface best-performing restaurants per cuisine for featured placement.

```sql
WITH cte AS (
  SELECT Cuisine, Restaurant_id, COUNT(*) AS no_of_orders
  FROM orders
  GROUP BY Cuisine, Restaurant_id)
SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY cuisine ORDER BY no_of_orders DESC) AS rn
  FROM cte) a
WHERE rn <= 3;
```

---

### Q2 — Daily New Customer Acquisition
**Business use:** Monitor customer growth trends day-over-day; evaluate campaign performance.

```sql
WITH cte AS (
  SELECT Customer_code, CAST(MIN(placed_at) AS date) AS first_order_date
  FROM orders
  GROUP BY Customer_code)
SELECT first_order_date, COUNT(*) AS no_of_new_customers
FROM cte
GROUP BY first_order_date
ORDER BY first_order_date;
```

---

### Q3 — Single-Order January 2025 Customers
**Business use:** Detect one-and-done customers from a specific cohort for re-engagement.

```sql
SELECT Customer_code, COUNT(*) AS no_of_orders
FROM orders
WHERE MONTH(placed_at) = 1 AND YEAR(placed_at) = 2025
  AND Customer_code NOT IN (
    SELECT DISTINCT Customer_code FROM orders
    WHERE NOT (MONTH(placed_at) = 1 AND YEAR(placed_at) = 2025))
GROUP BY Customer_code
HAVING COUNT(*) = 1;
```

---

### Q4 — Lapsed Promo-Acquired Customers
**Business use:** Re-activate customers who haven't ordered in 7+ days, acquired 1+ month ago on a promo.

```sql
WITH cte AS (
  SELECT Customer_code,
    MIN(Placed_at) AS first_order_date,
    MAX(Placed_at) AS latest_order_date
  FROM orders GROUP BY Customer_code)
SELECT cte.*, orders.Promo_code_Name AS first_order_promo
FROM cte
INNER JOIN orders
  ON cte.Customer_code = orders.Customer_code
  AND cte.first_order_date = orders.Placed_at
WHERE latest_order_date < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
  AND first_order_date < DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
  AND orders.Promo_code_Name IS NOT NULL;
```

---

### Q5 — Every-3rd-Order Trigger (Today)
**Business use:** Power a real-time trigger to send personalized comms at each 3rd order milestone.

```sql
WITH cte AS (
  SELECT customer_code, placed_at,
    ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY placed_at) AS order_number
  FROM orders)
SELECT * FROM cte
WHERE order_number % 3 = 0
  AND DATE(placed_at) = CURDATE();
```

---

### Q6 — Promo-Only Multi-Order Customers
**Business use:** Flag customers with zero organic spend — margin risk and promo graduation candidates.

```sql
SELECT Customer_code,
  COUNT(*) AS no_of_orders,
  COUNT(Promo_code_Name) AS promo_orders
FROM orders
GROUP BY Customer_code
HAVING COUNT(*) > 1
  AND COUNT(*) = COUNT(Promo_code_Name);
```

> **Trick:** `COUNT(column)` ignores NULLs. If `COUNT(*) = COUNT(Promo_code_Name)`, every order had a promo.

---

### Q7 — Organic Acquisition Rate (January 2025)
**Business use:** Measure channel quality — what % of new customers came in without a promo.

```sql
WITH cte AS (
  SELECT customer_code, promo_code_name, placed_at,
    ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY placed_at) AS rn
  FROM orders
  WHERE MONTH(placed_at) = 1)
SELECT
  COUNT(CASE WHEN rn = 1 AND promo_code_name IS NULL THEN customer_code END) * 100.0
  / COUNT(DISTINCT customer_code) AS percentage
FROM cte;
```

---

## 🧠 SQL Concepts Covered

- `WITH` / Common Table Expressions (CTEs)
- `ROW_NUMBER()` window function with `PARTITION BY`
- `DATE_SUB()`, `CURDATE()`, `MONTH()`, `YEAR()`, `CAST()`
- `NOT IN` subquery filtering
- `HAVING` for post-aggregation filtering
- Conditional aggregation with `CASE WHEN`
- Modulo operator `%` for interval-based targeting
- `COUNT(column)` vs `COUNT(*)` for NULL-aware counting

---

## 📁 File Structure

```
sqlProject/
├── README.md                        ← You are here
├── sqlProject.sql                   ← All queries
└── SQL_Project_Documentation.docx  ← Full project documentation
```

---

## 📬 Notes

- Queries **Q4** and **Q5** are date-sensitive — they use `CURDATE()` and will return different results depending on when they are run.
- All queries are self-contained and can be executed independently.
- Window functions require **MySQL 8.0+**. They will not work on MySQL 5.x.
