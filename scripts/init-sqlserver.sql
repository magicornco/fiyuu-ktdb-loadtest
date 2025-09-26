-- SQL Server initialization script for load testing

-- Create test database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'testdb')
BEGIN
    CREATE DATABASE testdb;
END
GO

USE testdb;
GO

-- Create users table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='users' AND xtype='U')
BEGIN
    CREATE TABLE users (
        id INT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(50) NOT NULL UNIQUE,
        email NVARCHAR(100) NOT NULL UNIQUE,
        first_name NVARCHAR(50),
        last_name NVARCHAR(50),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        last_login DATETIME2 NULL,
        is_active BIT DEFAULT 1
    );
END
GO

-- Create products table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='products' AND xtype='U')
BEGIN
    CREATE TABLE products (
        id INT IDENTITY(1,1) PRIMARY KEY,
        name NVARCHAR(100) NOT NULL,
        description NVARCHAR(MAX),
        price DECIMAL(10,2) NOT NULL,
        stock_quantity INT DEFAULT 0,
        category_id INT,
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        is_active BIT DEFAULT 1
    );
END
GO

-- Create orders table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='orders' AND xtype='U')
BEGIN
    CREATE TABLE orders (
        id INT IDENTITY(1,1) PRIMARY KEY,
        user_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL DEFAULT 1,
        total_price DECIMAL(10,2) NOT NULL,
        status NVARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
        created_at DATETIME2 DEFAULT GETDATE(),
        updated_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
    );
END
GO

-- Create logs table
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='logs' AND xtype='U')
BEGIN
    CREATE TABLE logs (
        id INT IDENTITY(1,1) PRIMARY KEY,
        message NVARCHAR(MAX) NOT NULL,
        level NVARCHAR(10) DEFAULT 'INFO' CHECK (level IN ('DEBUG', 'INFO', 'WARN', 'ERROR')),
        user_id INT NULL,
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (user_id) REFERENCES users(id)
    );
END
GO

-- Create trigger to update updated_at column
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_users_updated_at')
BEGIN
    EXEC('
    CREATE TRIGGER tr_users_updated_at
    ON users
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE users 
        SET updated_at = GETDATE()
        FROM users u
        INNER JOIN inserted i ON u.id = i.id;
    END
    ');
END
GO

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_products_updated_at')
BEGIN
    EXEC('
    CREATE TRIGGER tr_products_updated_at
    ON products
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE products 
        SET updated_at = GETDATE()
        FROM products p
        INNER JOIN inserted i ON p.id = i.id;
    END
    ');
END
GO

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_orders_updated_at')
BEGIN
    EXEC('
    CREATE TRIGGER tr_orders_updated_at
    ON orders
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE orders 
        SET updated_at = GETDATE()
        FROM orders o
        INNER JOIN inserted i ON o.id = i.id;
    END
    ');
END
GO

-- Insert sample data
IF NOT EXISTS (SELECT 1 FROM users WHERE username = 'john_doe')
BEGIN
    INSERT INTO users (username, email, first_name, last_name) VALUES
    ('john_doe', 'john@example.com', 'John', 'Doe'),
    ('jane_smith', 'jane@example.com', 'Jane', 'Smith'),
    ('bob_wilson', 'bob@example.com', 'Bob', 'Wilson'),
    ('alice_brown', 'alice@example.com', 'Alice', 'Brown'),
    ('charlie_davis', 'charlie@example.com', 'Charlie', 'Davis');
END
GO

IF NOT EXISTS (SELECT 1 FROM products WHERE name = 'Laptop')
BEGIN
    INSERT INTO products (name, description, price, stock_quantity) VALUES
    ('Laptop', 'High-performance laptop', 999.99, 50),
    ('Mouse', 'Wireless mouse', 29.99, 100),
    ('Keyboard', 'Mechanical keyboard', 79.99, 75),
    ('Monitor', '4K monitor', 299.99, 25),
    ('Headphones', 'Noise-cancelling headphones', 199.99, 30);
END
GO

IF NOT EXISTS (SELECT 1 FROM orders WHERE user_id = 1)
BEGIN
    INSERT INTO orders (user_id, product_id, quantity, total_price, status) VALUES
    (1, 1, 1, 999.99, 'delivered'),
    (2, 2, 2, 59.98, 'shipped'),
    (3, 3, 1, 79.99, 'processing'),
    (4, 4, 1, 299.99, 'pending'),
    (5, 5, 1, 199.99, 'delivered');
END
GO

-- Create indexes for better performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_users_username')
BEGIN
    CREATE INDEX idx_users_username ON users(username);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_users_email')
BEGIN
    CREATE INDEX idx_users_email ON users(email);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_orders_user_id')
BEGIN
    CREATE INDEX idx_orders_user_id ON orders(user_id);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_orders_status')
BEGIN
    CREATE INDEX idx_orders_status ON orders(status);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_orders_created_at')
BEGIN
    CREATE INDEX idx_orders_created_at ON orders(created_at);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_logs_created_at')
BEGIN
    CREATE INDEX idx_logs_created_at ON logs(created_at);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_logs_level')
BEGIN
    CREATE INDEX idx_logs_level ON logs(level);
END
GO

PRINT 'SQL Server test database initialization completed successfully!';
