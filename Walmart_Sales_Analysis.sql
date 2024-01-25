-- Creating a database
CREATE DATABASE IF NOT EXISTS WalmartSales;

-- Switching to the database we just created
USE WalmartSales;

-- Creating a table to store the sales data
CREATE TABLE IF NOT EXISTS sales (
			invoice_id VARCHAR(20) NOT NULL PRIMARY KEY,
            branch VARCHAR(5) NOT NULL,
            city VARCHAR(25) NOT NULL,
            customer VARCHAR(20) NOT NULL,
            gender VARCHAR(10) NOT NULL,
            product_line VARCHAR(40) NOT NULL,
            unit_price DECIMAL(6,2) NOT NULL,
            quantity INT NOT NULL,
            vat DECIMAL(6,4) NOT NULL,
            total DECIMAL(12,4) NOT NULL,
            date DATETIME NOT NULL,
            time TIME NOT NULL,
            payment_method VARCHAR(20) NOT NULL,
            cogs DECIMAL(5,2) NOT NULL,
            gross_margin_pct DECIMAL(7,6) NOT NULL,
            gross_income DECIMAL(10,4) NOT NULL,
            rating DECIMAL(3,1) NOT NULL
            );

-- -------------------------------------------------- FEATURE ENGINEERING ----------------------------------------------------------
-- Adding the 'time of day' column in the table
-- This will help us answer questions like at what time of the day, most sales are made 

ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

-- Updating and Inserting values in the column
UPDATE sales 
SET time_of_day = (
		CASE
			WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
            WHEN time BETWEEN '12:00:01' AND '16:30:00' THEN 'Afternoon'
            ELSE 'Evening'
		END 
        ); 

-- Adding a new column 'day-name' in the table
-- It will be used to answer questions like on which day each branch is busiest

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales 
SET day_name= DAYNAME(date);

-- Adding the 'month-name' column in the table

ALTER TABLE sales ADD COLUMN month VARCHAR(10);

UPDATE sales 
SET month = MONTHNAME(date);



-- ------------------------------ Answering Business Questions ------------------------------------------------
-- ------------------------------------- GENERIC --------------------------------------------------------------

-- Q1: How many unique cities does the data have?
SELECT DISTINCT city
FROM sales;

-- Q2: In which city is each branch?
SELECT branch,city
FROM sales
GROUP BY city,branch;

-- SELECT DISTINCT branch,city
-- from sales;

-- ----------------------------------------------------------------------------------------------------------
-- -------------------------------------- Products related --------------------------------------------------

-- Q3: How many unique product lines does the data have?
SELECT COUNT(DISTINCT product_line) as 'product_count'
FROM sales;

-- Q4: What is the most common payment method?
SELECT payment_method, COUNT(payment_method) as 'count'
FROM sales
GROUP BY payment_method
ORDER BY count DESC
LIMIT 1;

-- Q5: What is the most selling product line?
SELECT product_line, COUNT(*) as cnt
FROM sales
GROUP BY product_line
ORDER BY cnt DESC
LIMIT 1;

-- Q6: What is the total revenue by month?
SELECT month,SUM(total) as total_revenue
FROM sales
GROUP BY month
ORDER BY total_revenue DESC;

-- Q7: What month had the largest COGS?
SELECT month,SUM(cogs) as 'total'
FROM sales
GROUP BY month
ORDER BY total DESC 
LIMIT 1;

-- Q8: What product line had the largest revenue?
SELECT product_line, SUM(total) as 'revenue'
FROM sales
GROUP BY product_line
ORDER BY revenue DESC
LIMIT 1;

-- Q9: Which city has the largest revenue?
SELECT city,SUM(total) as revenue
FROM sales
GROUP BY city
ORDER BY revenue DESC
LIMIT 1;

-- Q10: What product line had the largest VAT?
SELECT product_line,AVG(vat) vat 
FROM sales
GROUP BY product_line
ORDER BY vat DESC
LIMIT 1;

-- Q11: Fetch each product line and add a column to those 
--      product line showing "Good", "Bad". Good if its greater than average sales
SELECT product_line,ROUND(AVG(total),2)as avg_sales,
			CASE
				WHEN AVG(total) > (SELECT AVG(total) FROM sales) THEN 'Good'
                ELSE 'Bad'
			END as Remarks
FROM sales 
GROUP BY product_line;

-- Q12: Which branch sold more products than average product sold?
SELECT branch, AVG(quantity) as avg_sale
FROM sales
GROUP BY branch
HAVING AVG(quantity)> (SELECT AVG(quantity) FROM sales);

-- Q13: What is the most common product line by gender?
WITH rankcte AS (
			SELECT gender,product_line,COUNT(*) as occurrences,
            ROW_NUMBER() OVER(PARTITION BY gender ORDER BY COUNT(*) DESC) as row_num
            FROM sales
            GROUP BY gender,product_line
            )
SELECT gender,product_line,occurrences
FROM rankcte 
WHERE row_num=1;

-- Q14: What is the average rating of each product line?
SELECT product_line,ROUND(AVG(rating),2) as avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;


-- ----------------------------------- SALES ------------------------------------------------

-- Q15: Number of sales made in each time of the day per weekday
SELECT day_name,time_of_day,SUM(quantity) as num_of_sales
FROM sales
WHERE day_name NOT IN ('Saturday','Sunday')
GROUP BY day_name,time_of_day
ORDER BY num_of_sales DESC;

-- Q16: Which of the customer types brings the most revenue?
SELECT customer,SUM(total) as revenue
FROM sales
GROUP BY customer
ORDER BY revenue DESC
LIMIT 1;

-- Q17: Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT city, AVG(vat) as avg_tax
FROM sales
GROUP BY city
ORDER BY avg_tax DESC
LIMIT 1;

-- Q18: Which customer type pays the most in VAT?
SELECT customer,SUM(vat) as total_tax
FROM sales
GROUP BY customer
ORDER BY total_tax DESC
LIMIT 1;


-- ---------------------------------- CUSTOMER ---------------------------------------------

-- Q19: How many unique customer types does the data have? 
SELECT COUNT(DISTINCT customer) AS cust_types_count 
FROM sales;

-- Q20: How many unique payment methods does the data have?
SELECT COUNT(DISTINCT payment_method) AS type_of_paymethods
FROM sales;

-- Q21: What is the most common customer type?
SELECT customer,COUNT(*) AS no_of_customers
FROM sales
GROUP BY customer
ORDER BY no_of_customers DESC
LIMIT 1;

-- Q22: Which customer type buys the most?
SELECT customer, COUNT(*) visits
FROM sales 
GROUP BY customer
ORDER BY visits DESC
LIMIT 1;

-- Q23: What is the gender of most of the customers?
SELECT gender,COUNT(*) AS no_of_visitors
FROM sales 
GROUP BY gender
ORDER BY no_of_visitors DESC;

-- Q24: What is the gender distribution per branch?
SELECT branch,gender,COUNT(*) AS cnt
FROM sales
GROUP BY branch,gender
ORDER BY branch,cnt DESC;

-- Q25: Which time of the day do customers give most ratings?
SELECT time_of_day,COUNT(*) AS num_of_ratings
FROM sales
GROUP BY time_of_day
ORDER BY num_of_ratings DESC;

-- Q26: Which time of the day do customers give most ratings per branch?
SELECT branch,time_of_day,COUNT(*) AS num_of_ratings
FROM sales
GROUP BY branch,time_of_day
ORDER BY branch,num_of_ratings DESC;

-- Q27: Which day of the week has the best avg ratings?
SELECT day_name,AVG(rating) as avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC
LIMIT 1;

-- Q28: Which day of the week has the best average ratings per branch?
WITH mycte AS(
		SELECT branch,day_name,ROUND(AVG(rating),2) as avg_rating,
        ROW_NUMBER() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as day_rank
		FROM sales
		GROUP BY branch,day_name
        )
SELECT branch,day_name,avg_rating 
FROM mycte 
WHERE day_rank=1;


-- ------------------------------------------ END -----------------------------------------------------------
























			