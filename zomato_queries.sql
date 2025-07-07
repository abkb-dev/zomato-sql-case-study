-- 1.Select a particular database
USE zomato;
-- 2.count number of users
SELECT COUNT(*) FROM users;
-- 3.return random user records
select * from users order by rand() limit 5;
-- 4. Find null values
# let us find those orders on which we didnt get rating.
select * from orders 
where restaurant_rating is null;
-- 5. replace null restaurant_rating values with zero
update orders
set restaurant_rating = 0 
where restaurant_rating is null;
-- 6. find number of orders placed by each customer
select u.name, count(*) as `num_of_orders`
from users u left join orders o
on u.user_id = o.user_id
group by u.user_id;
-- 7.find restaurant with most number of menu items
# konse restaurant me sab se zyada menu items hai
select r.r_name,count(*) as `num_of_menu_items` 
from restraunts r join menu m
on r.r_id = m.r_id
group by r.r_id
order by num_of_menu_items desc limit 1;

-- 8.find number of votes and avg rating for all the restaurants.
# each rest me kitne orders place hue wo hai num_of_votes
# and each rest ki avg_rating kitni hai, to jabhi ek user ne order place kiya
select r.r_name,count(*) as 'num_of_votes', 
round(avg(restaurant_rating),2) as 'avg_rest_rating'
from orders o join restraunts r
on o.r_id  = r.r_id
group by r.r_id;
-- or --
select r_id, count(order_id) as 'num_of_votes', 
round(avg(restaurant_rating),2) as 'avg_rest_rating'
from orders
group by r_id;

-- 9.find the food that is being sold at most number of restaurants.
# wo konsa food hai, jo sabse zyada restraunt me bikta ho.
select f.f_name, count(*) as `num_rest_where_food_sold`-- i.e. count(r.r_id)
from restraunts r join menu m
on r.r_id = m.r_id join food f
on m.f_id = f.f_id
group by f.f_id
order by num_rest_where_food_sold desc limit 1;

-- 10. find restaurant with max revenue in a given month
select r.r_name, month(o.date), sum(amount) as `revenue_per_month`
from orders o join restraunts r
on o.r_id = r.r_id
group by r.r_id,month(date)
order by sum(amount) desc limit 1;

-- 11. find restaurants with total sales > 1500
select r.r_name,sum(amount) as `total_sales_per_rest`
from orders o join restraunts r
on o.r_id = r.r_id
group by r.r_id
having total_sales_per_rest > 1500;

-- 12. find customers who have never ordered
select u.user_id,u.name
from users u left join orders o
on u.user_id = o.user_id
where o.order_id is null;
-- or by using subqueries
select user_id,name from users
where user_id not in (select distinct(user_id) from orders);
-- or by using set operator which is except
select user_id,name from users
except
select t1.user_id,t2.name from orders t1 join users t2
on t1.user_id = t2.user_id;

-- 13.Show order details of a particular customer in a given date range
# ek particular customer ke order details(matlab fooditems etc) in particular date range.
select u.name,o.date,f.f_name 
from users u join orders o 
on u.user_id = o.user_id
join order_details od 
on o.order_id = od.order_id
join food f 
on od.f_id = f.f_id
where u.name = 'ankit' and
o.date between '2022-05-15' and '2022-06-15';

-- 14. Customer favorite food
# first we will find, 
# id,name,foodname and number of times they ordered
select u.name,f.f_name,count(*) as `num` -- number of times that food ordered
from users u join orders o
on u.user_id = o.user_id join order_details od
on o.order_id = od.order_id join food f
on od.f_id = f.f_id
group by u.name,f.f_name;
# the above result set gives har customer ne har food (customer-food pair) kitne bar order kiya hai.
# second, we will create CTE for the above result set, and we iterate over each record where we select
# only those customer - food record where num_of_times the food ordered by customer is equal to maximum
# number of times the food orded by that current customer (which can be done by correlated subquery)
WITH temp_table AS (select u.user_id,u.name,f.f_name,count(*) as `num` -- number of times that food ordered
					from users u join orders o
					on u.user_id = o.user_id join order_details od
					on o.order_id = od.order_id join food f
					on od.f_id = f.f_id
					group by u.name,f.f_name)
select user_id,name,f_name,num
from temp_table t1
where num = (select max(num) from temp_table t2 where t2.user_id = t1.user_id);

-- 15. find most costly restaurants(Avg price/dish)
-- to get avg cost per dist for each restaurant, we first group by r_id,
-- then in each restaurant we get total number of food_items they sell and total price (sum) of
-- all the dishes they sell.
# now to get avg_price_per_dish_for_each_restaurant just divide sum(price)/count(*)
select r_name, sum(price)/count(*) as 'avg_price_per_dish'
from restraunts r join menu m
on r.r_id = m.r_id
group by r.r_id
order by avg_price_per_dish desc limit 1;

-- 16. find delivery partner compensation using the formula (number_of_deliveries * 100 + 1000*avg_rating)
-- Delivery partner compensation means the total money a delivery person (like a rider or driver) 
-- earns from a company (like Zomato or Swiggy) for delivering orders.
-- so we want delivery partner name and its salary(delivery partner compensation)
select o.partner_id ,d.partner_name,
(count(*) * 100 + 1000 * avg(delivery_rating)) as 'salary'
from orders o join delivery_partner d
on o.partner_id = d.partner_id
group by o.partner_id;

-- 17. find revenue per month for specific restaurant
# first i will find revenue generated by each rest in each month
# second i will filter out the rest i want by using where clause.
select r.r_name,monthname(o.date),sum(amount)
from orders o join restraunts r
on o.r_id = r.r_id
where r.r_name = 'dominos' # 2nd step
group by o.r_id,monthname(date); # 1st step

-- 18. find all the restaurant which are purely veg(only veg)
select r_id
from menu m join food f
on m.f_id = f.f_id
where type != 'veg'; -- this gives all rest_id's which sold food other than veg.

-- now by using this list of queries, we will only select those r_id's/r_name which doesnt 
-- came in above list.
select r_name from restraunts
where r_id not in (select r_id
				   from menu m join food f
				   on m.f_id = f.f_id
				   where type != 'veg'); -- these are the rest which solds purely veg food.

-- 19. find min and max order value for all the customers
-- meaning har customer ke liye sabse zyada order amount and sabse kam order amount value for each customer
select u.name, max(amount), min(amount)
from users u join orders o
on u.user_id = o.user_id
group by u.user_id;























