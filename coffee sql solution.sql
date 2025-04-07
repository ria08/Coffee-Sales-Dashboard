create database coffee_sales_data;


-- Data cleaning process

-- Converting to date format

update coffee_shop_sales
set transaction_date= str_to_date(transaction_date, '%d-%m-%Y');

alter table coffee_shop_sales
modify column transaction_date date;

describe coffee_shop_sales;

-- Converting to time format

update coffee_shop_sales
set transaction_time= str_to_date(transaction_time, '%H:%i:%s');


alter table coffee_shop_sales
modify column transaction_time time;

-- changing the name of first column

alter table coffee_shop_sales
change column ï»¿transaction_id transaction_id int;

select * from coffee_shop_sales;

-- Calculate the overall sales of coffee for a month

select round(sum(unit_price * transaction_qty)) as total_coffee_sales
from coffee_shop_sales
where month(transaction_date) = 5 ; -- 5 refers to may here

-- Calculate month-on-month increase or decrease in sales

select
    month(transaction_date) as month,
    round(sum(unit_price * transaction_qty)) as total_sales,
    (sum(unit_price * transaction_qty) - LAG(sum(unit_price * transaction_qty), 1) -- difference b/w sales of current and previous month
    over (order by month(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1) -- dividing by previous month sales to get percent
    over (order by month(transaction_date)) * 100 as mom_increase_percentage 
from
    coffee_shop_sales
where
    month(transaction_date) in (4, 5) -- for months of April and May
group by
    month(transaction_date)
order by
    month(transaction_date);

-- calculate total orders for a respective month

select count(*) as total_orders
from coffee_shop_sales
where month(transaction_date) = 5; -- for the month of may

-- calculate month-on-month increase or decrease in no of coffee orders

select 
    month(transaction_date) as month,
    round(count(*)) as total_orders,
    (count(*) - LAG(count(*), 1) 
    over (order by month(transaction_date))) / LAG(count(*), 1) 
    over (order by month(transaction_date)) * 100 as mom_increase_percentage
from
    coffee_shop_sales
where 
    month(transaction_date) in (4, 5) -- for April and May
group by
    month(transaction_date)
order by
    month(transaction_date);


-- calculate total quantity sold for each respective month

select sum(transaction_qty) as total_quantity_sold
from coffee_shop_sales
where month(transaction_date) =5; -- for may month


-- calculate month-on-month increase or decrease in total quantity sold

select 
month(transaction_date) as month,
    round(sum(transaction_qty)) as total_quantity_sold,
    (sum(transaction_qty) - LAG(sum(transaction_qty), 1) 
    over (order by month(transaction_date))) / LAG(sum(transaction_qty), 1) 
    over (order by month(transaction_date)) * 100 as mom_increase_percentage
from
    coffee_shop_sales
where
    month(transaction_date) in (4, 5)   -- for April and May
group by
    month(transaction_date)
order by
    month(transaction_date);

-- write a query for calendar table that will be displayed in power BI

SELECT 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1),'K') AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1),'K') AS total_quantity_sold
FROM 
    coffee_shop_sales
WHERE 
    transaction_date = '2023-05-18'; -- for may 18


-- segmenting sales data based on weekdays and weekends

select 
case when dayofweek(transaction_date) in (1,7) 
then 'Weekends'
else 'Weekdays'
end as day_type,
concat(round(sum(unit_price * transaction_qty)/1000, 1),'K') as total_coffee_sales
from coffee_shop_sales
where month(transaction_date) = 5
group by 
case when dayofweek(transaction_date) in (1,7) 
then 'Weekends'
else 'Weekdays'
end;


-- calculate sales data based on different locations

SELECT 
	store_location,
	SUM(unit_price * transaction_qty) as total_sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) =5 
GROUP BY store_location
ORDER BY SUM(unit_price * transaction_qty) DESC;


-- calculate average sales for a particular month

SELECT 
concat(round(AVG(total_sales)/1000, 1), 'K') AS average_sales
FROM (
    SELECT 
        sum(unit_price * transaction_qty) AS total_sales
    FROM 
        coffee_shop_sales
	WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        transaction_date
) AS sales_query;


-- calculate daily sales for a particular month

SELECT 
    DAY(transaction_date) AS day_of_month,
    ROUND(SUM(unit_price * transaction_qty),1) AS total_sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5  -- Filter for May
GROUP BY 
    DAY(transaction_date)
ORDER BY 
    DAY(transaction_date);

-- using both queries determine if sales for a particular day was above or below average

SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_shop_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;


-- analysing sales w.r.t different product category

SELECT 
	product_category,
	CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000, 1), 'K') as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC;

-- analysing sales w.r.t different product type and finding top 10 products for a particular month

SELECT 
	product_type,
	CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000, 1), 'K') as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 10;

-- filtering sales, quantity and orders based on month, day, and hour of transaction

SELECT 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty) AS Total_Quantity,
    COUNT(*) AS Total_Orders
FROM 
    coffee_shop_sales
WHERE 
    DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5)

-- display sales for all hours in a day in a particular month
SELECT
    HOUR(transaction_time) AS Hour_of_Day,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    HOUR(transaction_time)
ORDER BY 
    HOUR(transaction_time);
    
    -- find sales from monday to sunday for a particular month

SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END;
