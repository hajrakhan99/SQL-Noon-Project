create database orderss;
use orderss;
select * from orders;


--  1 find three top 3 outlets by cuisuin type without using limit and top function---
with cte as (
select Cuisine,Restaurant_id,COUNT(*) as no_of_orders
from orders
group by Cuisine,Restaurant_id)
select * from (
select * 
,Row_Number() over (partition by cuisine order by no_of_orders desc) as rn
from cte)a
where rn<=3;




-- 2 - find the daily new customer count from the launch date (everyday how many are we acquiring )
with cte as (
select Customer_code, cast(MIN(placed_at) AS date) as first_order_date
from orders
group by Customer_code)

select first_order_date,COUNT(*) as no_of_new_customers
from cte
group by first_order_date
order by first_order_date
;


-- 3 COUNT ALL THE USERS WHO WERE ACQUIRED IN JAN 2025 AND ONLY PLACED ONE ORDER IN JAN AND  DID NOT PLACE ANY ORDER
SELECT Customer_code, COUNT(*) AS no_of_orders
FROM orders
WHERE MONTH(placed_at) = 1 AND YEAR(placed_at) = 2025
 and Customer_code not in (select distinct Customer_code
 from orders
 where not (MONTH(placed_at)=1 and YEAR(placed_at)=2025)
 )
 GROUP BY Customer_code
HAVING COUNT(*) = 1;


-- 4 list all customers with no order in the last 7 days but were acquired one month ago with their first order on promo 
WITH cte AS (
    SELECT Customer_code,
           MIN(Placed_at) AS first_order_date,
           MAX(Placed_at) AS latest_order_date
    FROM orders
    GROUP BY Customer_code
)

SELECT cte.*,
       orders.Promo_code_Name AS first_order_promo
FROM cte
INNER JOIN orders 
ON cte.Customer_code = orders.Customer_code
AND cte.first_order_date = orders.Placed_at

WHERE latest_order_date < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
AND first_order_date < DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
AND orders.Promo_code_Name IS NOT NULL;

-- 5  Growth team is planning to create a trigger that will target customers after their every 
-- third order with a personalized communication and they have asked you to create a query for this
WITH cte AS (
  SELECT
    customer_code,
    placed_at,
    ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY placed_at) AS order_number
  FROM orders
)
SELECT *
FROM cte
WHERE order_number % 3 = 0
  AND DATE(placed_at) = CURDATE();

-- 6 list customers who placed more than 1 order and all their orders on a promo only 
select Customer_code, COUNT(*) as no_of_orders,COUNT(Promo_code_Name) as promo_orders
from orders 
group by Customer_code
having COUNT(*)>1 AND COUNT(*)=COUNT(Promo_code_Name);

-- 7 what percent of customers were organically acquired in jan 2025 ,(placed their first order without promo code)
WITH cte AS (
  SELECT
    customer_code,
    promo_code_name,
    placed_at,
    ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY placed_at) AS rn
  FROM orders
  WHERE MONTH(placed_at) = 1
)
SELECT 
  COUNT(CASE WHEN rn = 1 AND promo_code_name IS NULL THEN customer_code END) * 100.0 
  / COUNT(DISTINCT customer_code) AS percentage
FROM cte;


