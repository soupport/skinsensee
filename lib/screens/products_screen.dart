import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart'; // Import your DatabaseHelper

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

  @override
  void initState() {
    super.initState();
    // Load products from the database when the screen is initialized
    _productsFuture = DatabaseHelper.fetchProducts();
  }

  // Get products that cater to all selected skin concerns (most recommended)
  List<Product> _getMostRecommendedProducts(List<Product> products, List<String> selectedConcerns) {
    return products.where((product) {
      // Check if the product's skin concerns contain all the selected concerns
      return selectedConcerns.every((concern) => product.skinConcerns.contains(concern));
    }).toList();
  }

  // Get products that cater to at least one selected skin concern (other recommendations)
  List<Product> _getOtherRecommendedProducts(List<Product> products, List<String> selectedConcerns) {
    return products.where((product) {
      // Check if the product's skin concerns contain at least one of the selected concerns
      return product.skinConcerns.any((concern) => selectedConcerns.contains(concern));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Products'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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
                  const Text(
                    'Failed to load products',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _productsFuture = DatabaseHelper.fetchProducts(); // Retry fetching products
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No products available',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Filter products based on the selected concerns
          List<Product> mostRecommendedProducts = _getMostRecommendedProducts(snapshot.data!, widget.selectedConcerns);
          List<Product> otherRecommendedProducts = _getOtherRecommendedProducts(snapshot.data!, widget.selectedConcerns);

          return Column(
            children: [
              // Section for displaying products
              Expanded(
                child: _buildProductList(
                  context,
                  isMostRecommendedSelected ? mostRecommendedProducts : otherRecommendedProducts,
                ),
              ),
              // Buttons for toggling sections
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isMostRecommendedSelected = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMostRecommendedSelected ? Colors.pink : Colors.grey,
                      ),
                      child: const Text('Most Recommended'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isMostRecommendedSelected = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isMostRecommendedSelected ? Colors.pink : Colors.grey,
                      ),
                      child: const Text('Other Recommendations'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductList(BuildContext context, List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No products found for your selected concerns',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
              ),
              child: const Text('Back to Selection'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product, context);
      },
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Brand: ${product.brand}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Price: ${product.price}',
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
            const SizedBox(height: 12),
            _buildConcernsChips(product),
            const SizedBox(height: 12),
            if (product.link.isNotEmpty) _buildViewProductButton(product.link, context),
          ],
        ),
      ),
    );
  }

  Widget _buildConcernsChips(Product product) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: product.skinConcerns
          .map((concern) => Chip(label: Text(concern)))
          .toList(),
    );
  }

  Widget _buildViewProductButton(String link, BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final Uri url = Uri.parse(link);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch product link.')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
      ),
      child: const Text('View Product'),
    );
  }

}
