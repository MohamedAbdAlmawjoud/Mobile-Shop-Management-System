# Mobile-Shop-Management-System

A modern **Desktop Application for Mobile Phone Shop Management**, built with **Flutter Desktop**.

The system is designed to help mobile phone shop owners and employees manage products, sales, inventory, stock movements, and stock counts from one powerful desktop application.

## 🖥️ Platform

This application is designed primarily for:

* 🪟 Windows
* 🍎 macOS
* 🐧 Linux

## 🚀 Features

### 🔐 Authentication

* User login
* Admin and Cashier roles
* Role-based access control

### 📊 Dashboard

* Today's sales
* Total products
* Low-stock products
* Recent sales overview

### 📦 Product Management

* Add products
* Edit products
* Delete products
* Search products by name
* Search products by barcode
* Categorize products
* Track purchase and selling prices
* Manage product quantities

### 🏷️ Category Management

* Add categories
* Edit categories
* Delete categories
* View all categories

### 🛒 Sales / POS

* Search products
* Add products to the cart
* Update quantities
* Remove products from the cart
* Automatic total calculation
* Multiple payment methods
* Complete checkout process
* Automatic stock deduction
* Sales history

### 🔍 Barcode Scanner Support

The application supports standard USB and Bluetooth barcode scanners that work as keyboard input devices.

Workflow:

```text id="g5y7ha"
Barcode Scanner
       ↓
Scan Product
       ↓
Flutter Desktop Application
       ↓
Find Product
       ↓
Add Product to POS Cart
```

### 📦 Inventory Management

* View current stock
* Add new stock
* Track stock movements
* View stock history
* Detect low-stock products

### 📋 Stock Count

* Compare system quantity with actual quantity
* Detect shortages and excess stock
* Create stock adjustments
* Record inventory changes

```text id="6bwnl5"
System Quantity: 10
Actual Quantity: 8

Difference: -2
```

### 📈 Reports

* Sales reports
* Inventory reports
* Low-stock reports
* Stock movement reports
* Stock count reports

---

## 🛠️ Tech Stack

* **Flutter Desktop**
* **Dart**
* **SQLite**
* **Riverpod**

## 🏗️ Architecture

The application follows a modular and scalable architecture:

```text id="t6yxpp"
Desktop UI
     ↓
Riverpod
     ↓
Repository / Service
     ↓
SQLite Database
```

---

## 📁 Project Structure

```text id="n1kds2"
lib/
│
├── core/
│   ├── database/
│   ├── routing/
│   ├── theme/
│   ├── utils/
│   └── constants/
│
├── features/
│   │
│   ├── auth/
│   ├── dashboard/
│   ├── categories/
│   ├── products/
│   ├── sales/
│   ├── inventory/
│   ├── stock_count/
│   ├── reports/
│   └── users/
│
└── main.dart
```

---

## 🗄️ Database Structure

### Users

```text id="ygdk6u"
users
├── id
├── username
├── password
└── role
```

### Categories

```text id="kz4yzx"
categories
├── id
└── name
```

### Products

```text id="d0yqbc"
products
├── id
├── name
├── barcode
├── category_id
├── purchase_price
├── selling_price
└── quantity
```

### Sales

```text id="8z8m3v"
sales
├── id
├── user_id
├── total
├── payment_method
└── created_at
```

### Sale Items

```text id="ul62zx"
sale_items
├── id
├── sale_id
├── product_id
├── quantity
└── price
```

### Stock Movements

```text id="g3wmr2"
stock_movements
├── id
├── product_id
├── type
├── quantity
├── user_id
└── created_at
```

---

## 🔄 Stock Movement Types

```text id="5qmpk4"
STOCK_IN    → New stock added
SALE        → Product sold
ADJUSTMENT  → Manual stock adjustment
```

This allows the system to maintain a complete inventory history.

---

## 🧮 Stock Count Formula

```text id="p2oay5"
Difference = Actual Quantity - System Quantity
```

Example:

```text id="fkm7be"
System Quantity = 10
Actual Quantity = 8

Difference = -2
```

---

## 🛒 Sales Transaction Flow

```text id="yyh7dg"
Search Product
      ↓
Add to Cart
      ↓
Update Quantity
      ↓
Calculate Total
      ↓
Confirm Sale
      ↓
Save Sale
      ↓
Save Sale Items
      ↓
Update Stock
      ↓
Create Stock Movement
```

To keep the database consistent, the sale and stock update should be handled as a single database transaction.

---

## 🚦 Getting Started

### Prerequisites

* Flutter SDK
* Dart SDK
* Flutter Desktop support enabled
* Visual Studio with Windows Desktop Development tools for Windows builds

Check your setup:

```bash id="g2z6vf"
flutter doctor
```

### Clone the Repository

```bash id="m3dn6u"
git clone YOUR_REPOSITORY_URL
```

### Install Dependencies

```bash id="pd24dc"
flutter pub get
```

### Run on Windows

```bash id="bocj7n"
flutter run -d windows
```

---

## 🏗️ Build the Desktop Application

For Windows:

```bash id="v60p6v"
flutter build windows
```

The release application will be generated inside:

```text id="ls43y4"
build/windows/
```

---

## 🧪 Testing Checklist

* [ ] User login
* [ ] Role permissions
* [ ] Product CRUD
* [ ] Category CRUD
* [ ] Barcode scanning
* [ ] POS cart
* [ ] Prevent sales above available stock
* [ ] Inventory updates
* [ ] Stock movements
* [ ] Stock count calculations
* [ ] Reports
* [ ] Database transactions

---

## 🚧 Future Improvements

* [ ] IMEI tracking
* [ ] Invoice printing
* [ ] Backup and restore
* [ ] Supplier management
* [ ] Purchase management
* [ ] Advanced reports
* [ ] Multi-branch support
* [ ] Cloud synchronization

---

## 👨‍💻 Developer

Developed by **Mohamed Ahmed**

**Flutter & Mobile Developer**

---

## 📄 License

This project is currently being developed as a custom desktop management solution.

All rights reserved.
