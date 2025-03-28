require 'sqlite3'
require 'mail'
require 'logger'
require 'net/smtp'

# =========================================
# ⚡ WIGGIES AUTOMATED NOTIFICATION SYSTEM ⚡
# =========================================
# 🚀 Automates emails for:
# ✅ Low stock alerts
# ✅ Daily & Monthly sales reports
# ✅ New order confirmations
# ✅ Stock replenishment reminders
# ✅ Customer order notifications

# 📌 Email Configuration (Update your credentials)
EMAIL_SETTINGS = {
  address: "smtp.gmail.com",
  port: 587,
  user_name: "your-email@gmail.com",
  password: "your-email-password",
  authentication: "plain",
  enable_starttls_auto: true
}

# 📌 Recipient Emails
ADMIN_EMAIL = "admin@wiggies.com"
CUSTOMER_EMAIL = "customer@wiggies.com"

# 🔍 Log File Setup
logger = Logger.new("notifications.log")

# =========================================
# 📊 DATABASE SETUP (SQLite for demo)
# =========================================

DB = SQLite3::Database.new "wiggies_inventory.db"

# Create Inventory Table
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS inventory (
    id INTEGER PRIMARY KEY,
    product_name TEXT,
    stock INTEGER,
    reorder_level INTEGER
  );
SQL

# Create Sales Table
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS sales (
    id INTEGER PRIMARY KEY,
    product_name TEXT,
    quantity_sold INTEGER,
    revenue REAL,
    date TEXT
  );
SQL

# Create Orders Table
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY,
    customer_email TEXT,
    product_name TEXT,
    quantity INTEGER,
    order_date TEXT
  );
SQL

# =========================================
# 🛠️ Helper Methods
# =========================================

# 📌 Send Email Notification
def send_email(subject, body, recipient)
  Mail.defaults { delivery_method :smtp, EMAIL_SETTINGS }

  mail = Mail.new do
    from    EMAIL_SETTINGS[:user_name]
    to      recipient
    subject subject
    body    body
  end

  mail.deliver!
  puts "📧 Email Sent: #{subject} to #{recipient}"
end

# 📌 Fetch Low Stock Products & Notify Admin
def check_low_stock(threshold = 5)
  results = DB.execute("SELECT product_name, stock, reorder_level FROM inventory WHERE stock <= ?", threshold)
  return if results.empty?

  message = "⚠️ Low Stock Alert!\n\n"
  results.each do |product, stock, reorder_level|
    reorder_qty = reorder_level - stock
    message += "#{product}: Only #{stock} left! Reorder Suggestion: Order #{reorder_qty} more.\n"
  end
  
  send_email("🚨 Low Stock Alert!", message, ADMIN_EMAIL)
end

# 📌 Generate Daily Sales Report
def generate_sales_report
  today = Time.now.strftime("%Y-%m-%d")
  results = DB.execute("SELECT product_name, SUM(quantity_sold), SUM(revenue) FROM sales WHERE date = ? GROUP BY product_name", today)

  return if results.empty?

  message = "📊 Daily Sales Report for #{today}:\n\n"
  total_revenue = 0

  results.each do |product, quantity, revenue|
    message += "#{product}: Sold #{quantity}, Revenue: $#{revenue}\n"
    total_revenue += revenue
  end

  message += "\n💰 Total Revenue: $#{total_revenue}"
  
  send_email("📈 Daily Sales Report", message, ADMIN_EMAIL)
end

# 📌 Generate Monthly Sales Report
def generate_monthly_sales_report
  month = Time.now.strftime("%Y-%m")
  results = DB.execute("SELECT product_name, SUM(quantity_sold), SUM(revenue) FROM sales WHERE date LIKE ? GROUP BY product_name", "#{month}%")

  return if results.empty?

  message = "📊 Monthly Sales Report for #{month}:\n\n"
  total_revenue = 0

  results.each do |product, quantity, revenue|
    message += "#{product}: Sold #{quantity}, Revenue: $#{revenue}\n"
    total_revenue += revenue
  end

  message += "\n💰 Total Monthly Revenue: $#{total_revenue}"
  
  send_email("📊 Monthly Sales Report", message, ADMIN_EMAIL)
end

# 📌 Notify Customer on New Order
def notify_customer_order(customer_email, product, quantity)
  message = "🎉 Thank you for your order!\n\nProduct: #{product}\nQuantity: #{quantity}\nYour order is being processed."
  send_email("🛒 Your Order Confirmation", message, customer_email)
end

# 📌 Notify Admin on New Order
def notify_admin_new_order(product, quantity)
  message = "🚀 New Order Received!\n\nProduct: #{product}\nQuantity: #{quantity}\n🛍️ Prepare for fulfillment."
  send_email("🛒 New Order Notification", message, ADMIN_EMAIL)
end

# 📌 Log All Transactions
def log_transaction(type, details)
  logger.info("[#{Time.now}] #{type}: #{details}")
end

# =========================================
# 🔄 AUTOMATION (Simulated Data & Scheduler)
# =========================================

# Add dummy inventory data (for testing)
DB.execute("INSERT INTO inventory (product_name, stock, reorder_level) VALUES ('Vanilla Ice Cream', 3, 10)") rescue nil
DB.execute("INSERT INTO inventory (product_name, stock, reorder_level) VALUES ('Chocolate Ice Cream', 12, 20)") rescue nil

# Add dummy sales data (for testing)
DB.execute("INSERT INTO sales (product_name, quantity_sold, revenue, date) VALUES ('Vanilla Ice Cream', 5, 15.00, date('now'))") rescue nil

# Add dummy order data (for testing)
DB.execute("INSERT INTO orders (customer_email, product_name, quantity, order_date) VALUES ('customer@wiggies.com', 'Strawberry Ice Cream', 2, date('now'))") rescue nil

# 🔄 Run Automated Notifications
loop do
  puts "🔄 Checking for notifications..."

  check_low_stock
  generate_sales_report
  generate_monthly_sales_report

  # Simulate new order
  notify_customer_order("customer@wiggies.com", "Strawberry Ice Cream", 2)
  notify_admin_new_order("Strawberry Ice Cream", 2)

  # Log transaction
  log_transaction("Order", "Customer ordered 2x Strawberry Ice Cream")

  puts "⏳ Waiting for next cycle...\n\n"
  sleep(86400) # Run once a day
end
