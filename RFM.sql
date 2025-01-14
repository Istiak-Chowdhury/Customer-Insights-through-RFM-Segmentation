use rfm_sales;
select * from sales_sample_data;
select distinct count(*) from sales_sample_data;	-- 2823
select distinct status from sales_sample_data;	-- 6
select distinct year_id from sales_sample_data;	-- 2003, 2004, 2005


-- 2005 year total month
select 
month_id
from sales_sample_data
where year_id = '2005'
group by 1
order by 1 asc;


-- Total sales by Year
select 
year_id,
month_id,
round(sum(sales),2) as Revenue
from sales_sample_data
group by 1,2
order by 1,2;

select ORDER_DATE from sales_sample_data;
SELECT STR_TO_DATE(ORDER_DATE, '%Y-%m-%d') AS `Date` FROM SALES_SAMPLE_DATA LIMIT 5;

SELECT MAX(STR_TO_DATE(ORDER_DATE, '%Y-%m-%d')) AS LATESTDATE from SALES_SAMPLE_DATA;	-- 2005-05-31
SELECT MIN(STR_TO_DATE(ORDER_DATE, '%Y-%m-%d')) AS EARLIESTDATE from SALES_SAMPLE_DATA;	-- 2003-01-06


-- Date Difference 
SELECT 
    DATEDIFF(MAX(STR_TO_DATE(ORDER_DATE, '%Y-%m-%d')),
            MIN(STR_TO_DATE(ORDER_DATE, '%Y-%m-%d'))) AS Dif
FROM
    SALES_SAMPLE_DATA;	--  876


-- RFM Segementation: Recency, Frequency, and Monetary information based Segmentation of Customers
CREATE OR REPLACE VIEW RFM_SEGMENT AS
WITH RFM_Initial_Calculation AS (
SELECT 
    CUSTOMERNAME,
    ROUND(SUM(SALES), 0) AS MonetaryValue,
    COUNT(DISTINCT ORDER_NUMBER) AS Frequency,
    DATEDIFF(MAX(STR_TO_DATE(ORDER_DATE, '%Y-%m-%d')),
            (SELECT 
                    MAX(STR_TO_DATE(ORDER_DATE, '%Y-%m-%d'))
                FROM
                    SALES_SAMPLE_DATA)) * (- 1) AS Recency
FROM
    SALES_SAMPLE_DATA
GROUP BY CUSTOMERNAME
),
RFM_Score_Calculation AS (
	SELECT 
		C.*,
		NTILE(4) OVER (ORDER BY C.Recency DESC) AS RFM_Recency_SCORE,
        NTILE(4) OVER (ORDER BY C.Frequency DESC) AS RFM_Frequency_SCORE,
		NTILE(4) OVER (ORDER BY C.MonetaryValue DESC) AS RFM_MonetaryValue_SCORE
	FROM RFM_Initial_Calculation AS C
)
SELECT 
		R.CUSTOMERNAME,
        (R.RFM_Recency_SCORE + R.RFM_Frequency_SCORE + R.RFM_MonetaryValue_SCORE) AS TOTAL_RFM_SCORE,
        CONCAT_WS(
		'', R.RFM_Recency_SCORE, R.RFM_Frequency_SCORE, R.RFM_MonetaryValue_SCORE
    ) AS RFM_CATEGORY_COMBINATION
FROM 
    RFM_Score_Calculation AS R;
    
    
SELECT * FROM RFM_SEGMENT
order by RFM_CATEGORY_COMBINATION;   


SELECT 
    CUSTOMERNAME,
    RFM_CATEGORY_COMBINATION,
    CASE
        WHEN RFM_CATEGORY_COMBINATION IN (111 , 112, 121, 132, 211, 211, 212, 114, 141) THEN 'CHURNED CUSTOMER'
        WHEN RFM_CATEGORY_COMBINATION IN (133 , 134, 143, 24, 334, 343, 344, 144) THEN 'SLIPPING AWAY, CANNOT LOSE'
        WHEN RFM_CATEGORY_COMBINATION IN (311 , 411, 331) THEN 'NEW CUSTOMERS'
        WHEN RFM_CATEGORY_COMBINATION IN (222 , 231, 221, 223, 233, 322) THEN 'POTENTIAL CHURNERS'
        WHEN RFM_CATEGORY_COMBINATION IN (323 , 333, 321, 341, 422, 332, 432) THEN 'ACTIVE'
        WHEN RFM_CATEGORY_COMBINATION IN (433 , 434, 443, 444) THEN 'LOYAL'
        ELSE 'CANNOT BE DEFINED'
    END AS CUSTOMER_SEGMENT
FROM
    RFM_SEGMENT;


SELECT DISTINCT
    RFM_CATEGORY_COMBINATION
FROM
    RFM_SEGMENT
ORDER BY 1 asc;




WITH CTE1 AS
(SELECT 
    CUSTOMERNAME,
    CASE
        WHEN RFM_CATEGORY_COMBINATION IN (111, 112, 121, 123, 132, 211, 211, 212, 114, 141) THEN 'CHURNED CUSTOMER'
        WHEN RFM_CATEGORY_COMBINATION IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'SLIPPING AWAY, CANNOT LOSE'
        WHEN RFM_CATEGORY_COMBINATION IN (311, 411, 331) THEN 'NEW CUSTOMERS'
        WHEN RFM_CATEGORY_COMBINATION IN (222, 231, 221,  223, 233, 322) THEN 'POTENTIAL CHURNERS'
        WHEN RFM_CATEGORY_COMBINATION IN (323, 333,321, 341, 422, 332, 432) THEN 'ACTIVE'
        WHEN RFM_CATEGORY_COMBINATION IN (433, 434, 443, 444) THEN 'LOYAL'
    ELSE 'CANNOT BE DEFINED'
    END AS CUSTOMER_SEGMENT
FROM RFM_SEGMENT)
SELECT 
    CUSTOMER_SEGMENT, count(*) as Number_of_Customers
FROM CTE1
GROUP BY 1
ORDER BY 2 DESC;
