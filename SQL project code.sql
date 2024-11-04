-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT market FROM dim_customer 
WHERE customer = "Atliq Exclusive" and REGION = "APAC"


-- 2) What is the percentage of unique product increase in 2021 vs. 2020?

WITH cte20 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_manufacturing_cost AS f 
    WHERE cost_year = 2020
),
cte21 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_manufacturing_cost AS f 
    WHERE cost_year = 2021
)

SELECT *,
       ROUND((unique_products_2021 - unique_products_2020) * 100.0 / unique_products_2020, 2) AS percentage_chg
FROM cte20
CROSS JOIN cte21;


-- 3 ) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.

SELECT segment, COUNT( DISTINCT (product_code)) as product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count desc

-- 4)  Follow-up: Which segment had the most increase in unique products in
2021 vs 2020?

WITH cte_2020 AS (
    SELECT p.segment,COUNT(DISTINCT s.product_code) AS product_count_2020 
    FROM dim_product p
    JOIN fact_sales_monthly s ON p.product_code = s.product_code 
    WHERE s.fiscal_year = 2020 
    GROUP BY p.segment
),
cte_2021 AS (
    SELECT p.segment,COUNT(DISTINCT s.product_code) AS product_count_2021 
    FROM dim_product p
    JOIN fact_sales_monthly s ON p.product_code = s.product_code 
    WHERE s.fiscal_year = 2021 
    GROUP BY p.segment
)
SELECT 
    cte_2020.segment, 
    cte_2020.product_count_2020, 
    cte_2021.product_count_2021,
    ABS(cte_2020.product_count_2020 - cte_2021.product_count_2021) AS difference
FROM cte_2020 
JOIN cte_2021 ON cte_2020.segment = cte_2021.segment 
ORDER BY difference DESC;


-- 5) Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost


SELECT m.product_code, p.product, m.manufacturing_cost
FROM fact_manufacturing_cost m join dim_product p
USING (product_code)
WHERE m.manufacturing_cost =(select max(manufacturing_cost)
FROM fact_manufacturing_cost)
OR m.manufacturing_cost = (select min(manufacturing_cost)
FROM fact_manufacturing_cost)
ORDER BY m.manufacturing_cost desc;

 -- 6 Generate a report which contains the top 5 customers who received an  average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 

SELECT a.customer_code, c.customer, round(avg(a.pre_invoice_discount_pct)*100,2) as avg_dis_pct
FROM  fact_pre_invoice_deductions a join dim_customer c using (customer_code)
WHERE fiscal_year =2021 and c.market="india" group by a.customer_code, c.customer 
ORDER BY  avg_dis_pct desc limit 5;


-- 7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic
  --     decisions. The final report contains these columns: Month Year Gross sales Amount


SELECT monthname(s.date) as month,s.fiscal_year,
ROUND(sum(g.gross_price*sold_quantity),2)
AS gross_sales_amt FROM fact_sales_monthly s
JOIN dim_customer c USING (customer_code)
JOIN fact_gross_price g USING (product_code)
WHERE customer="atliq exclusive"
GROUP BY  monthname(s.date) ,s.fiscal_year
ORDER BY fiscal_year


-- 8) In which quarter of 2020, got the maximum total_sold_quanƟty? The final output contains these fields sorted by the total_sold_quanƟty, Quarter total_sold_quantity

SELECT
CASE
WHEN month(date) in (9,10,11) then 'Q1'
WHEN month(date) in (12,01,02) then 'Q2'
WHEN month(date) in (03,04,05) then 'Q3'
ELSE 'Q4'
END AS Quarters,
SUM(sold_quantity) AS total_sold_qty
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_qty DESC;


-- 10 )Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage

WITH x AS (SELECT c.channel,
        ROUND(SUM(g.gross_price * s.sold_quantity) / 1000000, 2) AS gross_sales_mln
    FROM fact_sales_monthly s
    JOIN dim_customer c USING(customer_code)
    JOIN fact_gross_price g USING(product_code)
    WHERE s.fiscal_year = 2021
    GROUP BY c.channel)
SELECT channel,gross_sales_mln,
    ROUND((gross_sales_mln / (SELECT SUM(gross_sales_mln) FROM x)) * 100, 2)
    AS pct FROM X
ORDER BY gross_sales_mln DESC;













