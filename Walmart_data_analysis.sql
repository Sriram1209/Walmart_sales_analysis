--rounding off total column
UPDATE Walmart SET
total = ROUND(total::NUMERIC, 2)::DOUBLE PRECISION;

--changing data type of date column from text to date
ALTER TABLE Walmart
ALTER COLUMN date SET
DATA TYPE DATE USING TO_DATE(date, 'DD/MM/YY');

--changing data type of time column from text to time
ALTER TABLE Walmart
ALTER COLUMN time SET
DATA TYPE TIME USING time::TIME;

ALTER TABLE Walmart
ALTER COLUMN quantity SET
DATA TYPE NUMERIC USING quantity::NUMERIC;

CREATE VIEW name AS
SELECT * FROM Walmart 
ORDER BY invoice_id
LIMIT 15;


-- Business Problems

--Q1: What are the different payment methods, and how many transactions and items were sold with each method?
--P1: This helps understand customer preferences for payment methods, aiding in payment optimization strategies

SELECT payment_method, COUNT(payment_method) AS no_of_payments FROM Walmart
GROUP BY payment_method
ORDER BY COUNT(payment_method);

--Q2: Which category received the highest average rating in each branch?
--P2: This allows Walmart to recognize and promote popular categories in specific branches, enhancing customer satisfaction and branch-specific marketing

WITH ranked AS (
	SELECT category, branch, 
	ROUND(AVG(rating)::NUMERIC,2) AS avg_rating,
	RANK() OVER(PARTITION BY branch ORDER BY ROUND(AVG(rating)::NUMERIC,2) DESC) AS rank
FROM Walmart
GROUP BY branch, category
)
SELECT * FROM ranked
WHERE rank = 1;

--Q3: What is the busiest day of the week for each branch based on transaction volume?
--P3: This insight helps in optimizing staffing and inventory management to accommodate peak days

WITH quantity_per_date AS(
	SELECT branch, TO_CHAR(date, 'DAY') AS day, COUNT(payment_method) AS no_of_transactions, 
	DENSE_RANK() OVER(PARTITION BY branch ORDER BY COUNT(payment_method) DESC) AS rank FROM Walmart
	GROUP BY 1, 2 
)
SELECT branch, day, no_of_transactions FROM quantity_per_date
WHERE rank = 1;

--Q4: How many items were sold through each payment method?
--P4: This helps Walmart track sales volume by payment type, providing insights into customer purchasing habits.

SELECT payment_method, 
	COUNT(*) AS no_of_transactions, 
	SUM(quantity) AS no_of_items 
FROM Walmart
GROUP BY payment_method;

--Q5: What are the average, minimum, and maximum ratings for each category in each city?
--P5: This data can guide city-level promotions, allowing Walmart to address regional preferences and improve customer experiences.

SELECT city, category,
	ROUND(AVG(rating)::NUMERIC, 2) AS AVERAGE, 
	MIN(rating) AS MINIMUN, 
	MAX(rating) AS MAXIMUN 
FROM Walmart
GROUP BY 1,2;

--Q6: What is the total profit for each category, ranked from highest to lowest?
--P6: Identifying high-profit categories helps focus efforts on expanding these products or managing pricing strategies effectively.

SELECT category, 
	ROUND(SUM(total * profit_margin)::NUMERIC, 2) AS profit
FROM Walmart
GROUP BY category;

--Q7: What is the most frequently used payment method in each branch?
--P7: This information aids in understanding branch-specific payment preferences, potentially allowing branches to streamline their payment processing systems

SELECT branch, payment_method, no_of_transaction FROM 
	(SELECT branch, payment_method, 
	 COUNT(payment_method) AS no_of_transaction,
	 DENSE_RANK() OVER(PARTITION BY branch ORDER BY COUNT(payment_method) DESC) AS RANK
     FROM Walmart
     GROUP BY branch, payment_method
     ORDER BY branch)
WHERE RANK = 1;

--Q8: How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?
--P8: This insight helps in managing staff shifts and stock replenishment schedules, especially during high-sales periods.

SELECT branch,
	CASE
		WHEN EXTRACT(HOUR FROM time) < 12 THEN 'MORNING'
		WHEN EXTRACT(HOUR FROM time) > 12 AND EXTRACT(HOUR FROM time) < 17 THEN 'AFTERNOON'
		ELSE 'EVENING'
	END AS session,
	COUNT(*) 
FROM Walmart
GROUP BY 1,2
ORDER BY 1;

--Q9: Which branches experienced the decrease in revenue compared to the previous year?	
--P9: Detecting branches with declining revenue is crucial for understanding possible local issues and creating strategies to boost sales or mitigate losses

WITH cte AS(
	SELECT branch, EXTRACT(YEAR FROM date) AS year, ROUND(SUM(total)::NUMERIC, 2) AS revenue_cur,
	LEAD(ROUND(SUM(total)::NUMERIC, 2)) OVER(PARTITION BY branch ORDER BY EXTRACT(YEAR FROM date)) AS next_year_revenue
	FROM Walmart
	GROUP BY 1, 2
)
SELECT * FROM cte
WHERE revenue_cur < next_year_revenue
ORDER BY 1, 2;

SELECT * FROM NAME

