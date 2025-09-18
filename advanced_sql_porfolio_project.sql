--------------------------------------------------
-- 🛒 E-COMMERCE DATABASE PROJECT
-- Author: [Your Name]
-- Story: I built this project to simulate a small
-- online shop. My goal was to design the schema, 
-- insert realistic sample data, and then run SQL 
-- analytics to uncover useful business insights.
-------------------------------------------------

-- ------------------------------------------------
-- 0. DROP & RECREATE DATABASE
-- I dropped and recreated the database because 
-- I wanted a clean slate each time I rerun the script.
-- This avoids conflicts with existing tables or data.
-- ------------------------------------------------
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- ------------------------------------------------
-- 1. CREATE TABLES
-- I designed normalized tables to represent real-world 
-- e-commerce data: customers, products, orders, 
-- order items, and payments. 
-- This structure mirrors how online shops actually work.
-- ------------------------------------------------

-- Customers: I store basic customer info with unique emails
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products: I track product details including stock levels
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL CHECK (stock >= 0)
);

-- Orders: I link customers to their purchases
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PENDING',
    total_amount DECIMAL(10,2) NOT NULL
);

-- Order Items: I added this to handle multi-product orders
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL
);

-- Payments: I store payment details to track transactions
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50),
    status VARCHAR(20) DEFAULT 'SUCCESS'
);

-- ------------------------------------------------
-- 2. INSERT SAMPLE DATA
-- I inserted 5 customers, 5 products, and orders across 
-- Jan–Apr 2023. I chose realistic values so that the 
-- analytics queries later would reveal meaningful insights.
-- ------------------------------------------------

-- Customers
INSERT INTO customers (full_name, email) VALUES
('Alice Johnson', 'alice@example.com'),
('Bob Smith', 'bob@example.com'),
('Charlie Brown', 'charlie@example.com'),
('Diana Prince', 'diana@example.com'),
('Ethan Hunt', 'ethan@example.com');

-- Products
INSERT INTO products (product_name, category, price, stock) VALUES
('Laptop', 'Electronics', 1200.00, 10),
('Smartphone', 'Electronics', 800.00, 20),
('Headphones', 'Accessories', 150.00, 50),
('Office Chair', 'Furniture', 300.00, 15),
('Desk Lamp', 'Furniture', 50.00, 30);

-- Orders
INSERT INTO orders (customer_id, total_amount, order_date) VALUES
(1, 1350.00, '2023-01-05'),
(2, 2000.00, '2023-01-20'),
(3, 800.00, '2023-02-12'),
(4, 150.00, '2023-03-01'),
(5, 350.00, '2023-03-15'),
(1, 300.00, '2023-04-05'),
(2, 950.00, '2023-04-12');

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1200.00),   -- Laptop
(1, 3, 1, 150.00),    -- Headphones
(2, 1, 1, 1200.00),   -- Laptop
(2, 2, 1, 800.00),    -- Smartphone
(3, 2, 1, 800.00),    -- Smartphone
(4, 3, 1, 150.00),    -- Headphones
(5, 4, 1, 300.00),    -- Office Chair
(5, 5, 1, 50.00),     -- Desk Lamp
(6, 3, 2, 150.00),    -- Headphones
(7, 2, 1, 800.00),    -- Smartphone
(7, 5, 3, 50.00);     -- Desk Lamp

-- Payments
INSERT INTO payments (order_id, amount, payment_method, payment_date) VALUES
(1, 1350.00, 'Credit Card', '2023-01-06'),
(2, 2000.00, 'PayPal', '2023-01-22'),
(3, 800.00, 'Credit Card', '2023-02-13'),
(4, 150.00, 'Debit Card', '2023-03-02'),
(5, 350.00, 'Credit Card', '2023-03-16'),
(6, 300.00, 'Credit Card', '2023-04-06'),
(7, 950.00, 'Debit Card', '2023-04-13');

-------------------------------------------------
-- CUSTOMER & ORDER ANALYTICS
-------------------------------------------------

-- 1. I found the top 5 customers by spending 
-- because I wanted to identify who brings in 
-- the most revenue.
WITH CustomerSpending AS (
    SELECT 
        c.customer_id,
        c.full_name,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name
),
RankedSpending AS (
    SELECT 
        customer_id,
        full_name,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_num
    FROM CustomerSpending
)
SELECT 
    customer_id,
    full_name,
    total_spent,
    rank_num
FROM RankedSpending
WHERE rank_num <= 5
ORDER BY total_spent DESC;

-- 2. I compared each order to the customer’s average 
-- because I wanted to highlight unusually large purchases.
WITH AvgOrderValue AS (
    SELECT 
        customer_id,
        AVG(total_amount) AS avg_order_value
    FROM orders
    GROUP BY customer_id
)
SELECT 
    o.order_id,
    o.customer_id,
    o.total_amount,
    a.avg_order_value
FROM orders o
JOIN AvgOrderValue a 
    ON o.customer_id = a.customer_id
WHERE o.total_amount > a.avg_order_value
ORDER BY o.customer_id, o.total_amount DESC;

-- 3. I calculated days between purchases using LAG() 
-- because I wanted to measure customer purchase frequency.
SELECT
    o.customer_id,
    c.full_name,
    o.order_id,
    o.order_date,
    LAG(o.order_date) OVER (
        PARTITION BY o.customer_id 
        ORDER BY o.order_date
    ) AS prev_order_date,
    DATEDIFF(
        DAY,
        LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date),
        o.order_date
    ) AS days_between
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_date;

-- 4. I listed customers who spent more than the average 
-- because I wanted to find the most valuable segment.
WITH CustomerSpending AS (
    SELECT 
        c.customer_id,
        c.full_name,
        SUM(o.total_amount) AS total_spent
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.full_name
),
AvgSpending AS (
    SELECT AVG(total_spent) AS avg_spent
    FROM CustomerSpending
)
SELECT 
    cs.customer_id,
    cs.full_name,
    cs.total_spent
FROM CustomerSpending cs
CROSS JOIN AvgSpending a
WHERE cs.total_spent > a.avg_spent
ORDER BY cs.total_spent DESC;

-- 5. I extracted first and last order dates 
-- because I wanted to map customer lifetime timelines.
WITH CustomerOrders AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.full_name,
    co.first_order_date,
    co.last_order_date
FROM customers c
JOIN CustomerOrders co 
    ON c.customer_id = co.customer_id
ORDER BY c.customer_id;

-------------------------------------------------
-- SALES & TIME ANALYSIS
-------------------------------------------------

-- 6. I calculated monthly sales with cumulative totals 
-- because I wanted to track revenue growth over time.
WITH MonthlySales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(total_amount) AS monthly_total
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    monthly_total,
    SUM(monthly_total) OVER (ORDER BY month) AS running_cumulative
FROM MonthlySales
ORDER BY month;

-- 7. I calculated month-over-month growth % 
-- because I wanted to measure performance trends.
WITH MonthlySales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(total_amount) AS monthly_total
    FROM orders
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    monthly_total,
    LAG(monthly_total) OVER (ORDER BY month) AS prev_month_total,
    ROUND(
        ( (monthly_total - LAG(monthly_total) OVER (ORDER BY month)) 
          / LAG(monthly_total) OVER (ORDER BY month) ) * 100,
        2
    ) AS growth_percentage
FROM MonthlySales
ORDER BY month;

-- 8. I split orders into quartiles with NTILE(4) 
-- because I wanted to classify spending levels.
SELECT 
    order_id,
    customer_id,
    total_amount,
    order_date,
    NTILE(4) OVER (ORDER BY total_amount DESC) AS order_value_quartile
FROM orders
ORDER BY total_amount DESC;

-- 9. I used ROW_NUMBER to find the largest order 
-- each month because it shows which customer made 
-- the biggest purchase in that period.
SELECT
    order_id,
    customer_id,
    customer_name,
    total_amount,
    order_date
FROM (
    SELECT 
        o.order_id,
        o.customer_id,
        c.full_name AS customer_name,
        o.total_amount,
        o.order_date,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', o.order_date)
            ORDER BY o.total_amount DESC
        ) AS rn
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
) ranked
WHERE rn = 1
ORDER BY order_date;

-- 10. I compared each order to the monthly average 
-- because I wanted to see which orders stood out 
-- as above or below normal spending.
SELECT 
    o.order_id,
    o.customer_id,
    c.full_name AS customer_name,
    o.order_date,
    o.total_amount,
    monthly_stats.monthly_avg,
    o.total_amount - monthly_stats.monthly_avg AS diff_from_avg
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN (
    SELECT 
        DATE_TRUNC('month', order_date) AS order_month,
        AVG(total_amount) AS monthly_avg
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
) monthly_stats
    ON DATE_TRUNC('month', o.order_date) = monthly_stats.order_month
ORDER BY o.order_date;
