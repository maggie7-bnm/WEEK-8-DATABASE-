-- ecommerce_schema.sql
-- CREATE DATABASE + full schema for an E-commerce Store
-- MySQL / InnoDB, utf8mb4

DROP DATABASE IF EXISTS ecommerce_store;
CREATE DATABASE ecommerce_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_store;

-- ----------------------------------------------------
-- Table: customers
-- One customer can have many orders (One-to-Many)
-- email is UNIQUE
-- ----------------------------------------------------
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: customer_profiles
-- Example One-to-One with customers (customer_id is UNIQUE FK)
-- ----------------------------------------------------
DROP TABLE IF EXISTS customer_profiles;
CREATE TABLE customer_profiles (
  profile_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL UNIQUE,
  date_of_birth DATE,
  gender ENUM('male','female','other') DEFAULT 'other',
  loyalty_points INT DEFAULT 0,
  avatar_url VARCHAR(512),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: addresses
-- A customer can have multiple addresses (One-to-Many)
-- ----------------------------------------------------
DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  label VARCHAR(50) DEFAULT 'home', -- e.g., home, work
  street VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: suppliers
-- ----------------------------------------------------
DROP TABLE IF EXISTS suppliers;
CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  contact_email VARCHAR(255),
  phone VARCHAR(30),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: categories
-- Hierarchical categories can be implemented with parent_id (optional)
-- ----------------------------------------------------
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  parent_id INT DEFAULT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: products
-- ----------------------------------------------------
DROP TABLE IF EXISTS products;
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  supplier_id INT,
  sku VARCHAR(100) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL CHECK (price >= 0),
  weight_kg DECIMAL(8,3),
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Many-to-Many: product_categories (products <-> categories)
-- ----------------------------------------------------
DROP TABLE IF EXISTS product_categories;
CREATE TABLE product_categories (
  product_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (product_id, category_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: inventory
-- Tracks stock per product (One-to-One-ish per product, or One-to-Many if tracking locations)
-- ----------------------------------------------------
DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (
  inventory_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL UNIQUE,
  quantity INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reorder_level INT NOT NULL DEFAULT 10,
  last_restock TIMESTAMP NULL,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: orders
-- One customer can have many orders (One-to-Many)
-- ----------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  shipping_address_id INT,
  billing_address_id INT,
  order_status ENUM('pending','processing','shipped','delivered','cancelled','refunded') DEFAULT 'pending',
  total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
  placed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: order_items
-- Each order has many items; each item references a product
-- ----------------------------------------------------
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price >= 0),
  item_total DECIMAL(12,2) AS (quantity * unit_price) STORED,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: payments
-- One-to-One or One-to-Many depending on payment splits
-- ----------------------------------------------------
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  payment_method ENUM('card','mpesa','bank_transfer','wallet','cash_on_delivery') NOT NULL,
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('pending','completed','failed','refunded') DEFAULT 'pending',
  transaction_reference VARCHAR(255),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: product_reviews
-- Customers can review products (One-to-Many)
-- ----------------------------------------------------
DROP TABLE IF EXISTS product_reviews;
CREATE TABLE product_reviews (
  review_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  customer_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: coupons
-- Example of discount/coupon table
-- ----------------------------------------------------
DROP TABLE IF EXISTS coupons;
CREATE TABLE coupons (
  coupon_id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  discount_type ENUM('percent','fixed') NOT NULL,
  discount_value DECIMAL(8,2) NOT NULL CHECK (discount_value >= 0),
  expires_at DATETIME,
  active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Table: order_coupons (many-to-many if multiple coupons per order allowed)
-- ----------------------------------------------------
DROP TABLE IF EXISTS order_coupons;
CREATE TABLE order_coupons (
  order_id INT NOT NULL,
  coupon_id INT NOT NULL,
  PRIMARY KEY (order_id, coupon_id),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ----------------------------------------------------
-- Indexes to help queries (non-unique)
-- ----------------------------------------------------
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_inventory_quantity ON inventory(quantity);

-- ----------------------------------------------------
-- Sample view (optional) showing order summary (not required but useful)
-- ----------------------------------------------------
DROP VIEW IF EXISTS vw_order_summary;
CREATE VIEW vw_order_summary AS
SELECT
  o.order_id,
  o.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  o.placed_at,
  o.order_status,
  o.total_amount,
  (SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.order_id) AS item_count
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id;

-- ----------------------------------------------------
-- SAMPLE DATA INSERTS
-- ----------------------------------------------------

-- Customers
INSERT INTO customers (first_name, last_name, email, phone)
VALUES
('Alice', 'Wanjiru', 'alice@example.com', '0712345678'),
('Brian', 'Otieno', 'brian@example.com', '0722334455'),
('Cynthia', 'Mwangi', 'cynthia@example.com', '0733445566');

-- Customer Profiles
INSERT INTO customer_profiles (customer_id, date_of_birth, gender, loyalty_points, avatar_url)
VALUES
(1, '1995-04-12', 'female', 100, 'https://example.com/avatars/alice.png'),
(2, '1992-08-22', 'male', 50, 'https://example.com/avatars/brian.png');

-- Addresses
INSERT INTO addresses (customer_id, label, street, city, state, postal_code, country, is_default)
VALUES
(1, 'home', '123 Kenyatta Ave', 'Nairobi', 'Nairobi', '00100', 'Kenya', TRUE),
(1, 'work', '456 Moi Ave', 'Nairobi', 'Nairobi', '00100', 'Kenya', FALSE),
(2, 'home', '789 Koinange St', 'Kisumu', 'Kisumu', '40100', 'Kenya', TRUE);

-- Suppliers
INSERT INTO suppliers (name, contact_email, phone)
VALUES
('Tech World Ltd', 'sales@techworld.com', '0700001111'),
('Fashion Hub', 'info@fashionhub.com', '0700002222');

-- Categories
INSERT INTO categories (name, description)
VALUES
('Electronics', 'Phones, laptops, and gadgets'),
('Clothing', 'Men and Women apparel'),
('Accessories', 'Bags, belts, watches');

-- Products
INSERT INTO products (supplier_id, sku, name, description, price, weight_kg)
VALUES
(1, 'SKU001', 'iPhone 14', 'Latest Apple iPhone', 120000, 0.180),
(1, 'SKU002', 'HP Laptop', 'Core i7, 16GB RAM', 85000, 2.200),
(2, 'SKU003', 'Denim Jacket', 'Blue unisex jacket', 4500, 1.200);

-- Product Categories
INSERT INTO product_categories (product_id, category_id)
VALUES
(1, 1), -- iPhone in Electronics
(2, 1), -- Laptop in Electronics
(3, 2); -- Jacket in Clothing

-- Inventory
INSERT INTO inventory (product_id, quantity, reorder_level, last_restock)
VALUES
(1, 10, 2, NOW()),
(2, 5, 2, NOW()),
(3, 30, 5, NOW());

-- Orders
INSERT INTO orders (customer_id, shipping_address_id, billing_address_id, order_status, total_amount)
VALUES
(1, 1, 1, 'processing', 124500),
(2, 3, 3, 'pending', 4500);

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES
(1, 1, 1, 120000),  -- Alice bought 1 iPhone
(1, 3, 1, 4500),    -- Alice also bought a Jacket
(2, 3, 1, 4500);    -- Brian bought 1 Jacket

-- Payments
INSERT INTO payments (order_id, payment_method, amount, status, transaction_reference)
VALUES
(1, 'mpesa', 124500, 'completed', 'MPESA12345'),
(2, 'card', 4500, 'pending', 'CARD98765');

-- Reviews
INSERT INTO product_reviews (product_id, customer_id, rating, title, body)
VALUES
(1, 1, 5, 'Best iPhone Ever!', 'Totally worth the price. Camera is 🔥🔥'),
(3, 2, 4, 'Nice Jacket', 'Fits well, quality is good.');

-- Coupons
INSERT INTO coupons (code, description, discount_type, discount_value, expires_at, active)
VALUES
('WELCOME10', '10% off for first order', 'percent', 10.00, '2025-12-31', TRUE),
('FREESHIP', 'Free shipping coupon', 'fixed', 500.00, '2025-06-30', TRUE);

-- Order Coupons
INSERT INTO order_coupons (order_id, coupon_id)
VALUES
(1, 1); -- Alice used WELCOME10

