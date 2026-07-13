USE smart_supermarket;

INSERT INTO roles (role_name, description) VALUES
  ('Customer', 'End-customer using tablet or mobile apps'),
  ('Employee', 'In-store employee handling orders and inventory'),
  ('Admin', 'Administrative user with reporting and setup access');

INSERT INTO users (role_id, email, password_hash, phone, first_name, last_name) VALUES
  (1, 'rachel@example.com', '$2y$12$hashedpassword1', '+94123456789', 'Rachel', 'Perera'),
  (1, 'sam@example.com', '$2y$12$hashedpassword2', '+94123456780', 'Sam', 'Fernando'),
  (2, 'amal@example.com', '$2y$12$hashedpassword3', '+94123456781', 'Amal', 'Kumar'),
  (3, 'nisha@example.com', '$2y$12$hashedpassword4', '+94123456782', 'Nisha', 'Silva');

INSERT INTO customers (user_id, loyalty_number, preferred_language, marketing_opt_in, date_of_birth) VALUES
  (1, 'LOYALTY-1001', 'English', 1, '1992-05-10'),
  (2, 'LOYALTY-1002', 'Sinhala', 0, '1988-02-14');

INSERT INTO employees (user_id, employee_code, department, hire_date, title) VALUES
  (3, 'EMP-0001', 'Floor Operations', '2024-01-03', 'Order Specialist');

INSERT INTO admins (user_id, admin_level) VALUES
  (4, 'super');

INSERT INTO suppliers (name, contact_name, contact_email, contact_phone, address) VALUES
  ('FreshFields Farms', 'Lakmal Perera', 'lakmal@freshfields.lk', '+94119876543', 'No. 12, Fruit Street, Colombo'),
  ('Daily Grocery Suppliers', 'Mala Senanayake', 'mala@dailygrocery.lk', '+94117765432', 'No. 98, Main Road, Kandy');

INSERT INTO categories (name, description, sort_order) VALUES
  ('Vegetables & Fruits', 'Fresh produce and seasonal fruits', 10),
  ('Grocery', 'Pantry staples and non-perishable essentials', 20),
  ('Beverages', 'Drinks and refreshments', 30),
  ('Household', 'Cleaning and household supplies', 40),
  ('Chilled Foods', 'Refrigerated dairy and ready-to-eat items', 50),
  ('Frozen Foods', 'Frozen foods and ice creams', 60);

INSERT INTO products (category_id, supplier_id, barcode, sku, name, description, unit_price, retail_price, tax_rate, weight_grams) VALUES
  (1, 1, '8901234500012', 'SKU-VF-001', 'Organic Fuji Apples', 'Fresh organic fuji apples.', 320.00, 360.00, 12.00, 150),
  (2, 2, '8901234500029', 'SKU-GR-001', 'Basmati Rice 5kg', 'Premium aromatic basmati rice.', 1380.00, 1480.00, 12.00, NULL),
  (3, 1, '8901234500036', 'SKU-BV-001', 'Sparkling Water 6-Pack', 'Refreshing mineral water.', 260.00, 300.00, 12.00, 600),
  (4, 2, '8901234500043', 'SKU-HH-001', 'All-Purpose Cleaner', 'Multipurpose floor and surface cleaner.', 550.00, 650.00, 12.00, 1000);

INSERT INTO product_images (product_id, image_url, alt_text, sort_order, is_primary) VALUES
  (1, 'https://example.com/images/apple.jpg', 'Organic Fuji Apples', 1, 1),
  (2, 'https://example.com/images/rice.jpg', 'Basmati Rice 5kg', 1, 1),
  (3, 'https://example.com/images/water.jpg', 'Sparkling Water 6-Pack', 1, 1),
  (4, 'https://example.com/images/cleaner.jpg', 'All-Purpose Cleaner', 1, 1);

INSERT INTO inventory (product_id, stock_quantity, reserved_quantity, reorder_threshold, restock_target, last_stocked_at) VALUES
  (1, 120, 3, 20, 100, '2026-07-01 08:30:00'),
  (2, 45, 0, 10, 80, '2026-07-01 09:00:00'),
  (3, 210, 7, 30, 150, '2026-07-01 08:00:00'),
  (4, 80, 2, 20, 60, '2026-07-01 07:45:00');

INSERT INTO coupons (coupon_code, description, discount_percent, minimum_order_amount, max_redemptions, start_at, end_at, is_active) VALUES
  ('SUMMER10', '10% off on orders over Rs.1000', 10, 1000.00, 500, '2026-07-01 00:00:00', '2026-08-31 23:59:59', 1);

INSERT INTO orders (order_number, customer_id, employee_id, coupon_id, order_total, discount_total, tax_total, grand_total, order_status, order_source, placed_at) VALUES
  ('ORD-20260702-0001', 1, 3, 1, 1680.00, 168.00, 181.44, 1693.44, 'Confirmed', 'Tablet', '2026-07-02 10:22:00');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_amount, tax_amount, total_price) VALUES
  (1, 1, 2, 320.00, 32.00, 43.20, 651.20),
  (1, 3, 3, 260.00, 26.00, 38.88, 778.88);

INSERT INTO payments (order_id, payment_method, payment_status, amount, transaction_reference, paid_at) VALUES
  (1, 'Card', 'Paid', 1693.44, 'TXN-20260702-9876', '2026-07-02 10:24:00');
