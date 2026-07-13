-- Production-ready MySQL 8.0 schema for Smart Supermarket Ordering and Billing System

CREATE DATABASE IF NOT EXISTS smart_supermarket
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE smart_supermarket;

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
  role_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  user_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id INT UNSIGNED NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(32) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (role_id) REFERENCES roles(role_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
  customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL UNIQUE,
  loyalty_number VARCHAR(50) UNIQUE,
  preferred_language VARCHAR(32) NOT NULL DEFAULT 'English',
  marketing_opt_in TINYINT(1) NOT NULL DEFAULT 0,
  date_of_birth DATE NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Employees table
CREATE TABLE IF NOT EXISTS employees (
  employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL UNIQUE,
  employee_code VARCHAR(50) NOT NULL UNIQUE,
  department VARCHAR(100) NOT NULL,
  hire_date DATE NOT NULL,
  title VARCHAR(100),
  manager_id INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Admins table
CREATE TABLE IF NOT EXISTS admins (
  admin_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL UNIQUE,
  admin_level ENUM('super', 'manager', 'auditor') NOT NULL DEFAULT 'manager',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Suppliers table
CREATE TABLE IF NOT EXISTS suppliers (
  supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(200) NOT NULL UNIQUE,
  contact_name VARCHAR(150),
  contact_email VARCHAR(255),
  contact_phone VARCHAR(32),
  address TEXT,
  website VARCHAR(255),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parent_category_id INT UNSIGNED NULL,
  name VARCHAR(150) NOT NULL UNIQUE,
  description TEXT,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  sort_order INT UNSIGNED NOT NULL DEFAULT 100,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Products table
CREATE TABLE IF NOT EXISTS products (
  product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id INT UNSIGNED NOT NULL,
  supplier_id INT UNSIGNED NULL,
  barcode VARCHAR(64) NOT NULL UNIQUE,
  sku VARCHAR(64) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  retail_price DECIMAL(10,2) NOT NULL CHECK (retail_price >= 0),
  tax_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00 CHECK (tax_rate >= 0),
  weight_grams INT UNSIGNED NULL,
  volume_ml INT UNSIGNED NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FULLTEXT KEY idx_products_fulltext (name, description)
) ENGINE=InnoDB;

-- Product updates table
CREATE TABLE IF NOT EXISTS product_updates (
  product_update_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  admin_id INT UNSIGNED NOT NULL,
  change_type ENUM('Price', 'Inventory', 'Metadata', 'Category', 'Status') NOT NULL,
  change_notes TEXT NULL,
  previous_value JSON NULL,
  new_value JSON NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (admin_id) REFERENCES admins(admin_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  INDEX idx_product_updates_product (product_id),
  INDEX idx_product_updates_admin (admin_id)
) ENGINE=InnoDB;

-- Product Images table
CREATE TABLE IF NOT EXISTS product_images (
  product_image_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  image_url VARCHAR(512) NOT NULL,
  alt_text VARCHAR(255),
  sort_order INT UNSIGNED NOT NULL DEFAULT 1,
  is_primary TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX idx_product_images_product (product_id),
  INDEX idx_product_images_primary (product_id, is_primary),
  CHECK (is_primary IN (0, 1))
) ENGINE=InnoDB;

-- Inventory table
CREATE TABLE IF NOT EXISTS inventory (
  inventory_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL UNIQUE,
  stock_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  reserved_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  reorder_threshold INT UNSIGNED NOT NULL DEFAULT 10,
  restock_target INT UNSIGNED NOT NULL DEFAULT 50,
  last_stocked_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Discounts table
CREATE TABLE IF NOT EXISTS discounts (
  discount_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  discount_code VARCHAR(64) UNIQUE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  discount_percent TINYINT UNSIGNED NOT NULL CHECK (discount_percent BETWEEN 1 AND 100),
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_by_admin_id INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (created_by_admin_id) REFERENCES admins(admin_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CHECK (end_at > start_at)
) ENGINE=InnoDB;

-- Coupons table
CREATE TABLE IF NOT EXISTS coupons (
  coupon_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  coupon_code VARCHAR(64) NOT NULL UNIQUE,
  description VARCHAR(255),
  discount_percent TINYINT UNSIGNED NOT NULL CHECK (discount_percent BETWEEN 1 AND 100),
  fixed_amount DECIMAL(10,2) NULL CHECK (fixed_amount >= 0),
  minimum_order_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (minimum_order_amount >= 0),
  max_redemptions INT UNSIGNED NOT NULL DEFAULT 0,
  redeemed_count INT UNSIGNED NOT NULL DEFAULT 0,
  start_at DATETIME NOT NULL,
  end_at DATETIME NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (discount_percent > 0 OR fixed_amount IS NOT NULL),
  CHECK (end_at > start_at)
) ENGINE=InnoDB;

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  customer_id INT UNSIGNED NOT NULL,
  employee_id INT UNSIGNED NULL,
  coupon_id INT UNSIGNED NULL,
  order_total DECIMAL(12,2) NOT NULL CHECK (order_total >= 0),
  discount_total DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
  tax_total DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (tax_total >= 0),
  grand_total DECIMAL(12,2) NOT NULL CHECK (grand_total >= 0),
  order_status ENUM('Pending', 'Confirmed', 'Preparing', 'Ready', 'Collected', 'Cancelled') NOT NULL DEFAULT 'Pending',
  order_source ENUM('Tablet', 'Mobile', 'Employee', 'Admin') NOT NULL DEFAULT 'Tablet',
  placed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  processed_at DATETIME NULL,
  completed_at DATETIME NULL,
  cancelled_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX idx_orders_customer (customer_id),
  INDEX idx_orders_status (order_status),
  INDEX idx_orders_placed_at (placed_at)
) ENGINE=InnoDB;

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  order_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0),
  discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
  total_price DECIMAL(12,2) NOT NULL CHECK (total_price >= 0),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  UNIQUE KEY uniq_order_product (order_id, product_id),
  INDEX idx_order_items_product (product_id)
) ENGINE=InnoDB;

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
  payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL UNIQUE,
  payment_method ENUM('Cash', 'Card', 'QR', 'Mobile Wallet') NOT NULL,
  payment_status ENUM('Pending', 'Paid', 'Failed', 'Refunded') NOT NULL DEFAULT 'Pending',
  amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
  transaction_reference VARCHAR(255),
  paid_at DATETIME NULL,
  refunded_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX idx_payments_status (payment_status)
) ENGINE=InnoDB;

-- Shopping carts table
CREATE TABLE IF NOT EXISTS shopping_carts (
  cart_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id INT UNSIGNED NULL,
  session_token CHAR(36) NOT NULL UNIQUE,
  cart_status ENUM('Active', 'Abandoned', 'Converted', 'Cleared') NOT NULL DEFAULT 'Active',
  expires_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX idx_shopping_carts_status (cart_status),
  INDEX idx_shopping_carts_customer (customer_id)
) ENGINE=InnoDB;

-- Cart items table
CREATE TABLE IF NOT EXISTS cart_items (
  cart_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cart_id INT UNSIGNED NOT NULL,
  product_id INT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL CHECK (quantity > 0),
  added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cart_id) REFERENCES shopping_carts(cart_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  UNIQUE KEY uniq_cart_product (cart_id, product_id),
  INDEX idx_cart_items_product (product_id)
) ENGINE=InnoDB;

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  notification_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  customer_id INT UNSIGNED NULL,
  title VARCHAR(200) NOT NULL,
  message TEXT NOT NULL,
  notification_type ENUM('Order', 'Promotional', 'System', 'Inventory') NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  scheduled_at DATETIME NULL,
  sent_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX idx_notifications_user (user_id),
  INDEX idx_notifications_customer (customer_id)
) ENGINE=InnoDB;

-- Order status history table
CREATE TABLE IF NOT EXISTS order_status_history (
  history_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  previous_status ENUM('Pending', 'Confirmed', 'Preparing', 'Ready', 'Collected', 'Cancelled') NOT NULL,
  new_status ENUM('Pending', 'Confirmed', 'Preparing', 'Ready', 'Collected', 'Cancelled') NOT NULL,
  changed_by_user_id INT UNSIGNED NULL,
  changed_by_employee_id INT UNSIGNED NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  notes VARCHAR(255),
  FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (changed_by_employee_id) REFERENCES employees(employee_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX idx_order_status_history_order (order_id)
) ENGINE=InnoDB;

-- Sales reports table
CREATE TABLE IF NOT EXISTS sales_reports (
  report_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  report_date DATE NOT NULL,
  report_type ENUM('Daily', 'Weekly', 'Monthly', 'Quarterly', 'Annual') NOT NULL,
  total_orders INT UNSIGNED NOT NULL DEFAULT 0,
  total_revenue DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_discount DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_tax DECIMAL(14,2) NOT NULL DEFAULT 0,
  total_items_sold INT UNSIGNED NOT NULL DEFAULT 0,
  top_selling_category_id INT UNSIGNED NULL,
  top_selling_product_id INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (top_selling_category_id) REFERENCES categories(category_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (top_selling_product_id) REFERENCES products(product_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  UNIQUE KEY uniq_sales_report_period (report_date, report_type)
) ENGINE=InnoDB;

-- Login sessions table
CREATE TABLE IF NOT EXISTS login_sessions (
  session_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  session_token CHAR(36) NOT NULL UNIQUE,
  device_type ENUM('Tablet', 'Mobile', 'Web', 'Kiosk') NOT NULL,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(512) NULL,
  login_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_seen_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  INDEX idx_login_sessions_user (user_id),
  INDEX idx_login_sessions_active (is_active)
) ENGINE=InnoDB;

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NULL,
  admin_id INT UNSIGNED NULL,
  action_type VARCHAR(100) NOT NULL,
  action_target VARCHAR(100) NULL,
  target_id VARCHAR(100) NULL,
  description TEXT,
  event_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(512) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  FOREIGN KEY (admin_id) REFERENCES admins(admin_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  INDEX idx_audit_logs_user (user_id),
  INDEX idx_audit_logs_admin (admin_id),
  INDEX idx_audit_logs_event_time (event_time)
) ENGINE=InnoDB;
