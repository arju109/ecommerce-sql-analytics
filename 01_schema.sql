-- ============================================================
-- E-COMMERCE SALES ANALYTICS PROJECT
-- File: 01_schema.sql
-- Purpose: Database schema (DDL) for an e-commerce sales system
-- Engine: SQLite (syntax is 95% portable to MySQL/PostgreSQL)
-- ============================================================

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

-- ------------------------------------------------------------
-- CUSTOMERS: one row per customer
-- ------------------------------------------------------------
CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    customer_name   TEXT NOT NULL,
    email           TEXT UNIQUE NOT NULL,
    city            TEXT,
    state           TEXT,
    country         TEXT,
    signup_date     DATE NOT NULL,
    customer_segment TEXT CHECK (customer_segment IN ('Consumer','Corporate','Home Office'))
);

-- ------------------------------------------------------------
-- PRODUCTS: one row per product (catalog)
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category        TEXT NOT NULL,
    sub_category    TEXT NOT NULL,
    unit_price      REAL NOT NULL CHECK (unit_price > 0),
    unit_cost       REAL NOT NULL CHECK (unit_cost > 0)
);

-- ------------------------------------------------------------
-- ORDERS: one row per order (order header)
-- ------------------------------------------------------------
CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL,
    order_date      DATE NOT NULL,
    ship_date       DATE,
    ship_mode       TEXT CHECK (ship_mode IN ('Same Day','First Class','Second Class','Standard Class')),
    order_status    TEXT CHECK (order_status IN ('Completed','Cancelled','Returned')),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ------------------------------------------------------------
-- ORDER_ITEMS: one row per product line within an order
-- (this is the fact table for revenue analysis)
-- ------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL,
    product_id      INTEGER NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      REAL NOT NULL,       -- price at time of sale (can differ from catalog due to discount)
    discount        REAL DEFAULT 0 CHECK (discount >= 0 AND discount <= 1),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Helpful indexes for analytical queries
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
