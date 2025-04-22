import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:skinsense/models/product.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class DatabaseHelper {
  static Database? _database;

  // Singleton pattern
  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDatabase();
      return _database!;
    }
  }

  // Initialize the database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'skinsense.db');
    return openDatabase(path, onCreate: (db, version) async {
      await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY,
        name TEXT,
        brand TEXT,
        price TEXT,
        link TEXT,
        skinConcerns TEXT,
        ingredients TEXT  -- Added ingredients column
      )
      ''');
    }, version: 1);
  }

  // Insert products from CSV data
  static Future<void> insertProductsFromCSV() async {
    final Database db = await database;
    final String csvData = await rootBundle.loadString('assets/skinsense_boots_products.csv');
    List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvData);

    for (var row in rowsAsListOfValues.skip(1)) { // Skip the header
      await db.insert('products', {
        'name': row[0],
        'brand': row[1],
        'price': row[2],
        'link': row[3],
        'skinConcerns': row[5], // Corrected column index for Skin_Concerns
        'ingredients': row[4],  // Corrected column index for Ingredients
      });
    }
  }

  // Fetch all products from the database
  static Future<List<Product>> fetchProducts() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    return List.generate(maps.length, (i) {
      return Product(
        name: maps[i]['name'],
        brand: maps[i]['brand'],
        price: maps[i]['price'],
        link: maps[i]['link'],
        skinConcerns: List<String>.from(maps[i]['skinConcerns'].split(',')),
        ingredients: List<String>.from(maps[i]['ingredients'].split(',')),  // Parse ingredients
      );
    });
  }

  // Fetch products that match the selected skin concerns
  static Future<List<Product>> fetchProductsByConcerns(List<String> selectedConcerns) async {
    final Database db = await database;

    // Build the SQL query
    String query = 'SELECT * FROM products WHERE ';
    List<String> concernQueries = [];
    List<String> queryParams = [];

    // Construct query for each selected concern
    for (var concern in selectedConcerns) {
      concernQueries.add('skinConcerns LIKE ?');
      queryParams.add('%$concern%');
    }

    query += concernQueries.join(' OR '); // Using OR to match any of the selected concerns

    // Execute the query
    final List<Map<String, dynamic>> maps = await db.rawQuery(query, queryParams);

    return List.generate(maps.length, (i) {
      return Product(
        name: maps[i]['name'],
        brand: maps[i]['brand'],
        price: maps[i]['price'],
        link: maps[i]['link'],
        skinConcerns: List<String>.from(maps[i]['skinConcerns'].split(',')),
        ingredients: List<String>.from(maps[i]['ingredients'].split(',')),
      );
    });
  }
}
