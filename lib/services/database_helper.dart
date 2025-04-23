import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:skinsense/models/product.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'skinsense.db';
  static const int _dbVersion = 3; // Incremented version for schema fix

  // Table and column names
  static const String tableProducts = 'products';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnBrand = 'brand';
  static const String columnPrice = 'price';
  static const String columnLink = 'link';
  static const String columnIngredients = 'ingredients';
  static const String columnSkinConcerns = 'skinConcerns';
  static const String columnImagePath = 'imagePath';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      onCreate: _onCreate,
      version: _dbVersion,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableProducts(
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnBrand TEXT NOT NULL,
        $columnPrice TEXT NOT NULL,
        $columnLink TEXT NOT NULL,
        $columnIngredients TEXT NOT NULL,
        $columnSkinConcerns TEXT NOT NULL,
        $columnImagePath TEXT NOT NULL
      )
    ''');
  }

  static Future<void> insertProductsFromCSV() async {
    try {
      final db = await database;
      await db.delete(tableProducts); // Clear existing data

      // Load and parse CSV with proper settings
      final csvData = await rootBundle.loadString('assets/skinsense_boots_products.csv');
      final rows = const CsvToListConverter(
        shouldParseNumbers: false,
        allowInvalid: true,
      ).convert(csvData, eol: '\n');

      // Verify we have data (header + at least 1 row)
      if (rows.length <= 1) {
        developer.log('CSV only contains headers or is empty. Rows found: ${rows.length}');
        return;
      }

      // Process headers - exact matching
      final headers = rows[0].map((e) => e.toString().trim()).toList();
      final nameIdx = headers.indexOf('Name');
      final brandIdx = headers.indexOf('Brand');
      final priceIdx = headers.indexOf('Price');
      final linkIdx = headers.indexOf('Link');
      final ingredientsIdx = headers.indexOf('Ingredients');
      final concernsIdx = headers.indexOf('Skin_Concerns');
      final imageIdx = headers.indexOf('Image_path');

      // Validate headers
      if (nameIdx == -1 || brandIdx == -1 || priceIdx == -1 ||
          linkIdx == -1 || ingredientsIdx == -1 || concernsIdx == -1 ||
          imageIdx == -1) {
        developer.log('Missing required columns in CSV. Found headers: $headers');
        return;
      }

      // Insert products in transaction
      int insertedCount = 0;
      await db.transaction((txn) async {
        for (var row in rows.skip(1)) {
          try {
            // Ensure row has enough columns and is not empty
            if (row.length <= imageIdx || row.every((cell) => cell.toString().trim().isEmpty)) {
              continue;
            }

            await txn.insert(tableProducts, {
              columnName: row[nameIdx]?.toString().trim() ?? '',
              columnBrand: row[brandIdx]?.toString().trim() ?? '',
              columnPrice: row[priceIdx]?.toString().trim() ?? '',
              columnLink: row[linkIdx]?.toString().trim() ?? '',
              columnIngredients: row[ingredientsIdx]?.toString().trim() ?? '',
              columnSkinConcerns: row[concernsIdx]?.toString().trim() ?? '',
              columnImagePath: row[imageIdx]?.toString().trim() ?? '',
            });
            insertedCount++;
          } catch (e) {
            developer.log('Error inserting row: ${e.toString()}');
            developer.log('Problematic row data: $row');
          }
        }
      });

      developer.log('Successfully inserted $insertedCount products');
    } catch (e) {
      developer.log('Error in insertProductsFromCSV: ${e.toString()}');
      rethrow;
    }
  }

  static Future<List<Product>> fetchProducts() async {
    final db = await database;
    final products = await db.query(tableProducts);
    return products.map((p) => Product(
      name: p[columnName]?.toString() ?? '',
      brand: p[columnBrand]?.toString() ?? '',
      price: p[columnPrice]?.toString() ?? '',
      link: p[columnLink]?.toString() ?? '',
      ingredients: (p[columnIngredients]?.toString() ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      skinConcerns: (p[columnSkinConcerns]?.toString() ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      imagePath: p[columnImagePath]?.toString() ?? '',
    )).toList();
  }

  static Future<List<Product>> fetchProductsByConcerns(List<String> concerns) async {
    if (concerns.isEmpty) return fetchProducts();

    final db = await database;
    final query = '''
      SELECT * FROM $tableProducts 
      WHERE ${List.filled(concerns.length, '$columnSkinConcerns LIKE ?').join(' OR ')}
    ''';
    final params = concerns.map((c) => '%$c%').toList();

    final products = await db.rawQuery(query, params);
    return products.map((p) => Product(
      name: p[columnName]?.toString() ?? '',
      brand: p[columnBrand]?.toString() ?? '',
      price: p[columnPrice]?.toString() ?? '',
      link: p[columnLink]?.toString() ?? '',
      ingredients: (p[columnIngredients]?.toString() ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      skinConcerns: (p[columnSkinConcerns]?.toString() ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      imagePath: p[columnImagePath]?.toString() ?? '',
    )).toList();
  }

  static Future<List<String>> fetchAllSkinConcerns() async {
    final db = await database;

    // Get all skin concerns strings from the database
    final results = await db.query(
      tableProducts,
      columns: [columnSkinConcerns],
    );

    // Extract all concerns and make them unique
    final allConcerns = <String>{};

    for (final row in results) {
      final concernsStr = row[columnSkinConcerns]?.toString() ?? '';
      developer.log('Raw concerns string: $concernsStr'); // Debug log

      // Handle the string format and split properly
      final concernsList = concernsStr
          .replaceAll('"', '') // Remove any quotation marks
          .split(',')          // Split by commas
          .map((e) => e.trim()) // Trim whitespace
          .where((e) => e.isNotEmpty && e != 'null') // Remove empty entries
          .toList();

      developer.log('Parsed concerns: $concernsList'); // Debug log
      allConcerns.addAll(concernsList);
    }

    final sortedConcerns = allConcerns.toList()..sort();
    developer.log('All unique concerns: $sortedConcerns'); // Debug log
    return sortedConcerns;
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $tableProducts 
        ADD COLUMN $columnImagePath TEXT NOT NULL DEFAULT ""
      ''');
    }
    if (oldVersion < 3) {
      // For any future schema changes
      await db.execute('''
        ALTER TABLE $tableProducts 
        ADD COLUMN $columnImagePath TEXT NOT NULL DEFAULT ""
      ''');
    }
  }

  static Future<int> getProductCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableProducts')
    ) ?? 0;
  }

  static Future<void> deleteDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}