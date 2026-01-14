-- ============================================
-- PROJECT 1: E-commerce Database Design
-- Focus: Normalization (3NF), Constraints, Indexing, and Security
-- MySQL Workbench Compatible SQL Script
-- ============================================

-- 1. Database Initialization
-- Using utf8mb4 to support multi-byte characters
DROP DATABASE IF EXISTS ecom_portfolio_db;
CREATE DATABASE IF NOT EXISTS ecom_portfolio_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecom_portfolio_db;

-- ============================================
-- 2. User Management Table (Parent Table)
-- ============================================
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    -- Indexing for performance on registration-based queries.
    INDEX idx_reg_date (created_at)
) ENGINE=InnoDB;

-- ============================================
-- 3. Product Catalog Table
-- ============================================
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    description TEXT,
    -- Full-text index for high-performance keyword searching in product descriptions.
    FULLTEXT INDEX idx_desc (description)
) ENGINE=InnoDB;

-- ============================================
-- 4. Orders Table (Child Table)
-- ============================================
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    amount DECIMAL(10, 2),
    -- Foreign Key Constraint to ensure Referencing Integrity (Prevents Orphaned Rows).
    CONSTRAINT fk_orders_users 
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- Composite Index to optimize user-specific order history lookups.
    INDEX idx_user_order (user_id, order_date)
) ENGINE=InnoDB;

-- ============================================
-- 5. Order Items Table (Normalized to 3NF)
-- ============================================
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price > 0),
    -- Foreign Keys
    CONSTRAINT fk_order_items_orders 
        FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_order_items_products 
        FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ============================================
-- 6. Security: Principle of Least Privilege
-- Creating a restricted account for reporting purposes only.
-- ============================================
-- Uncomment the following lines if you have admin privileges:
-- CREATE USER IF NOT EXISTS 'data_analyst'@'localhost' IDENTIFIED BY 'ReadOnly_2026!';
-- GRANT SELECT ON ecom_portfolio_db.* TO 'data_analyst'@'localhost';
-- FLUSH PRIVILEGES;

-- ============================================
-- 7. Insert Sample Data for Testing
-- ============================================

-- Insert Users
INSERT INTO users (username, email, created_at) VALUES
    ('john_doe', 'john.doe@example.com', '2026-01-10 10:00:00'),
    ('jane_smith', 'jane.smith@example.com', '2026-01-11 14:30:00'),
    ('mike_wilson', 'mike.wilson@example.com', '2026-01-12 09:15:00'),
    ('sarah_jones', 'sarah.jones@example.com', '2026-01-13 16:45:00'),
    ('david_brown', 'david.brown@example.com', '2026-01-14 11:20:00');

-- Insert Products
INSERT INTO products (name, price, description) VALUES
    ('Wireless Bluetooth Headphones', 89.99, 'High-quality wireless headphones with noise cancellation and 20-hour battery life'),
    ('Smartphone Case Premium', 29.99, 'Durable and stylish protective case for latest smartphones'),
    ('USB-C Fast Charger', 24.99, 'Quick charge adapter compatible with most modern devices'),
    ('Laptop Backpack', 59.99, 'Water-resistant backpack with padded compartments for laptops up to 17 inches'),
    ('Wireless Mouse', 34.99, 'Ergonomic wireless mouse with adjustable DPI settings'),
    ('Mechanical Keyboard', 129.99, 'RGB backlit mechanical keyboard with Cherry MX switches'),
    ('Portable Power Bank', 49.99, '20000mAh power bank with dual USB ports and fast charging support'),
    ('Webcam HD 1080p', 79.99, 'Full HD webcam with built-in microphone and auto-focus'),
    ('Desk Lamp LED', 39.99, 'Adjustable LED desk lamp with color temperature control'),
    ('Cable Management Kit', 19.99, 'Organize your cables with this complete cable management solution');

-- Insert Orders
INSERT INTO orders (user_id, order_date, status, amount) VALUES
    (1, '2026-01-14 10:30:00', 'completed', 154.98),
    (2, '2026-01-14 11:45:00', 'pending', 89.99),
    (3, '2026-01-14 12:00:00', 'shipped', 24.99),
    (1, '2026-01-14 13:15:00', 'processing', 219.97),
    (4, '2026-01-14 14:30:00', 'completed', 49.99),
    (5, '2026-01-14 15:00:00', 'pending', 129.99),
    (2, '2026-01-14 16:20:00', 'completed', 94.98),
    (3, '2026-01-14 17:00:00', 'processing', 154.98);

-- Insert Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 89.99),
    (1, 5, 1, 34.99),
    (1, 10, 3, 19.99),
    (2, 6, 1, 129.99),
    (3, 3, 1, 24.99),
    (4, 2, 2, 29.99),
    (4, 4, 1, 59.99),
    (4, 9, 1, 39.99),
    (4, 10, 2, 19.99),
    (5, 7, 1, 49.99),
    (6, 6, 1, 129.99),
    (7, 8, 1, 79.99),
    (7, 10, 1, 19.99),
    (8, 1, 1, 89.99),
    (8, 5, 1, 34.99),
    (8, 3, 1, 24.99);

-- ============================================
-- 8. Test Queries to Verify Database Integrity
-- ============================================

-- Query 1: Check all users
SELECT '=== All Users ===' AS section;
SELECT * FROM users;

-- Query 2: Check all products
SELECT '=== All Products ===' AS section;
SELECT * FROM products;

-- Query 3: Check all orders with user information
SELECT '=== Orders with User Info ===' AS section;
SELECT 
    o.order_id,
    u.username,
    o.order_date,
    o.status,
    o.amount
FROM orders o
JOIN users u ON o.user_id = u.user_id
ORDER BY o.order_date DESC;

-- Query 4: Check order details with product information
SELECT '=== Order Items Details ===' AS section;
SELECT 
    o.order_id,
    u.username,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS subtotal
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN users u ON o.user_id = u.user_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_id DESC, oi.order_item_id;

-- Query 5: Test full-text search on products
SELECT '=== Full-text Search Test: wireless ===' AS section;
SELECT * FROM products 
WHERE MATCH(description) AGAINST('wireless' IN NATURAL LANGUAGE MODE);

-- Query 6: Calculate total sales by user
SELECT '=== Total Sales by User ===' AS section;
SELECT 
    u.user_id,
    u.username,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COALESCE(SUM(o.amount), 0) AS total_spent
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username
ORDER BY total_spent DESC;

-- Query 7: Find top selling products
SELECT '=== Top Selling Products ===' AS section;
SELECT 
    p.product_id,
    p.name,
    p.price,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name, p.price
ORDER BY total_revenue DESC;

-- Query 8: Check constraint integrity
SELECT '=== Constraint Check ===' AS section;
SELECT 
    'Total Users' AS metric,
    COUNT(*) AS count
FROM users
UNION ALL
SELECT 'Total Products', COUNT(*) FROM products
UNION ALL
SELECT 'Total Orders', COUNT(*) FROM orders
UNION ALL
SELECT 'Total Order Items', COUNT(*) FROM order_items
UNION ALL
SELECT 'Orders with Users', COUNT(DISTINCT user_id) FROM orders
UNION ALL
SELECT 'Order Items with Products', COUNT(DISTINCT product_id) FROM order_items;

-- ============================================
-- 9. Database Information Summary
-- ============================================
SELECT '=== Database Summary ===' AS section;
SELECT 
    DATABASE() AS database_name,
    VERSION() AS mysql_version,
    NOW() AS current_time;

-- Display table structures
SELECT '=== Table Structures ===' AS section;
SHOW TABLES;
