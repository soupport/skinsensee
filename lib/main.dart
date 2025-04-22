import 'package:flutter/material.dart';
import 'package:skinsense/screens/home_screen.dart';
import 'package:skinsense/screens/products_screen.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that all bindings are initialized before the app starts

  // Initialize the database and insert CSV data
  await DatabaseHelper.insertProductsFromCSV(); // Ensure that products are inserted into the database

  runApp(const SkinSenseApp());
}

class SkinSenseApp extends StatelessWidget {
  const SkinSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: Colors.pink,
          secondary: const Color(0xFFFFB6C1),
          background: const Color(0xFFFFF0F5),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          margin: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.pink.withOpacity(0.1),
          labelStyle: const TextStyle(color: Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/products':
            final args = settings.arguments;

            // Handle case where arguments aren't in expected format
            if (args is! Map<String, dynamic>) {
              debugPrint('Invalid arguments type for /products route');
              return MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              );
            }

            // Safely extract and cast arguments with defaults
            final selectedConcerns = (args['selectedConcerns'] as List<dynamic>?)
                ?.whereType<String>()
                .toList() ?? [];

            final products = (args['products'] as List<dynamic>?)
                ?.whereType<Product>()
                .toList() ?? [];

            return MaterialPageRoute(
              builder: (context) => ProductsScreen(
                selectedConcerns: selectedConcerns,
                products: products,
              ),
            );
          default:
            return null;
        }
      },
      onUnknownRoute: (settings) {
        debugPrint('Unknown route: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
    );
  }
}
