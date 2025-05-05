import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skinsense/screens/home_screen.dart';
import 'package:skinsense/screens/products_screen.dart';
import 'package:skinsense/screens/profile_page.dart';
import 'package:skinsense/screens/settings.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart';
import 'package:skinsense/services/routine_provider.dart';
import 'package:skinsense/services/theme_provider.dart';
import 'package:skinsense/services/tips_provider.dart';
import 'package:skinsense/screens/all_products_page.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.insertProductsFromCSV();
  runApp(const SkinSenseApp());
}

class SkinSenseApp extends StatelessWidget {
  const SkinSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TipsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SkinSense',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.pink,
                primary: Colors.pink,
                secondary: const Color(0xFFFFB6C1),
                background: const Color(0xFFFFF0F5),
              ),
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
            darkTheme: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.pink,
                brightness: Brightness.dark,
                primary: Colors.pink[300],
                secondary: Colors.pink[200],
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const MainNavigationScreen(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/products':
                  final args = settings.arguments;
                  if (args is! Map<String, dynamic>) {
                    debugPrint('Invalid arguments type for /products route');
                    return MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    );
                  }
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
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AllProductsScreen(), // Replaced ProductsPlaceholderScreen with AllProductsScreen
    const ProfileScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2) {
            Provider.of<RoutineProvider>(context, listen: false).loadRoutine();
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomAppBarTheme.color,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa), // Changed from search to spa icon for products
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}