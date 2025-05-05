import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import '../services/routine_provider.dart';

class ProductsScreen extends StatefulWidget {
  final List<String> selectedConcerns;
  final List<Product> products;

  const ProductsScreen({
    super.key,
    required this.selectedConcerns,
    required this.products,
  });

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool isMostRecommendedSelected = true;
  late Future<List<Product>> _productsFuture;
  bool _isLoading = false;
  int? _expandedIndex;
  Map<String, String> _ingredientMessages = {};
  String? _selectedIngredient;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadIngredientMessages();
  }

  Future<void> _loadIngredientMessages() async {
    try {
      final String data = await rootBundle.loadString('assets/messages/Ingredient_messages.txt');
      final Map<String, String> messages = {};

      LineSplitter.split(data).forEach((line) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length == 2) {
            final ingredient = parts[0].trim().toLowerCase();
            final message = parts[1].trim();
            messages[ingredient] = message;
          }
        }
      });

      setState(() {
        _ingredientMessages = messages;
      });
    } catch (e) {
      debugPrint('Error loading ingredient messages: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      // Use the existing method to fetch all products
      _productsFuture = DatabaseHelper.instance.readAllProducts();
      await _productsFuture;
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Product> _getMostRecommendedProducts(List<Product> products) {
    return products.where((product) {
      return widget.selectedConcerns.every((concern) =>
          product.skinConcerns.contains(concern));
    }).toList();
  }

  List<Product> _getOtherRecommendedProducts(List<Product> products) {
    return products.where((product) {
      return product.skinConcerns.any((concern) =>
          widget.selectedConcerns.contains(concern));
    }).toList();
  }

  Future<void> _retryLoading() async {
    setState(() => _isLoading = true);
    try {
      // Use the existing method to fetch all products
      final products = await DatabaseHelper.instance.readAllProducts();
      setState(() {
        _productsFuture = Future.value(products);
      });
    } catch (e) {
      debugPrint('Error retrying: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleExpand(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
      _selectedIngredient = null; // Reset selected ingredient when expanding/collapsing
    });
  }

  List<String> _getMatchingIngredients(List<String> productIngredients) {
    final List<String> matches = [];

    for (final ingredient in productIngredients) {
      final ingredientLower = ingredient.toLowerCase();
      if (_ingredientMessages.keys.any((key) => ingredientLower.contains(key))) {
        matches.add(ingredient);
      }
    }

    return matches;
  }

  String? _getIngredientMessage(String ingredient) {
    final ingredientLower = ingredient.toLowerCase();
    for (final entry in _ingredientMessages.entries) {
      if (ingredientLower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  void _toggleIngredient(String ingredient) {
    setState(() {
      _selectedIngredient = _selectedIngredient == ingredient ? null : ingredient;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final responsiveTextScale = screenSize.width / 400; // Base scale factor

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recommended Products',
          style: TextStyle(
            fontSize: isTablet ? 22.0 : 18.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load products',
                    style: TextStyle(fontSize: 18 * responsiveTextScale.clamp(0.8, 1.3)),
                  ),
                  SizedBox(height: 20 * responsiveTextScale.clamp(0.8, 1.2)),
                  ElevatedButton(
                    onPressed: _retryLoading,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                    child: Text(
                      'Retry',
                      style: TextStyle(fontSize: 16 * responsiveTextScale.clamp(0.8, 1.2)),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No products available',
                style: TextStyle(fontSize: 18 * responsiveTextScale.clamp(0.8, 1.3)),
              ),
            );
          }

          final products = snapshot.data!;
          final mostRecommended = _getMostRecommendedProducts(products);
          final otherRecommended = _getOtherRecommendedProducts(products);
          final displayProducts = isMostRecommendedSelected ? mostRecommended : otherRecommended;

          return Column(
            children: [
              Expanded(
                child: _buildProductList(displayProducts, responsiveTextScale, isTablet),
              ),
              Padding(
                padding: EdgeInsets.all(16.0 * responsiveTextScale.clamp(0.8, 1.2)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildToggleButton('Most Recommended', true, responsiveTextScale),
                    _buildToggleButton('Other Recommendations', false, responsiveTextScale),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(String text, bool value, double scale) {
    return ElevatedButton(
      onPressed: () {
        if (isMostRecommendedSelected != value) {
          setState(() {
            isMostRecommendedSelected = value;
            _expandedIndex = null;
            _selectedIngredient = null;
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isMostRecommendedSelected == value ? Colors.pink : Colors.grey,
        padding: EdgeInsets.symmetric(
          horizontal: 12.0 * scale.clamp(0.8, 1.3),
          vertical: 8.0 * scale.clamp(0.8, 1.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14 * scale.clamp(0.8, 1.2)),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, double scale, bool isTablet) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No products found for your selected concerns',
              style: TextStyle(fontSize: 18 * scale.clamp(0.8, 1.3)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20 * scale.clamp(0.8, 1.2)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale.clamp(0.8, 1.2),
                  vertical: 12 * scale.clamp(0.8, 1.2),
                ),
              ),
              child: Text(
                'Back to Selection',
                style: TextStyle(fontSize: 16 * scale.clamp(0.8, 1.2)),
              ),
            ),
          ],
        ),
      );
    }

    // For tablets, use a grid layout instead of a list
    if (isTablet) {
      return GridView.builder(
        padding: EdgeInsets.all(16 * scale.clamp(0.8, 1.2)),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16 * scale.clamp(0.8, 1.2),
          mainAxisSpacing: 16 * scale.clamp(0.8, 1.2),
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductCard(products[index], index, scale, isTablet),
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(16 * scale.clamp(0.8, 1.2)),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductCard(products[index], index, scale, isTablet),
      );
    }
  }

  Widget _buildProductCard(Product product, int index, double scale, bool isTablet) {
    final isExpanded = _expandedIndex == index;
    final cardPadding = 16.0 * scale.clamp(0.8, 1.2);

    // Adjusted for portrait phones: Make image larger with name below it
    final useVerticalLayout = !isTablet && MediaQuery.of(context).size.width < 380;

    return Card(
      margin: EdgeInsets.only(bottom: 16 * scale.clamp(0.8, 1.2)),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleExpand(index),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              useVerticalLayout
                  ? _buildVerticalProductHeader(product, scale)
                  : _buildHorizontalProductHeader(product, scale, isTablet),
              SizedBox(height: 12 * scale.clamp(0.8, 1.2)),
              _buildConcernsChips(product, scale),
              if (isExpanded) ...[
                SizedBox(height: 12 * scale.clamp(0.8, 1.2)),
                _buildMainIngredients(product, scale),
                if (_selectedIngredient != null)
                  _buildIngredientMessage(_selectedIngredient!, scale),
                SizedBox(height: 12 * scale.clamp(0.8, 1.2)),
                if (product.link.isNotEmpty)
                  _buildViewProductButton(product.link, scale),
                SizedBox(height: 12 * scale.clamp(0.8, 1.2)),
                _buildAddToRoutineButton(product, scale),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // New vertical layout for narrow screens
  Widget _buildVerticalProductHeader(Product product, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 120 * scale.clamp(0.8, 1.3),
          height: 120 * scale.clamp(0.8, 1.3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _getImageWidget(product),
          ),
        ),
        SizedBox(height: 12 * scale.clamp(0.8, 1.2)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              product.name,
              style: TextStyle(
                fontSize: 18 * scale.clamp(0.9, 1.3),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4 * scale.clamp(0.8, 1.2)),
            Text(
              'Brand: ${product.brand}',
              style: TextStyle(fontSize: 14 * scale.clamp(0.8, 1.2)),
              textAlign: TextAlign.center,
            ),
            Text(
              'Price: £${product.price}',
              style: TextStyle(
                fontSize: 16 * scale.clamp(0.9, 1.4),
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  // Horizontal layout for wider screens
  Widget _buildHorizontalProductHeader(Product product, double scale, bool isTablet) {
    final imageSize = isTablet ? 100.0 : 80.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: imageSize * scale.clamp(0.8, 1.3),
          height: imageSize * scale.clamp(0.8, 1.3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _getImageWidget(product),
          ),
        ),
        SizedBox(width: 16 * scale.clamp(0.8, 1.2)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  fontSize: (isTablet ? 20 : 18) * scale.clamp(0.9, 1.3),
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              SizedBox(height: 4 * scale.clamp(0.8, 1.2)),
              Text(
                'Brand: ${product.brand}',
                style: TextStyle(fontSize: (isTablet ? 15 : 14) * scale.clamp(0.8, 1.2)),
              ),
              Text(
                'Price: £${product.price}',
                style: TextStyle(
                  fontSize: (isTablet ? 18 : 16) * scale.clamp(0.9, 1.4),
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainIngredients(Product product, double scale) {
    final matchingIngredients = _getMatchingIngredients(product.ingredients);

    if (matchingIngredients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main Ingredients:',
          style: TextStyle(
            fontSize: 16 * scale.clamp(0.8, 1.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8 * scale.clamp(0.8, 1.2)),
        Wrap(
          spacing: 8 * scale.clamp(0.8, 1.2),
          runSpacing: 8 * scale.clamp(0.8, 1.2),
          children: matchingIngredients.map((ingredient) {
            final isSelected = _selectedIngredient == ingredient;
            return ActionChip(
              label: Text(
                ingredient,
                style: TextStyle(
                  fontSize: 13 * scale.clamp(0.8, 1.2),
                  color: isSelected ? Colors.white : Colors.pink,
                ),
              ),
              backgroundColor: isSelected ? Colors.pink : Colors.pink[50],
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scale.clamp(0.8, 1.2),
                vertical: 2 * scale.clamp(0.8, 1.2),
              ),
              onPressed: () => _toggleIngredient(ingredient),
            );
          }).toList(),
        ),
        SizedBox(height: 8 * scale.clamp(0.8, 1.2)),
      ],
    );
  }

  Widget _buildIngredientMessage(String ingredient, double scale) {
    final message = _getIngredientMessage(ingredient);
    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12 * scale.clamp(0.8, 1.2)),
      padding: EdgeInsets.all(12 * scale.clamp(0.8, 1.2)),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink[200]!),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14 * scale.clamp(0.8, 1.2),
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildAddToRoutineButton(Product product, double scale) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            // Get the RoutineProvider and add the product
            final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
            await routineProvider.addToRoutine(product);

            // Show success message for 1 second
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to your routine'),
                  backgroundColor: Colors.pink,
                  duration: const Duration(seconds: 1), // Set duration to 1 second
                ),
              );
            }
          } catch (e) {
            // Show error message if something goes wrong
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add product: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 1), // Set error duration to 1 second too
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[300],
          padding: EdgeInsets.symmetric(
            vertical: 12 * scale.clamp(0.8, 1.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Add to Skincare Routine',
          style: TextStyle(
            fontSize: 16 * scale.clamp(0.8, 1.3),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _getImageWidget(Product product) {
    if (product.imagePath.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    final imageName = product.imagePath.contains('/')
        ? product.imagePath.split('/').last
        : product.imagePath;

    final assetPath = 'assets/product_images/$imageName';

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildConcernsChips(Product product, double scale) {
    return Wrap(
      spacing: 8 * scale.clamp(0.8, 1.2),
      runSpacing: 8 * scale.clamp(0.8, 1.2),
      children: product.skinConcerns.map((concern) => Chip(
        label: Text(
          concern,
          style: TextStyle(
            color: Colors.pink,
            fontSize: 12 * scale.clamp(0.8, 1.2),
          ),
        ),
        backgroundColor: Colors.pink[50],
        padding: EdgeInsets.symmetric(
          horizontal: 4 * scale.clamp(0.8, 1.2),
          vertical: 0,
        ),
      )).toList(),
    );
  }

  Widget _buildViewProductButton(String link, double scale) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final Uri url = Uri.parse(link);
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch product link.')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink,
          padding: EdgeInsets.symmetric(
            vertical: 12 * scale.clamp(0.8, 1.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'View Product',
          style: TextStyle(
            fontSize: 16 * scale.clamp(0.8, 1.3),
          ),
        ),
      ),
    );
  }
}