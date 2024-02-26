CREATE SCHEMA dannys_diner;


CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

USE Test_database;


-- 1. What is the total amount each customer spent at the restaurant?

select customer_id,sum(price) as total_amount_spent
from sales left join menu on sales.product_id = menu.product_id
group by customer_id;

---2. How many days has each customer visited the restaurant?

select customer_id,count(distinct(order_date)) as total_days_visited
from sales left join menu on sales.product_id = menu.product_id
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte as (
select customer_id, order_date, product_name from sales left join menu on sales.product_id = menu.product_id
),
cte2 as (
select *, row_number() over (partition by customer_id order by order_date asc) as rn
from cte)
select customer_id, product_name from cte2 where rn = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 m.product_name, count(s.order_date) as orders
from sales s inner join menu m
on s.product_id = m.product_id
group by product_name
order by count(s.order_date) desc


-- 5. Which item was the most popular for each customer?

with cte as (
select product_name, customer_id, count(order_date) as orders, 
rank() over(partition by customer_id order by count(order_date) desc) as rnk
from sales s inner join menu m 
on s.product_id = m.product_id
group by product_name, customer_id)

select customer_id, product_name, orders
from cte where rnk = 1

-- 6. Which item was purchased first by the customer after they became a member?

with cte as (
select m.customer_id,m.join_date,s.order_date,s.product_id,menu.product_name,ROW_NUMBER() over (partition by s.customer_id order by s.order_date asc) as rn
from members m
left join sales s
on s.customer_id = m.customer_id 
left join menu on s.product_id = menu.product_id
where s.order_date>=m.join_date
)
select customer_id, order_date, product_id,product_name
from cte
where rn =1;


-- 7. Which item was purchased just before the customer became a member?

with cte as (
select m.customer_id,m.join_date,s.order_date,s.product_id,menu.product_name,ROW_NUMBER() over (partition by s.customer_id order by s.order_date desc) as rn
from members m
left join sales s
on s.customer_id = m.customer_id 
left join menu on s.product_id = menu.product_id
where s.order_date<m.join_date
)
select customer_id, order_date, product_id,product_name
from cte
where rn =1;

-- 8. What is the total items and amount spent for each member before they became a member?

with cte as(
select m.customer_id,m.join_date,s.order_date,s.product_id,menu.product_name,menu.price
from members m
left join sales s
on s.customer_id = m.customer_id 
left join menu on s.product_id = menu.product_id
where s.order_date<m.join_date)

select customer_id, count(customer_id) as total_items,sum(price) as amount_spent
from cte
group by customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select sales.customer_id,
sum(case when product_name = 'sushi' then price*10*2
 else price*10
 end) as points
from menu inner join sales on sales.product_id = menu.product_id
group by customer_id

 
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
---how many points do customer A and B have at the end of January?

select s.customer_id,sum(case when s.order_date between m.join_date and dateadd(DAY,6,join_date) then price*10*2
when product_name = 'sushi' then price*10*2
else price *10
end) as point
from sales s
inner join members m on s.customer_id=m.customer_id
inner join menu on s.product_id = menu.product_id
where DATETRUNC(month,s.order_date) = '2021-01-01'
group by s.customer_id



---Bonus question 1 - Join all the things:

select s.customer_id, s.order_date,menu.product_name,menu.price,
(case when m.join_date<= s.order_date then 'Y'
else 'N'
end) as member
from menu 
left join sales s on menu.product_id = s.product_id
left join members m on m.customer_id = s.customer_id
order by s.customer_id, s.order_date


---Bonus question 2 - Rank All The Things

with cte as (
select s.customer_id, s.order_date,menu.product_name,menu.price,
(case when m.join_date<= s.order_date then 'Y'
else 'N'
end) as member
from menu 
left join sales s on menu.product_id = s.product_id
left join members m on m.customer_id = s.customer_id)

select *, (case when member = 'Y' then rank() over (partition by customer_id,member order by order_date)
else NULL end) as ranking
from cte
