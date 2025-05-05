// all_products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart';
import '../services/routine_provider.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = searchTerm.isEmpty
          ? _allProducts
          : _allProducts.where((product) =>
          product.name.toLowerCase().contains(searchTerm)).toList();
    });
  }

  Future<void> _loadAllProducts() async {
    try {
      final products = await DatabaseHelper.instance.readAllProducts();
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
      debugPrint("Error loading all products: $e");
    }
  }

  void _onProductTap(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsModal(context, product),
    );
  }

  // In the _buildProductCard method, look for the Text widgets for product name and price
// and increase their font size multipliers

  Widget _buildProductCard(Product product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic sizes based on available width
        final cardWidth = constraints.maxWidth;
        final imageHeight = cardWidth * 0.75; // Adjust image aspect ratio
        final padding = cardWidth * 0.03; // Responsive padding

        return GestureDetector(
          onTap: () => _onProductTap(product),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: _buildProductImage(product.imagePath),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: cardWidth * 0.035, // Keeping brand size the same
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: padding * 0.5),
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: cardWidth * 0.055, // Increased from 0.04 to 0.055
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: padding),
                      Text(
                        '£${product.price}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: cardWidth * 0.06, // Increased from 0.045 to 0.06
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String imagePath) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    debugPrint('🖼️ Original image path: $imagePath');

    if (imagePath.isEmpty) {
      return _buildPlaceholder(accentColor, primaryColor);
    }

    // Extract just the filename with extension
    String filenameWithExt = imagePath.split('/').last;
    debugPrint('📂 Extracted filename: $filenameWithExt');

    // First try the exact filename (with timestamp)
    String assetPathWithTimestamp = 'assets/product_images/$filenameWithExt';

    // Then try without timestamp if needed
    String assetPathWithoutTimestamp = 'assets/product_images/${filenameWithExt.split('_').first}.jpg';

    // Try loading with timestamp first
    try {
      return Image.asset(
        assetPathWithTimestamp,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Failed to load with timestamp, trying without...');
          // Fall back to trying without timestamp
          return Image.asset(
            assetPathWithoutTimestamp,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Both attempts failed. Please verify:');
              debugPrint('1. File exists: $filenameWithExt OR ${filenameWithExt.split('_').first}.jpg');
              debugPrint('2. Exact filename matches (including spaces/capitalization)');
              debugPrint('3. pubspec.yaml contains "assets/product_images/"');
              return _buildPlaceholder(accentColor, primaryColor);
            },
          );
        },
      );
    } catch (e) {
      debugPrint('‼️ Exception loading image: $e');
      return _buildPlaceholder(accentColor, primaryColor);
    }
  }

  Widget _buildPlaceholder(Color accentColor, Color primaryColor) {
    return Container(
      color: accentColor.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: primaryColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildProductDetailsModal(BuildContext modalContext, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: _buildProductImage(product.imagePath),
            ),
            const SizedBox(height: 16),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.brand,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '£${product.price}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Skin Concerns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.skinConcerns.map((concern) => Chip(
                label: Text(concern),
                backgroundColor: Colors.pink[50],
                labelStyle: const TextStyle(color: Colors.pink),
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<RoutineProvider>(context, listen: false)
                      .addToRoutine(product);
                  Navigator.pop(modalContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.name} to routine'),
                      backgroundColor: Colors.pink[300],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add to Skincare Routine',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name...',
                prefixIcon: Icon(Icons.search, color: Colors.pink[300]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.pink.shade300, width: 2.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.pink.shade100, width: 1.0),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.pink.shade50,
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
              cursorColor: Colors.pink[400],
              style: TextStyle(color: Colors.black87),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load products'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAllProducts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2, // Responsive column count
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7, // Slightly wider cards
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(_filteredProducts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}