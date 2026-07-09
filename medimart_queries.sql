-- ============================================
-- MediMart Pharmaceutical Analytics Project
-- SQL Business Queries
-- Author: Yana Ajjamada
-- ============================================

-- Q1: Order status breakdown
SELECT status, COUNT(*) AS order_count
FROM orders
GROUP BY status;

-- Q2: Total revenue from completed orders
SELECT SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'completed';

-- Q3: Revenue by product category, highest to lowest
SELECT p.category, SUM(oi.quantity * oi.unit_price) AS category_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;

-- Q4: Each customer's name, city, and total orders (includes customers with 0 orders)
SELECT c.name, c.city, COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city;

-- Q5: Bangalore customers with completed orders
SELECT DISTINCT c.name, o.order_date
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE c.city = 'Bangalore' AND o.status = 'completed';

-- Q6: Products never ordered
SELECT product_name, category
FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id FROM order_items
);

-- Q7: Customer segmentation by order frequency
SELECT c.name,
    CASE
        WHEN COUNT(o.order_id) >= 3 THEN 'Loyal'
        WHEN COUNT(o.order_id) = 2 THEN 'Returning'
        ELSE 'New'
    END AS customer_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name;

-- Q8: Top spending customer per city (using CTE + ROW_NUMBER window function)
WITH customer_spend AS (
    SELECT c.customer_id, c.name, c.city,
        SUM(o.total_amount) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id, c.name, c.city
),
ranked_spend AS (
    SELECT customer_id, name, city, total_spend,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY total_spend DESC
        ) AS row_num
    FROM customer_spend
)
SELECT name, city, total_spend
FROM ranked_spend
WHERE row_num = 1;

-- Q9: Rank all customers by total spend using DENSE_RANK
SELECT c.name,
    SUM(o.total_amount) AS total_spend,
    DENSE_RANK() OVER (
        ORDER BY SUM(o.total_amount) DESC
    ) AS spend_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.name;

-- Q10: Customers who spent above the average, with the difference shown
WITH customer_spend AS (
    SELECT c.name,
        SUM(o.total_amount) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.status = 'completed'
    GROUP BY c.customer_id, c.name
),
spend_with_avg AS (
    SELECT name, total_spend,
        AVG(total_spend) OVER () AS avg_spend,
        total_spend - AVG(total_spend) OVER () AS difference
    FROM customer_spend
)
SELECT name, total_spend, ROUND(avg_spend, 2) AS avg_spend, ROUND(difference, 2) AS difference
FROM spend_with_avg
WHERE difference > 0
ORDER BY total_spend DESC;