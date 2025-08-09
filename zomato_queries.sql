-- 1. Select the database to use
USE zomato;

-- 2. Count the total number of users
SELECT COUNT(*) FROM users;

-- 3. Retrieve 5 random user records
SELECT * FROM users ORDER BY RAND() LIMIT 5;

-- 4. Find all orders that have no restaurant rating
SELECT * FROM orders 
WHERE restaurant_rating IS NULL;

-- 5. Replace all NULL restaurant ratings with zero
UPDATE orders
SET restaurant_rating = 0 
WHERE restaurant_rating IS NULL;

-- 6. Get the number of orders placed by each customer
SELECT u.name, COUNT(*) AS num_of_orders
FROM users u 
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id;

-- 7. Find the restaurant that offers the highest number of menu items
SELECT r.r_name, COUNT(*) AS num_of_menu_items 
FROM restraunts r 
JOIN menu m ON r.r_id = m.r_id
GROUP BY r.r_id
ORDER BY num_of_menu_items DESC 
LIMIT 1;

-- 8. Get the number of orders (votes) and average restaurant rating for all restaurants
SELECT r.r_name, COUNT(*) AS num_of_votes, 
ROUND(AVG(restaurant_rating), 2) AS avg_rest_rating
FROM orders o 
JOIN restraunts r ON o.r_id = r.r_id
GROUP BY r.r_id;

-- Alternative version by restaurant ID
SELECT r_id, COUNT(order_id) AS num_of_votes, 
ROUND(AVG(restaurant_rating), 2) AS avg_rest_rating
FROM orders
GROUP BY r_id;

-- 9. Identify the food item that is sold in the highest number of restaurants
SELECT f.f_name, COUNT(*) AS num_rest_where_food_sold
FROM restraunts r 
JOIN menu m ON r.r_id = m.r_id 
JOIN food f ON m.f_id = f.f_id
GROUP BY f.f_id
ORDER BY num_rest_where_food_sold DESC 
LIMIT 1;

-- 10. Find the restaurant that earned the highest revenue in any month
SELECT r.r_name, MONTH(o.date), SUM(amount) AS revenue_per_month
FROM orders o 
JOIN restraunts r ON o.r_id = r.r_id
GROUP BY r.r_id, MONTH(date)
ORDER BY SUM(amount) DESC 
LIMIT 1;

-- 11. List restaurants whose total sales exceed 1500
SELECT r.r_name, SUM(amount) AS total_sales_per_rest
FROM orders o 
JOIN restraunts r ON o.r_id = r.r_id
GROUP BY r.r_id
HAVING total_sales_per_rest > 1500;

-- 12. Find all customers who have never placed an order
SELECT u.user_id, u.name
FROM users u 
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE o.order_id IS NULL;

-- Alternative using subquery
SELECT user_id, name 
FROM users
WHERE user_id NOT IN (
	SELECT DISTINCT(user_id) 
	FROM orders
);

-- Alternative using EXCEPT (if supported by the DBMS)
SELECT user_id, name FROM users
EXCEPT
SELECT t1.user_id, t2.name 
FROM orders t1 
JOIN users t2 ON t1.user_id = t2.user_id;

-- 13. Display food items ordered by a specific customer within a given date range
SELECT u.name, o.date, f.f_name 
FROM users u 
JOIN orders o ON u.user_id = o.user_id
JOIN order_details od ON o.order_id = od.order_id
JOIN food f ON od.f_id = f.f_id
WHERE u.name = 'ankit' 
AND o.date BETWEEN '2022-05-15' AND '2022-06-15';

-- 14. Find each customer’s most frequently ordered food item
WITH temp_table AS (
	SELECT u.user_id, u.name, f.f_name, COUNT(*) AS num
	FROM users u 
	JOIN orders o ON u.user_id = o.user_id 
	JOIN order_details od ON o.order_id = od.order_id 
	JOIN food f ON od.f_id = f.f_id
	GROUP BY u.name, f.f_name
)
SELECT user_id, name, f_name, num
FROM temp_table t1
WHERE num = (
	SELECT MAX(num) 
	FROM temp_table t2 
	WHERE t2.user_id = t1.user_id
);

-- 15. Identify the restaurant with the highest average price per dish
SELECT r_name, SUM(price) / COUNT(*) AS avg_price_per_dish
FROM restraunts r 
JOIN menu m ON r.r_id = m.r_id
GROUP BY r.r_id
ORDER BY avg_price_per_dish DESC 
LIMIT 1;

-- 16. Calculate delivery partner compensation
-- Formula: (Number of deliveries * 100) + (1000 * Average delivery rating)
SELECT o.partner_id, d.partner_name,
(COUNT(*) * 100 + 1000 * AVG(delivery_rating)) AS salary
FROM orders o 
JOIN delivery_partner d ON o.partner_id = d.partner_id
GROUP BY o.partner_id;

-- 17. Retrieve monthly revenue for a specific restaurant
SELECT r.r_name, MONTHNAME(o.date), SUM(amount)
FROM orders o 
JOIN restraunts r ON o.r_id = r.r_id
WHERE r.r_name = 'dominos'
GROUP BY o.r_id, MONTHNAME(date);

-- 18. Find restaurants that only serve vegetarian food
SELECT r_name 
FROM restraunts
WHERE r_id NOT IN (
	SELECT r_id
	FROM menu m 
	JOIN food f ON m.f_id = f.f_id
	WHERE type != 'veg'
);

-- 19. Get the maximum and minimum order values for each customer
SELECT u.name, MAX(amount) AS max_order, MIN(amount) AS min_order
FROM users u 
JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id;

-- 20. Find the top 2 highest-spending Zomato customers for each month
/* INSIGHT: Identifies monthly "whale" customers who contribute the most revenue.
   Zomato can use this list to offer loyalty rewards, premium offers, 
   or exclusive discounts to retain them and increase lifetime value.
*/
select * from (select monthname(date) as 'month',user_id,sum(amount) as 'total',
			   dense_rank() over(partition by monthname(date) order by sum(amount)) as 'month_user_rank'
			   from orders
			   group by monthname(date),user_id
			   order by month(date)) as t
where t.month_user_rank < 3;
