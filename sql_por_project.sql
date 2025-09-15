-- Step 1: I created a dedicated database for this data cleaning project.
-- I did this to keep the work organized and isolated from other data.
CREATE DATABASE IF NOT EXISTS data_cleaning_practice;
USE data_cleaning_practice;

-- Step 2: I dropped the table if it already existed.
-- I did this to avoid conflicts when re-running the script during testing or updates.
DROP TABLE IF EXISTS orders_raw;

-- Step 3: I created a table with raw data types.
-- I chose VARCHAR for 'order_date' and 'amount' because I expect inconsistencies in formatting and data types, which I'll clean later.
CREATE TABLE orders_raw (
    order_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    order_date VARCHAR(20),
    amount VARCHAR(20),
    country VARCHAR(100)
);


-- Step 4: I inserted the raw, messy data exactly as it was provided.
-- I did this to simulate a real-world scenario where data comes in with inconsistencies in formatting, casing, nulls, and errors.
INSERT INTO orders_raw (order_id, customer_name, email, order_date, amount, country) VALUES
(1001, 'John Doe', 'john.doe@example.com', '2023-07-10', '100.50', 'USA'),
(1002, 'jane smith', 'jane.smith@Example.Com', '07/11/2023', '85.00', 'usa'),
(1003, 'Mike O''Conner', '', '2023/07/12', '42', 'United States'),
(1004, 'Ana-María López', 'ana.lopez@@example.com', '2023-13-07', '', 'México'),
(1005, 'Robert', 'robert@example', '2023-07-14', '-25.00', 'Canada'),
(1006, 'Emily Zhang', 'emily.zhang@example.com', '14-07-2023', '67.89', 'CANADA'),
(1007, 'John Doe', 'john.doe@example.com', '2023-07-10', '100.50', 'USA'),
(1008, 'Sarah Parker', 'sarah.parker@example.com', '2023-07-15', 'one hundred', 'US'),
(1009, '', 'no.email@example.com', '2023-07-16', '55.5', 'U.S.A.'),
(1010, 'Alex Murphy', 'alex.murphy@example.com', '2023-07-17', '75.25', 'United States');

-- I started with a basic count of the rows to understand the size of the dataset.
SELECT COUNT(*) AS total_orders FROM orders_raw;


-- I checked for duplicate order IDs to ensure primary key uniqueness.
SELECT order_id, COUNT(*) AS count
FROM orders_raw
GROUP BY order_id
HAVING COUNT(*) > 1;


-- I wanted to understand how many distinct customers are in the dataset.
-- I'm using a combination of customer_name and email to estimate unique customers.
SELECT COUNT(DISTINCT CONCAT(TRIM(LOWER(customer_name)), '|', TRIM(LOWER(email)))) AS unique_customers
FROM orders_raw;


-- I explored the distribution of country values to see inconsistencies and regional diversity.
SELECT country, COUNT(*) AS count
FROM orders_raw
GROUP BY country
ORDER BY count DESC;


-- I analyzed the structure of the 'amount' field to check if all values are numeric and positive.
SELECT 
  CASE 
    WHEN amount REGEXP '^[0-9]+(\\.[0-9]{1,2})?$' THEN 'Valid'
    WHEN amount IS NULL OR amount = '' THEN 'Missing'
    ELSE 'Invalid'
  END AS amount_status,
  COUNT(*) AS count
FROM orders_raw
GROUP BY amount_status;


-- I reviewed the date formats used in 'order_date' to assess their consistency.
-- This helps me identify whether I need to clean or parse the dates.
SELECT order_id, order_date
FROM orders_raw
WHERE STR_TO_DATE(order_date, '%Y-%m-%d') IS NULL;

-- I created a clean version of the table to preserve the original data.
-- I’m converting data types, fixing formatting issues, and cleaning invalid entries.
DROP TABLE IF EXISTS orders_cleaned;

CREATE TABLE orders_cleaned AS
SELECT
    order_id,
    
    -- I standardized the customer name by trimming and capitalizing the first letters.
    CONCAT(UCASE(LEFT(TRIM(customer_name), 1)), LCASE(SUBSTRING(TRIM(customer_name), 2))) AS customer_name,
    
    -- I cleaned and validated the email format.
    CASE
        WHEN email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN LOWER(TRIM(email))
        ELSE NULL
    END AS email,

    -- I converted various date formats into a consistent DATE type.
    STR_TO_DATE(order_date, '%Y-%m-%d') AS order_date, -- fallback will be fixed below

    -- I cleaned and converted amount to DECIMAL where possible.
    CASE 
        WHEN amount REGEXP '^[0-9]+(\\.[0-9]{1,2})?$' THEN CAST(amount AS DECIMAL(10,2))
        ELSE NULL
    END AS amount,

    -- I standardized country names to consistent casing and formats.
    CASE
        WHEN LOWER(country) IN ('usa', 'us', 'u.s.a.', 'united states') THEN 'United States'
        WHEN LOWER(country) IN ('canada') THEN 'Canada'
        WHEN LOWER(country) IN ('méxico', 'mexico') THEN 'Mexico'
        ELSE INITCAP(TRIM(country))
    END AS country

FROM orders_raw;



-- I manually fixed rows with invalid or ambiguous date formats after checking them.
-- STR_TO_DATE fails silently when the format doesn't match.

UPDATE orders_cleaned
SET order_date = STR_TO_DATE(order_date, '%d-%m-%Y')
WHERE order_date IS NULL AND order_id IN (1002, 1006);

UPDATE orders_cleaned
SET order_date = STR_TO_DATE('2023-07-13', '%Y-%m-%d')
WHERE order_id = 1004;  -- Invalid date '2023-13-07' corrected

-- I calculated total revenue from valid transactions.
SELECT SUM(amount) AS total_revenue
FROM orders_cleaned
WHERE amount IS NOT NULL AND amount > 0;


-- I summarized how many orders each country has.
-- This can reveal major market segments or regional activity.
SELECT country, COUNT(*) AS total_orders, ROUND(SUM(amount), 2) AS total_sales
FROM orders_cleaned
GROUP BY country
ORDER BY total_sales DESC;



-- I identified the top 5 customers based on total spend.
-- This would be useful in any CRM or marketing scenario.
SELECT customer_name, email, SUM(amount) AS total_spent
FROM orders_cleaned
GROUP BY customer_name, email
ORDER BY total_spent DESC
LIMIT 5;
-- I looked at how much revenue was generated per day.
-- This kind of temporal trend is useful for reporting and forecasting.
SELECT order_date, COUNT(*) AS num_orders, SUM(amount) AS total_sales
FROM orders_cleaned
WHERE amount IS NOT NULL
GROUP BY order_date
ORDER BY order_date;
-- I checked for rows with missing or invalid data even after cleaning.
-- These would either need manual review or exclusion from analysis.
SELECT *
FROM orders_cleaned
WHERE amount IS NULL OR email IS NULL OR order_date IS NULL OR customer_name IS NULL;
