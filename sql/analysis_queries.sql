USE amazon_sales_analysis;

DROP TEMPORARY TABLE IF EXISTS enriched_orders;

CREATE TEMPORARY TABLE enriched_orders AS
SELECT
  order_id,
  category,
  amount,
  qty,
  ship_service_level,
  DATE_FORMAT(date, '%Y-%m-01') AS month,
  CASE
    WHEN status = 'Cancelled' THEN 'pre_shipment_cancellation'
    WHEN status IN (
      'Shipped - Returned to Seller',
      'Shipped - Returning to Seller',
      'Shipped - Rejected by Buyer'
    ) THEN 'returned'
    WHEN status IN (
      'Shipped - Lost in Transit',
      'Shipped - Damaged'
    ) THEN 'logistic_failure'
    ELSE 'active_or_delivered'
  END AS outcome
FROM amazon_sales;

/* ====================================
   THEME 1: EXECUTIVE BUSINESS SUMMARY
   ==================================== */

SELECT
  COUNT(DISTINCT order_id) AS total_orders,
  SUM(amount) AS gross_revenue,
  SUM(
    CASE 
      WHEN outcome <> 'active_or_delivered'
      THEN amount ELSE 0 
    END
  ) AS lost_revenue,
  ROUND(
    100.0 * SUM(
      CASE WHEN outcome <> 'active_or_delivered'
      THEN amount ELSE 0 END
    ) / SUM(amount), 2
  ) AS revenue_loss_percent
FROM enriched_orders;

/* ================================
   THEME 2: BUSINESS SCALE OVERVIEW
   ================================ */
 
SELECT COUNT(DISTINCT order_id) AS total_orders,
sum(qty) AS total_qty_sold ,
SUM(amount) AS total_revenue
FROM enriched_orders;
/*This query measures gross business volume.
Loss analysis is handled separately in the cancellation theme.*/ 

/* =================================
   THEME 3: REVENUE TREND OVER TIME
   ================================= */
   
WITH monthly_revenue AS(
SELECT month,
SUM(amount) AS revenue
FROM enriched_orders
GROUP BY  month
)
SELECT 
month ,
revenue,
revenue-LAG(revenue) OVER (ORDER BY month) AS revenue_diff,
CASE WHEN revenue-LAG(revenue) OVER (ORDER BY month)>0 THEN 'Grow' 
WHEN revenue-LAG(revenue) OVER (ORDER BY month)<0 THEN 'Decline'
ELSE 'Flat'
END AS trend
FROM monthly_revenue
ORDER BY month;
/*Revenue fluctuates across months, 
suggesting growth is inconsistent 
and influenced by time-based demand 
patterns*/

/* ===================
    REVENUE MOMENTUM
   =================== */

-- Rolling 3-month revenue trend (MySQL)
SELECT
  month,
  SUM(amount) AS monthly_revenue,
  AVG(SUM(amount)) OVER (
    ORDER BY month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ) AS rolling_3_month_revenue
FROM enriched_orders
GROUP BY month
ORDER BY month;
/*The rolling average smooths short-term noise and confirms that 
revenue growth from April onward is consistent and demand-driven, 
not accidental.*/

/* =======================================
   THEME 4: CATEGORY PERFORMANCE & REVENUE 
   ======================================= */

SELECT category,
SUM(qty) AS total_quantity,
SUM(amount) AS category_revenue,
ROUND(100.0*SUM(amount)/SUM(SUM(amount)) OVER(),3) AS revenue_percent,
RANK() OVER(ORDER BY SUM(qty) DESC ) AS quantity_rank,
RANK() OVER(ORDER BY SUM(amount) DESC) AS revenue_rank,
(RANK() OVER(
ORDER BY SUM(amount) DESC) - RANK() OVER(ORDER BY SUM(qty) DESC ))
AS rank_gap
FROM enriched_orders
GROUP BY category;
/*Sales volume and revenue move together across 
categories, indicating no major price or margin 
imbalance*/

WITH order_category AS (
   SELECT order_id,
   category,
   SUM(amount) AS order_value
   FROM enriched_orders
   GROUP BY order_id,category
   )
SELECT category,
ROUND(AVG(order_value),2) AS avg_order_value,
COUNT(DISTINCT order_id) AS orders
FROM order_category
GROUP BY category
ORDER BY avg_order_value DESC;
/*Some categories get fewer orders but higher bills per order, 
which makes them more valuable per transaction*/

/* ======================================
   THEME 5: CUSTOMER ORDER VALUE BEHAVIOR
   ====================================== */

WITH order_values AS(
SELECT order_id,
SUM(amount) AS order_value
FROM enriched_orders
GROUP BY order_id
),
bucketed_orders AS(
SELECT order_id,
order_value,
NTILE(4) OVER (ORDER BY order_value) AS value_quartile
FROM order_values
)
SELECT 
CASE WHEN value_quartile =1 THEN 'Low'
WHEN value_quartile IN (2,3) THEN 'Mid'
ELSE 'High'
END AS order_segment,
COUNT(DISTINCT order_id) AS orders,
ROUND(100.0 * COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (),2) AS order_pct
FROM bucketed_orders
GROUP BY order_segment
ORDER BY orders DESC;
/*The majority of orders are mid-value, 
but high-value orders, though fewer, 
are key revenue drivers.*/

/* =======================================
   THEME 6: ORDER OUTCOMES & REVENUE LOSS
   ======================================= */
-- Part A: Order outcome distribution
SELECT outcome,
COUNT(DISTINCT order_id) AS order_count,
ROUND(100.0*COUNT(DISTINCT order_id)/SUM(COUNT(DISTINCT order_id)) OVER(),3)
AS order_share_percentage
FROM enriched_orders
GROUP BY outcome;
/*A noticeable number of orders still fail 
due to cancellations, returns, or delivery issues.*/

-- Part B: Revenue loss by category

SELECT category,
SUM(amount) AS gross_revenue,
SUM(CASE
WHEN outcome<> 'active_or_delivered'
THEN amount ELSE 0 END ) AS lost_revenue, 
ROUND(100.0 * SUM(CASE
WHEN outcome<> 'active_or_delivered'
THEN amount ELSE 0 END )/SUM(amount),2)
AS revenue_loss_percentage
FROM enriched_orders 
GROUP BY category
ORDER BY revenue_loss_percentage DESC;
/* Assumption: Any non-delivered order 
is treated as full revenue loss.*/

/*Most of the revenue loss is 
coming from just a few categories, 
not evenly across all of them.*/

/* ===================================
   THEME 7: LOGISTICS RISK ASSESSMENT
   =================================== */

SELECT
ship_service_level,
COUNT(DISTINCT order_id) AS total_orders,
COUNT(DISTINCT CASE WHEN outcome <> 'active_or_delivered' THEN order_id
END) AS failed_orders,
ROUND(100.0 * COUNT(DISTINCT CASE WHEN outcome <> 'active_or_delivered'
THEN order_id END) / COUNT(DISTINCT order_id), 2
) AS failure_rate_pct
FROM enriched_orders
GROUP BY ship_service_level
HAVING COUNT(DISTINCT order_id) > 100
ORDER BY failure_rate_pct DESC;
/*Standard shipping shows nearly double the customer-impact failure rate 
compared to Expedited, indicating that faster shipping is associated with
materially better order outcomes rather than just quicker delivery.




