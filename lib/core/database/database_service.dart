import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Central SQLite access point. Every repository goes through this —
/// never open a raw database connection anywhere else.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static const String _dbFileName = 'mobile_shop.db';
  static const int _dbVersion = 3;

  Future<Database>? _databaseFuture;

  Future<Database> get database => _databaseFuture ??= _initDatabase();

  /// Full path to the database file on disk — used by BackupService so the
  /// path logic lives in exactly one place.
  Future<String> get dbFilePath async {
    final dir = await getApplicationSupportDirectory();
    return join(dir.path, _dbFileName);
  }

  Future<Database> _initDatabase() async {
    // Required once per process before using sqflite_common_ffi.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    final dbPath = join(dir.path, _dbFileName);

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onConfigure: (db) async {
          // Enforce FK constraints (off by default in SQLite).
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'cashier')),
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        price REAL NOT NULL CHECK (price >= 0),
        quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
        is_imei_tracked INTEGER NOT NULL DEFAULT 0 CHECK (is_imei_tracked IN (0, 1)),
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (category_id) REFERENCES categories (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        total REAL NOT NULL CHECK (total >= 0),
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        unit_price REAL NOT NULL CHECK (unit_price >= 0),
        FOREIGN KEY (sale_id) REFERENCES sales (id)
          ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('STOCK_IN', 'SALE', 'ADJUSTMENT')),
        quantity_change INTEGER NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (product_id) REFERENCES products (id)
          ON DELETE RESTRICT,
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE product_imeis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        imei TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'in_stock' CHECK (status IN ('in_stock', 'sold')),
        sale_id INTEGER,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (product_id) REFERENCES products (id)
          ON DELETE RESTRICT,
        FOREIGN KEY (sale_id) REFERENCES sales (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        total REAL NOT NULL CHECK (total >= 0),
        notes TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
          ON DELETE RESTRICT,
        FOREIGN KEY (user_id) REFERENCES users (id)
          ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        unit_cost REAL NOT NULL CHECK (unit_cost >= 0),
        FOREIGN KEY (purchase_id) REFERENCES purchases (id)
          ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
          ON DELETE RESTRICT
      )
    ''');

    // Helpful indexes for common lookups.
    await db.execute(
      'CREATE INDEX idx_products_category ON products (category_id)',
    );
    await db.execute('CREATE INDEX idx_products_barcode ON products (barcode)');
    await db.execute(
      'CREATE INDEX idx_sale_items_sale ON sale_items (sale_id)',
    );
    await db.execute(
      'CREATE INDEX idx_stock_movements_product ON stock_movements (product_id)',
    );
    await db.execute(
      'CREATE INDEX idx_product_imeis_product ON product_imeis (product_id)',
    );
    await db.execute(
      'CREATE INDEX idx_product_imeis_status ON product_imeis (status)',
    );
    await db.execute(
      'CREATE INDEX idx_purchases_supplier ON purchases (supplier_id)',
    );
    await db.execute(
      'CREATE INDEX idx_purchase_items_purchase ON purchase_items (purchase_id)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN is_imei_tracked INTEGER NOT NULL DEFAULT 0 '
        'CHECK (is_imei_tracked IN (0, 1))',
      );
      await db.execute('''
        CREATE TABLE product_imeis (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          imei TEXT NOT NULL UNIQUE,
          status TEXT NOT NULL DEFAULT 'in_stock' CHECK (status IN ('in_stock', 'sold')),
          sale_id INTEGER,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (product_id) REFERENCES products (id)
            ON DELETE RESTRICT,
          FOREIGN KEY (sale_id) REFERENCES sales (id)
            ON DELETE RESTRICT
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_product_imeis_product ON product_imeis (product_id)',
      );
      await db.execute(
        'CREATE INDEX idx_product_imeis_status ON product_imeis (status)',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE suppliers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          email TEXT,
          address TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
      await db.execute('''
        CREATE TABLE purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          total REAL NOT NULL CHECK (total >= 0),
          notes TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          FOREIGN KEY (supplier_id) REFERENCES suppliers (id)
            ON DELETE RESTRICT,
          FOREIGN KEY (user_id) REFERENCES users (id)
            ON DELETE RESTRICT
        )
      ''');
      await db.execute('''
        CREATE TABLE purchase_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          purchase_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL CHECK (quantity > 0),
          unit_cost REAL NOT NULL CHECK (unit_cost >= 0),
          FOREIGN KEY (purchase_id) REFERENCES purchases (id)
            ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products (id)
            ON DELETE RESTRICT
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_purchases_supplier ON purchases (supplier_id)',
      );
      await db.execute(
        'CREATE INDEX idx_purchase_items_purchase ON purchase_items (purchase_id)',
      );
    }
  }

  Future<void> close() async {
    final opening = _databaseFuture;
    if (opening == null) return;

    final db = await opening;
    await db.close();
    if (identical(_databaseFuture, opening)) {
      _databaseFuture = null;
    }
  }
}
