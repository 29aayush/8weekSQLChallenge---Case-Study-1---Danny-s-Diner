use dannys_diner;
#What is the total amount each customer spent at the restaurant? 
select distinct m.customer_id,sum(me.price) as total_amt from members m 
join sales s on m.customer_id=s.customer_id 
join menu me on me.product_id=s.product_id 
group by m.customer_id
order by m.customer_id;

#How many days has each customer visited the restaurant?
select m.customer_id, count(distinct order_date) as total_days from members m 
join sales s on m.customer_id=s.customer_id 
group by m.customer_id
order by m.customer_id;

#What was the first item from the menu purchased by each customer?
with cte1 as (select distinct customer_id, min(order_date) as order_date from sales 
group by customer_id)

select distinct c.customer_id,m.product_name  from cte1 c join sales s on c.customer_id=s.customer_id and c.order_date=s.order_date
join menu m on s.product_id=m.product_id;


#What is the most purchased item on the menu and how many times was it purchased by all customers?
select a.product_id,a.product_name,a.purchase_count from (
select distinct m.product_id,m.product_name,count(distinct s.customer_id) as purchase_count,
dense_rank() over (order by count(distinct s.customer_id) desc) as rnk from sales s 
join menu m on s.product_id=m.product_id
group by m.product_id,m.product_name)a
where a.rnk=1;

#Which item was the most popular for each customer?
select a.customer_id,a.product_name from (
select distinct s.customer_id,m.product_name,count(s.product_id) as order_count, dense_rank() over (partition by s.customer_id order by count(s.product_id) desc) as rnk  from sales s 
join menu m on s.product_id=m.product_id
group by s.customer_id,m.product_name
) a where a.rnk=1;

#Which item was purchased first by the customer after they became a member?
select a.customer_id,a.order_date,a.product_name from (
select m.customer_id,s.order_date,me.product_name, dense_rank() over (partition by m.customer_id order by s.order_date asc) rnk
from members m join sales s on m.customer_id=s.customer_id and s.order_date>=m.join_date
join menu me on s.product_id=me.product_id
) a 
where a.rnk=1;

#Which item was purchased just before the customer became a member?
select a.customer_id,a.order_date,a.product_name from (
select m.customer_id,s.order_date,me.product_name, dense_rank() over (partition by m.customer_id order by s.order_date asc) rnk
from members m join sales s on m.customer_id=s.customer_id and s.order_date<m.join_date
join menu me on s.product_id=me.product_id
) a 
where a.rnk=1;

#What is the total items and amount spent for each member before they became a member?
select distinct m.customer_id, count(s.product_id) as total_items ,sum(me.price) as total_amount 
from members m join sales s on m.customer_id=s.customer_id and s.order_date<m.join_date
join menu me on s.product_id=me.product_id
group by m.customer_id
order by m.customer_id;

#If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select a.customer_id,sum(a.points) as total_points from (
select s.customer_id, case when me.product_name="sushi" then 20*me.price else 10*me.price end as points 
from sales s join menu me on s.product_id=me.product_id
) a
group by a.customer_id;

#In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select a.customer_id,sum(a.points) as total_points from (
select s.customer_id, m.join_date,s.order_date, 20*me.price as points 
from members m join sales s on m.customer_id=s.customer_id 
join menu me on s.product_id=me.product_id
where datediff(m.join_date,s.order_date)<=7
) a
where month(a.order_date)=1
group by a.customer_id;

#Bonus Question 1
select s.customer_id,s.order_date,me.product_name,me.price,case when s.order_date>=m.join_date and m.join_date is not null then "Y" else "N" end as 'member' from sales s left join members m on m.customer_id=s.customer_id 
left join menu me on s.product_id=me.product_id
order by s.customer_id,s.order_date,me.product_name;


select * from members;

#Bonus Question 1 - Ranking 

with cte as (select s.customer_id,s.order_date,me.product_name,me.price,case when s.order_date>=m.join_date and m.join_date is not null then "Y" else "N" end as 'member' from sales s left join members m on m.customer_id=s.customer_id 
left join menu me on s.product_id=me.product_id
order by s.customer_id,s.order_date,me.product_name)

select *,dense_rank() over (partition by customer_id order by order_date asc) as ranking from cte
where member="Y"
union all
select *,"Null" as ranking from cte
where member="N"
order by customer_id,order_date,product_name

