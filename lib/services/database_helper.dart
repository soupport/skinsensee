import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:skinsense/models/product.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'skinsense.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        price TEXT NOT NULL,
        link TEXT NOT NULL,
        ingredients TEXT NOT NULL,
        skinConcerns TEXT NOT NULL,
        imagePath TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_routine (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE(product_id) ON CONFLICT REPLACE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_routine (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
          UNIQUE(product_id) ON CONFLICT REPLACE
        )
      ''');
    }
  }

  // Product Operations
  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<Product?> readProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User Routine Operations
  Future<int> addToUserRoutine(Product product) async {
    final db = await instance.database;

    // First ensure product exists in main table
    if (product.id == null) {
      final id = await createProduct(product);
      product = product.copyWith(id: id);
    }

    return await db.insert(
      'user_routine',
      {'product_id': product.id},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Product>> fetchUserRoutineProducts() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT p.* FROM products p
      INNER JOIN user_routine ur ON p.id = ur.product_id
      ORDER BY ur.id DESC
    ''');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> removeFromUserRoutine(int productId) async {
    final db = await instance.database;
    return await db.delete(
      'user_routine',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  Future<bool> isInRoutine(int productId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_routine',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return result.isNotEmpty;
  }

  // CSV Import
  Future<void> insertProductsFromCSV() async {
    final db = await database;
    await db.delete('products');

    final csvData = await rootBundle.loadString('assets/skinsense_boots_products.csv');
    final rows = const CsvToListConverter().convert(csvData, eol: '\n');

    if (rows.length <= 1) return; // Only headers or empty

    // Map headers to indices
    final headers = rows[0].map((e) => e.toString().trim()).toList();
    final headerIndices = {
      'Name': headers.indexOf('Name'),
      'Brand': headers.indexOf('Brand'),
      'Price': headers.indexOf('Price'),
      'Link': headers.indexOf('Link'),
      'Ingredients': headers.indexOf('Ingredients'),
      'Skin_Concerns': headers.indexOf('Skin_Concerns'),
      'Image_path': headers.indexOf('Image_path'),
    };

    // Batch insert for performance
    final batch = db.batch();
    for (var row in rows.skip(1)) {
      try {
        if (row.length >= headerIndices.length) {
          final product = Product.fromCsv(row, headerIndices);
          batch.insert('products', product.toMap());
        }
      } catch (e) {
        debugPrint('Error processing row: $e');
      }
    }
    await batch.commit();
  }

  // Search and Filter Operations
  Future<List<Product>> searchProducts(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR brand LIKE ? OR ingredients LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> fetchProductsByConcerns(List<String> concerns) async {
    if (concerns.isEmpty) return readAllProducts();

    final db = await instance.database;
    final whereClause = concerns.map((_) => 'skinConcerns LIKE ?').join(' OR ');
    final whereArgs = concerns.map((c) => '%$c%').toList();

    final result = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<String>> fetchAllSkinConcerns() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT skinConcerns FROM products
    ''');

    final concerns = <String>{};
    for (final row in result) {
      final concernsStr = row['skinConcerns'] as String;
      concerns.addAll(concernsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }

    return concerns.toList()..sort();
  }

  // Utility Methods
  Future<int> getProductCount() async {
    final db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products')
    ) ?? 0;
  }

  Future<List<Product>> fetchRandomProducts(int count) async {
    final db = await instance.database;
    final total = await getProductCount();
    if (total == 0) return [];

    final randomOffset = (total <= count) ? 0 : Random().nextInt(total - count);
    final result = await db.query(
      'products',
      limit: count,
      offset: randomOffset,
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}