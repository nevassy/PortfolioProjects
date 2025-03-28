#drop table if exists goldusers_signup;
CREATE DATABASE zomatodb;
USE zomatodb;

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 


INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'), (3,'2017-04-21');

#drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-04-11');

#drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


#drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

/*1. Total amount each customer spent on Zomato*/
SELECT sales.userid, sum(product.price) AS Total_spent
FROM sales
JOIN product ON sales.product_id = product.product_id
GROUP BY sales.userid;

/*2. Days each customer visited zomato*/
SELECT userid, COUNT(DISTINCT created_date) Distinct_days
FROM sales
GROUP BY userid;

/*3.First product purchased by each customer*/
SELECT * FROM
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) AS rnk
FROM sales) a
WHERE rnk = 1;

/*4.Most purchased item on the menu and the times it was purchased by all customers*/
/*a.Most purchased item*/
SELECT product_id, COUNT(product_id) 
FROM sales
GROUP BY product_id 
ORDER BY COUNT(product_id) DESC 
LIMIT 1;

/*b. times it was purchased by all customers*/
SELECT userid, COUNT(product_id) AS cnt FROM sales WHERE product_id =
(SELECT product_id FROM sales GROUP BY product_id ORDER BY COUNT(product_id) DESC 
LIMIT 1)
GROUP BY userid;

/*5. Most popular product for each customer*/
SELECT * FROM
(SELECT *, RANK() OVER(PARTITION BY userid ORDER BY cnt DESC) AS rnk
FROM  (SELECT userid, product_id, COUNT(product_id) cnt
FROM sales GROUP BY userid, product_id) a)b WHERE rnk =1;

/*6. Item purchased first by the customer after they became a member*/
SELECT * FROM
(SELECT c. *, RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
INNER JOIN goldusers_signup b ON a.userid = b.userid AND created_date >= gold_signup_date)c)d WHERE rnk = 1;

/*7.Which item was purchased just before the customer became a member*/
SELECT * FROM
(SELECT c. *, RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) rnk FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
INNER JOIN goldusers_signup b ON a.userid = b.userid AND created_date < gold_signup_date)c)d WHERE rnk = 1;

/*8. Total orders and amount spent for each member before they became a member*/
SELECT userid, COUNT(created_date) AS order_purchased, SUM(price) AS total_amt_spent FROM
(SELECT c. *, d.price FROM 
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date FROM sales a 
INNER JOIN goldusers_signup b ON a.userid = b.userid AND created_date <= gold_signup_date)c
INNER JOIN product d ON c.product_id = d.product_id)e
GROUP BY userid;

/*9. If buying each product generates points for eg 5rs=2 zomato point and each product has different 
purchasing points for eg for p1 5rs=1 zomato point, for p2 10rs=5 zomato point and p3 5rs = 1 zomato point.
Calculate points collected by each customers and for which product most points have been given till now*/

/*a. Calculate points collected by each customers*/
SELECT userid, SUM(total_points) * 2.5 AS total_money_earned FROM
(SELECT e.*, amt/points AS total_points FROM
(SELECT d. *, 
	CASE 
		WHEN product_id=1 THEN 5
		WHEN product_id=2 THEN 2
		WHEN product_id=3 THEN 5
		ELSE 0
	END AS points FROM
(SELECT c.userid, c.product_id, SUM(price) amt FROM
(SELECT a. *, b.price FROM sales a
INNER JOIN product b ON a.product_id=b.product_id)c
GROUP BY userid, product_id)d)e)f
GROUP BY userid;

/*for which product most points have been given till now*/
SELECT * FROM
(SELECT *, RANK() OVER(ORDER BY total_point_earned DESC) rnk FROM
(SELECT product_id, SUM(total_points) AS total_point_earned FROM
(SELECT e.*, amt/points AS total_points FROM
(SELECT d. *, 
	CASE 
		WHEN product_id=1 THEN 5
		WHEN product_id=2 THEN 2
		WHEN product_id=3 THEN 5
		ELSE 0
	END AS points FROM
(SELECT c.userid, c.product_id, SUM(price) amt FROM
(SELECT a. *, b.price FROM sales a
INNER JOIN product b ON a.product_id=b.product_id)c
GROUP BY userid, product_id)d)e)f
GROUP BY product_id)f)g WHERE rnk=1;

/*10. In the first one year after a customer joins the gold program (including their join date) 
irrespective of what the customer has purchased they earn 5 zomato points for every 10 rs 
spent who earned more  1 or 3 and what was their points earnings in their first yr */
/*1 zp = 2rs*/
/*0.5 zp = 1rs*/

SELECT c.*, d.price*0.5 AS total_points_earned FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
INNER JOIN goldusers_signup b ON a.userid = b.userid AND created_date >= gold_signup_date AND 
created_date <=DATE_ADD(gold_signup_date, INTERVAL 1 YEAR ))c
INNER JOIN product d ON c.product_id = d.product_id;

/*11. rnk all the transaction of the customers*/
SELECT *, RANK() OVER(PARTITION BY userid ORDER BY created_date) rnk 
FROM sales;

/*12. rank all the transactions for each member whenever they are a zomato gold member for every 
non gold member transaction mark as na*/
SELECT e.*, CASE WHEN rnk =0 then 'na' ELSE rnk END AS rnk FROM
(SELECT c.*, 
	CASE 
		WHEN gold_signup_date is null THEN 0
        ELSE RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) 
	END AS rnk FROM
(SELECT a.userid, a.created_date, a.product_id, b.gold_signup_date
FROM sales a
LEFT JOIN goldusers_signup b ON a.userid = b.userid AND created_date >= gold_signup_date)c)e;


