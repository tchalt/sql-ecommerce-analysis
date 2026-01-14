-- ============================================
-- PROJECT 2: Performance Best Practices & KPI Reporting
-- Focus: Advanced Analytics (CTEs, Window Functions) and Query Optimization
-- MySQL Workbench Compatible SQL Script
-- ============================================

-- 1. Database Setup (Reuse existing database)
USE ecom_portfolio_db;

-- ============================================
-- 2. Enhance Users Table with City Field
-- Compatible with MySQL 5.7+ (IF NOT EXISTS not supported in ALTER TABLE for older versions)
-- ============================================
SET @column_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'ecom_portfolio_db'
      AND TABLE_NAME = 'users'
      AND COLUMN_NAME = 'city'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE users ADD COLUMN city VARCHAR(50) DEFAULT ''Unknown''',
    'SELECT ''Column city already exists'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update users with city information
UPDATE users SET city = 'New York' WHERE user_id = 1;
UPDATE users SET city = 'Los Angeles' WHERE user_id = 2;
UPDATE users SET city = 'New York' WHERE user_id = 3;
UPDATE users SET city = 'Chicago' WHERE user_id = 4;
UPDATE users SET city = 'Los Angeles' WHERE user_id = 5;

-- ============================================
-- 3. Add Index for Order Date (if not exists)
-- Compatible with MySQL 5.7+ (IF NOT EXISTS not supported in DROP INDEX for older versions)
-- ============================================
SET @index_exists = (
    SELECT COUNT(*)
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = 'ecom_portfolio_db'
      AND TABLE_NAME = 'orders'
      AND INDEX_NAME = 'idx_order_date'
);

SET @sql = IF(@index_exists > 0,
    'DROP INDEX idx_order_date ON orders',
    'SELECT ''Index idx_order_date does not exist'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Create the index
CREATE INDEX idx_order_date ON orders(order_date);

-- ============================================
-- 4. Insert Additional Order Data for 2026
-- ============================================
INSERT INTO orders (user_id, order_date, status, amount) VALUES
    -- 2026-01 orders
    (1, '2026-01-01 09:30:00', 'completed', 159.99),
    (2, '2026-01-02 14:20:00', 'completed', 89.99),
    (3, '2026-01-03 10:15:00', 'completed', 124.99),
    (4, '2026-01-04 16:45:00', 'completed', 249.98),
    (5, '2026-01-05 11:30:00', 'completed', 79.99),
    (1, '2026-01-06 13:20:00', 'completed', 199.99),
    (2, '2026-01-07 15:10:00', 'pending', 54.99),
    (3, '2026-01-08 09:45:00', 'completed', 179.99),
    (4, '2026-01-09 14:00:00', 'shipped', 129.99),
    (5, '2026-01-10 10:30:00', 'completed', 99.99),
    -- 2026-02 orders
    (1, '2026-02-01 11:20:00', 'completed', 239.98),
    (2, '2026-02-02 16:40:00', 'completed', 149.99),
    (3, '2026-02-03 08:55:00', 'completed', 189.99),
    (4, '2026-02-04 12:30:00', 'completed', 269.98),
    (5, '2026-02-05 15:15:00', 'completed', 119.99),
    -- Additional orders for variety
    (1, '2026-01-15 10:00:00', 'completed', 154.98),
    (2, '2026-01-18 14:30:00', 'completed', 94.98),
    (3, '2026-01-20 09:00:00', 'completed', 134.99),
    (4, '2026-01-22 13:15:00', 'completed', 289.98),
    (5, '2026-01-25 16:45:00', 'completed', 109.99),
    (1, '2026-01-28 11:20:00', 'completed', 174.99),
    (2, '2026-01-30 14:00:00', 'completed', 124.99),
    (3, '2026-02-10 09:30:00', 'completed', 199.99),
    (4, '2026-02-12 15:20:00', 'completed', 309.98),
    (5, '2026-02-15 12:10:00', 'completed', 139.99);

-- ============================================
-- 5. Advanced Analytics: Top 2 Spending Users per City
-- Leveraging CTEs (Common Table Expressions) for improved readability and modularity.
-- ============================================
SELECT '=== Top 2 Spending Users per City ===' AS section;

WITH UserSpending AS (
    SELECT 
        u.user_id,
        u.username,
        u.city,
        SUM(o.amount) as total_spent
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    WHERE o.status = 'completed'
    GROUP BY u.user_id, u.city
),
RankedSpending AS (
    SELECT 
        *,
        -- Using Window Function to rank users within each city partition.
        DENSE_RANK() OVER(PARTITION BY city ORDER BY total_spent DESC) as spend_rank
    FROM UserSpending
)
SELECT 
    city,
    username,
    total_spent,
    spend_rank
FROM RankedSpending 
WHERE spend_rank <= 2
ORDER BY city, spend_rank;

-- ============================================
-- 6. Query Optimization Case Study
-- SCENARIO: Optimizing a query that retrieves orders from the year 2026.
-- ============================================

-- [ANTI-PATTERN]: Using functions on indexed columns (causes Index Ignore/Full Table Scan)
SELECT '=== Anti-Pattern: Using YEAR() function ===' AS section;
EXPLAIN SELECT * FROM orders WHERE YEAR(order_date) = 2026;

-- [BEST PRACTICE]: Using range-based search to trigger Index Range Scan
SELECT '=== Best Practice: Range-based search ===' AS section;
EXPLAIN 
SELECT order_id, user_id, status 
FROM orders 
WHERE order_date >= '2026-01-01' AND order_date < '2027-01-01';

-- Comparison: Actual query execution
SELECT '=== Results: Using YEAR() function ===' AS section;
SELECT COUNT(*) as total_orders, SUM(amount) as total_revenue
FROM orders 
WHERE YEAR(order_date) = 2026 AND status = 'completed';

SELECT '=== Results: Using range-based search ===' AS section;
SELECT COUNT(*) as total_orders, SUM(amount) as total_revenue
FROM orders 
WHERE order_date >= '2026-01-01' AND order_date < '2027-01-01' 
  AND status = 'completed';

-- ============================================
-- 7. Automated Reporting via Database Views
-- Encapsulating complex logic and masking sensitive data for the operations team.
-- ============================================

-- Drop view if exists
DROP VIEW IF EXISTS v_sales_kpi_summary;

-- Create view
CREATE VIEW v_sales_kpi_summary AS
SELECT 
    DATE(order_date) as report_date,
    COUNT(order_id) as total_daily_orders,
    SUM(amount) as total_revenue,
    AVG(amount) as average_order_value
FROM orders
WHERE status = 'completed'
GROUP BY DATE(order_date);

-- Test the view
SELECT '=== Daily Sales KPI Summary ===' AS section;
SELECT * FROM v_sales_kpi_summary ORDER BY report_date;

-- ============================================
-- 8. Additional Advanced Analytics Examples
-- ============================================

-- Example 1: Moving Average of Daily Sales (7-day window)
SELECT '=== 7-Day Moving Average ===' AS section;
WITH DailySales AS (
    SELECT 
        DATE(order_date) as report_date,
        SUM(amount) as daily_revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE(order_date)
)
SELECT 
    report_date,
    daily_revenue,
    AVG(daily_revenue) OVER (
        ORDER BY report_date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) as moving_avg_7day
FROM DailySales
ORDER BY report_date;

-- Example 2: Year-over-Year Comparison
SELECT '=== Year-over-Year Revenue Comparison ===' AS section;
WITH YearlySales AS (
    SELECT 
        YEAR(order_date) as year,
        MONTH(order_date) as month,
        SUM(amount) as monthly_revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY YEAR(order_date), MONTH(order_date)
),
RankedYears AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY year DESC) as year_rank
    FROM YearlySales
)
SELECT 
    month,
    MAX(CASE WHEN year_rank = 1 THEN monthly_revenue END) as current_year,
    MAX(CASE WHEN year_rank = 2 THEN monthly_revenue END) as previous_year,
    (MAX(CASE WHEN year_rank = 1 THEN monthly_revenue END) - 
     MAX(CASE WHEN year_rank = 2 THEN monthly_revenue END)) as revenue_growth
FROM RankedYears
GROUP BY month
ORDER BY month;

-- Example 3: Cumulative Sum Running Total
SELECT '=== Cumulative Revenue (Running Total) ===' AS section;
WITH DailySales AS (
    SELECT 
        DATE(order_date) as report_date,
        SUM(amount) as daily_revenue
    FROM orders
    WHERE status = 'completed'
      AND order_date >= '2026-01-01'
    GROUP BY DATE(order_date)
)
SELECT 
    report_date,
    daily_revenue,
    SUM(daily_revenue) OVER (ORDER BY report_date) as cumulative_revenue
FROM DailySales
ORDER BY report_date;

-- Example 4: Percentile Analysis
SELECT '=== Revenue Percentiles per City ===' AS section;
WITH CitySpending AS (
    SELECT 
        u.city,
        u.username,
        SUM(o.amount) as total_spent
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    WHERE o.status = 'completed'
    GROUP BY u.city, u.username
)
SELECT 
    city,
    username,
    total_spent,
    PERCENT_RANK() OVER (PARTITION BY city ORDER BY total_spent) as percentile_rank,
    NTILE(4) OVER (PARTITION BY city ORDER BY total_spent) as quartile
FROM CitySpending
ORDER BY city, total_spent DESC;

-- Example 5: Lag/Lead Analysis - Compare with Previous/Next Order
SELECT '=== User Order Trends (Lag/Lead) ===' AS section;
WITH UserOrders AS (
    SELECT 
        user_id,
        order_id,
        order_date,
        amount,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) as order_sequence
    FROM orders
    WHERE status = 'completed'
)
SELECT 
    uo.user_id,
    uo.order_date,
    uo.amount as current_order_amount,
    LAG(uo.amount, 1) OVER (PARTITION BY uo.user_id ORDER BY uo.order_date) as previous_order_amount,
    LAG(uo.order_date, 1) OVER (PARTITION BY uo.user_id ORDER BY uo.order_date) as previous_order_date,
    DATEDIFF(uo.order_date, LAG(uo.order_date, 1) OVER (PARTITION BY uo.user_id ORDER BY uo.order_date)) as days_since_last_order
FROM UserOrders uo
WHERE uo.order_sequence > 1
ORDER BY uo.user_id, uo.order_date;

-- ============================================
-- 9. Performance Index Analysis
-- ============================================

-- Show indexes on orders table
SELECT '=== Indexes on Orders Table ===' AS section;
SHOW INDEX FROM orders;

-- Analyze table for optimizer statistics
ANALYZE TABLE orders;

-- Check table size
SELECT 
    TABLE_NAME,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS 'Size (MB)',
    TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ecom_portfolio_db' 
  AND TABLE_NAME = 'orders';

-- ============================================
-- 10. Summary Statistics
-- ============================================
SELECT '=== Database Performance Summary ===' AS section;
SELECT 
    DATABASE() as database_name,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM products) as total_products,
    (SELECT COUNT(*) FROM orders) as total_orders,
    (SELECT COUNT(DISTINCT city) FROM users) as total_cities,
    (SELECT SUM(amount) FROM orders WHERE status = 'completed') as total_revenue,
    (SELECT AVG(amount) FROM orders WHERE status = 'completed') as avg_order_value;

SELECT '=== Optimization Recommendations ===' AS section;
SELECT '1. Use range-based queries instead of functions on indexed columns' as recommendation
UNION ALL
SELECT '2. Create composite indexes for frequently used WHERE and ORDER BY combinations'
UNION ALL
SELECT '3. Use CTEs and window functions for complex analytics queries'
UNION ALL
SELECT '4. Use views to encapsulate complex query logic and improve security'
UNION ALL
SELECT '5. Regularly run ANALYZE TABLE to update optimizer statistics'
UNION ALL
SELECT '6. Monitor query execution plans with EXPLAIN';
