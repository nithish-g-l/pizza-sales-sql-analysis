CREATE DATABASE pizzashop;

CREATE TABLE ORDERS (
order_id int NOT NULL,
order_date DATE NOT NULL,
order_time TIME NOT NULL,
primary key(order_id)
);

CREATE TABLE ORDERS_DETAILS (
order_details_id int NOT NULL,
order_id int NOT NULL,
pizza_id text NOT NULL,
quantity int NOT NULL,
primary key(order_details_id)
);

-- Retrieve the total number of orders placed.
SELECT count(order_id) as total_orders
FROM orders;

-- Calculate the total revenue generated from pizza sales.
SELECT SUM(od.quantity * pi.price) AS total_sales
FROM orders_details od JOIN pizzas pi 
ON od.pizza_id = pi.pizza_id;

-- Identify the highest-priced pizza.
SELECT pt.name AS highest_priced_pizza,  price 
FROM pizzas pi INNER JOIN pizza_types pt
ON pi.pizza_type_id = pt.pizza_type_id
ORDER BY pi.price DESC
LIMIT 1;

-- Identify the most common pizza size ordered.
SELECT pi.size, count(od.pizza_id) AS orders_count
FROM pizzas pi JOIN orders_details od
ON pi.pizza_id = od.pizza_id
GROUP BY pi.size 
ORDER BY orders_count DESC
LIMIT 1;

-- List the top 5 most ordered pizza types along with their quantities.
SELECT pizza_types.name, SUM(orders_details.quantity) AS total_quantity
FROM pizza_types JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name 
ORDER BY total_quantity DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT pizza_types.category, SUM(orders_details.quantity)
FROM pizza_types JOIN pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category;

-- Determine the distribution of orders by hour of the day.
SELECT HOUR(order_time) AS hour, COUNT(order_id) AS count
FROM orders
GROUP BY hour;

-- Join relevant tables to find the category-wise distribution of pizzas.
SELECT category, COUNT(name)
FROM pizza_types
GROUP BY category; 

-- Group the orders by date and calculate the average number of pizzas ordered per day.
SELECT AVG(quantity) 
FROM 
(SELECT orders.order_date, SUM(orders_details.quantity) AS quantity
FROM orders join orders_details
ON orders.order_id = orders_details.order_id
GROUP BY orders.order_date) AS sum_quantity;

-- Determine the top 3 most ordered pizza types based on revenue.
SELECT pizzas.pizza_type_id, ROUND(SUM(pizzas.price*orders_details.quantity),2) AS REVENUE
FROM pizzas JOIN orders_details 
ON pizzas.pizza_id = orders_details.pizza_id
GROUP BY pizzas.pizza_type_id
order by REVENUE DESC
LIMIT 3;

-- Calculate the percentage contribution of each pizza type to total revenue.
SELECT pizza_types.category, CONCAT((SUM(orders_details.quantity * pizzas.price) / (SELECT SUM(od.quantity * pi.price) AS total_sales
FROM orders_details od JOIN pizzas pi 
ON od.pizza_id = pi.pizza_id))*100, '%' )AS 'percent cotribution' 
FROM pizza_types join pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details
ON orders_details.pizza_id = pizzas.pizza_id
group by pizza_types.category;


-- Analyze the cumulative revenue generated over time.
SELECT order_date, SUM(revenue) OVER(ORDER BY order_date) as cum_revenue
FROM
(SELECT orders.order_date, SUM(pizzas.price * orders_details.quantity) AS revenue
FROM pizzas JOIN orders_details 
ON pizzas.pizza_id = orders_details.pizza_id
JOIN orders ON orders_details.order_id = orders.order_id
GROUP BY orders.order_date) AS sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
SELECT name, revenue
FROM
(SELECT category, name, revenue,
RANK() OVER(PARTITION BY category ORDER BY revenue DESC ) AS rn
FROM
(
SELECT pizza_types.category, pizza_types.name, SUM(orders_details.quantity*pizzas.price) AS revenue
FROM pizza_types JOIN pizzas
ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN orders_details ON orders_details.pizza_id = pizzas.pizza_id
GROUP BY  pizza_types.category, pizza_types.name) AS sales_category) AS a
WHERE rn>=3;

