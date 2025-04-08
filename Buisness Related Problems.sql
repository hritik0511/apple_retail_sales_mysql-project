-- answers of all the questions from medium to complex difficulty level 

-- Buisness Problems
-- Medium Problems

-- 1.Find the number of stores in each country.

SELECT 
country,
 count(store_name) as total_stores 
FROM stores 
GROUP BY country 
ORDER BY total_stores;

-- 2.Calculate the total number of units sold by each store.

SELECT 
s.store_id, 
st.store_name,
SUM(s.quantity) as total_units_sold 
FROM sales s
JOIN stores st
ON s.store_id = st.store_id
GROUP BY s.store_id,st.store_name
ORDER BY total_units_sold DESC;

-- 3.Identify how many sales occurred in December 2023.

SELECT
COUNT(sale_id) AS total_sales
FROM sales 
WHERE sale_date 
BETWEEN '2023-12-01' AND '2023-12-31';

-- 4.Determine how many stores have never had a warranty claim filed.

SELECT 
COUNT(*) 
FROM stores
WHERE store_id NOT IN (
						SELECT 
						DISTINCT(store_id) 
						FROM sales s
						RIGHT JOIN warranty w
						ON s.sale_id = w.sale_id
                    );
                    
-- 5.Calculate the percentage of warranty claims marked as "Warranty Void"

SELECT
	ROUND(
			COUNT(claim_id)/
							CAST((SELECT COUNT(*) FROM warranty) AS DECIMAL)*100
            ,2) as warranty_void_percentage 
FROM warranty
WHERE repair_status = 'Warranty Void';

-- 6. Identify which store had the highest total units sold in the last year

SELECT
	s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_unit_sold
FROM sales s
JOIN stores st
ON s.store_id = st.store_id
WHERE sale_date BETWEEN '2020-01-01' AND '2021-01-01'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1;

-- 7.Count the number of unique products sold in the last year.

SELECT 
COUNT(DISTINCT product_id) AS total_unique_products
FROM sales
WHERE sale_date BETWEEN '2020-01-01' AND '2021-01-01';


-- 8.Find the average price of products in each category.

SELECT
	c.category_id,
    c.category_name,
    AVG(p.price) AS avg_price
FROM products p
JOIN category c
ON p.category_id = c.category_id
GROUP BY 1,2
ORDER BY 3 DESC;

-- 9.How many warranty claims were filed in 2020

SELECT
	COUNT(*)
FROM warranty
WHERE claim_date LIKE '2020%';

-- 10.For each store, identify the best-selling day based on highest quantity sold.

SELECT *
FROM (
		SELECT 
         store_id,
         DAYNAME(sale_date) as days_name,
         SUM(quantity) as total_units_sold,
         RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS ranks
         FROM sales 
         GROUP BY 1,2
         ) AS t1
WHERE ranks = 1;

-- Medium to Hard Problems

-- 11.Identify the least selling product in each country for each year based on total units sold.

WITH product_rank
AS(
SELECT
	st.country,
    p.product_name,
    SUM(s.quantity) as total_qty_sold,
    RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) as ranks
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
JOIN products as p
ON s.product_id = p.product_id
GROUP BY 1, 2
)
SELECT * 
FROM product_rank 
WHERE ranks = 1;

-- 12.Calculate how many warranty claims were filed within 180 days of a product sale

SELECT 
	COUNT(*)
FROM warranty as w
LEFT JOIN sales as s
ON s.sale_id = w.sale_id
WHERE w.claim_date - s.sale_date <= 180;

-- 13.Determine how many warranty claims were filed for products launched in the last 4 years

SELECT
	p.product_name,
    COUNT(w.claim_id) as total_claims
FROM warranty as w
RIGHT JOIN sales as s
ON w.sale_id = s.sale_id
JOIN products as p
ON s.product_id = p.product_id
WHERE DATEDIFF(CURRENT_DATE() , p.lauch_date) <= 1460
GROUP BY 1;

-- 14.List the months in the last three years where sales exceeded 5,000 units in the USA.

WITH intermediate_result
AS(
SELECT
	MONTHNAME(s.sale_date) as month_name,
    SUM(s.quantity) as total_units_sold
FROM sales as s
LEFT JOIN stores as st
ON s.store_id = st.store_id 
WHERE st.country = 'USA' and DATEDIFF(CURRENT_DATE(),s.sale_date) <= 1095 
GROUP BY 1
)
SELECT * 
FROM intermediate_result
WHERE total_units_sold > 5000;   

-- 15.Identify the product category with the most warranty claims filed in the last two years.

SELECT 
	c.category_name,
    COUNT(w.claim_id) as total_claims
FROM warranty as w
LEFT JOIN sales as s   
ON  w.sale_id = s.sale_id
JOIN products as p
ON s.product_id = p.product_id
JOIN category as c
ON p.category_id = c.category_id
WHERE DATEDIFF(CURRENT_DATE(),w.claim_date) <= 730
GROUP BY 1;

-- complex problems

-- 16.Determine the percentage chance of receiving warranty claims after each purchase for each country.

WITH t1
AS (
SELECT 
	st.country,
    SUM(s.quantity) as total_units_sold,
    COUNT(w.claim_id) as total_claims
FROM sales as s
JOIN stores as st
ON s.store_id = st.store_id
LEFT JOIN warranty as w
ON s.sale_id = w.sale_id
GROUP BY 1 )
SELECT 
	country,
    total_claims,
    total_units_sold,
    ROUND(((total_claims)/(total_units_sold) * 100 ),2) AS risk
FROM t1 
ORDER BY 4 DESC;

-- 17.Analyze the year-by-year growth ratio for each store.

WITH yearly_sales
AS(
SELECT
	s.store_id,
    st.store_name,
    EXTRACT(YEAR FROM sale_date) as year_,
    SUM(s.quantity * p.price) as total_sale
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id 
JOIN stores as st
ON s.store_id = st.store_id
GROUP BY 1,3
ORDER BY 1,3
),
growth_ratio 
AS(
SELECT
	store_name,
    year_,
    LAG(total_sale, 1) OVER(PARTITION BY store_name ORDER BY year_) as last_year_sale,
    total_sale as current_year_sales
FROM yearly_sales
)
SELECT 
	store_name,
    year_,
    last_year_sale,
    current_year_sales,
    ROUND(((current_year_sales - last_year_sale)/(last_year_sale))*100, 2) as growth_ratio
FROM growth_ratio
WHERE last_year_sale IS NOT NULL
		AND
        year_ <> EXTRACT(YEAR FROM CURRENT_DATE());
    
-- 18.Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.

SELECT
	CASE
		WHEN p.price < 500 THEN 'Less Expensive Product'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid Range Product'
        ELSE 'Expensive Product'
	END as price_segment,
    COUNT(w.claim_id) as total_claim
FROM warranty as w
LEFT JOIN sales as s
ON w.sale_id = s.sale_id
JOIN products as p
ON p.product_id = s.product_id
WHERE DATEDIFF(CURRENT_DATE(),w.claim_date) <= 1826
GROUP BY 1;

-- 19.Identify the store with the highest percentage of "Paid Repaired" claims relative to total claims filed

WITH paid_repaired 
AS
(SELECT 
	s.store_id,
    COUNT(w.claim_id) as paid_repaired
FROM sales as s
RIGHT JOIN warranty as w
ON s.sale_id = w.sale_id
WHERE w.repair_status = 'Paid Repaired'
GROUP BY 1
),total_repaired 
AS
(SELECT 
	s.store_id,
    COUNT(w.claim_id) as total_repaired
FROM sales as s
RIGHT JOIN warranty as w
ON s.sale_id = w.sale_id
GROUP BY 1)
SELECT
	tr.store_id,
    st.store_name,
    tr.total_repaired,
    pr.paid_repaired,
    ROUND(((pr.paid_repaired)/(tr.total_repaired))*100,2) as percentage
FROM paid_repaired as pr
JOIN total_repaired as tr
ON pr.store_id = tr.store_id
JOIN stores as st
ON tr.store_id = st.store_id;

	
-- 20.Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period

WITH t1 
AS
(SELECT 
	s.store_id,
    EXTRACT(YEAR FROM s.sale_date) as year_,
    EXTRACT(MONTH FROM s.sale_date) as month_,
    SUM(s.quantity * p.price) as total_revenue
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
GROUP BY 1,2,3
ORDER BY 1,2,3
)
SELECT 
	store_id,
    year_,
    month_,
    total_revenue,
    SUM(total_revenue) OVER(PARTITION BY store_id,year_ ORDER BY year_,month_) as running_total
FROM t1;

-- bonus question 
-- 21.Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6-12 months, 12-18 months, and beyond 18 months.

SELECT 
	p.product_name,
    CASE
		WHEN s.sale_date BETWEEN p.lauch_date AND DATEDIFF(s.sale_date,p.lauch_date) <= 181 THEN '0-6 months'
		WHEN s.sale_date BETWEEN p.lauch_date AND DATEDIFF(s.sale_date,p.lauch_date) > 181 AND DATEDIFF(s.sale_date,p.lauch_date)<=365 THEN '6-12 months'
		WHEN s.sale_date BETWEEN p.lauch_date AND DATEDIFF(s.sale_date,p.lauch_date) > 365 AND DATEDIFF(s.sale_date,p.lauch_date) <= 548 THEN '12-18 months'
		ELSE '18+'
	END AS plc,
    SUM(s.quantity) as total_qty_sale
    FROM sales as s
    JOIN products as p
    ON s.product_id = p.product_id
    GROUP BY 1,2
    ORDER BY 1,3;

    
