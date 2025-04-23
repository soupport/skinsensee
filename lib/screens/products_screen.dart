import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/services/database_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      _productsFuture = DatabaseHelper.fetchProducts();
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
      final products = await DatabaseHelper.fetchProducts();
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
                  const Text('Failed to load products', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _retryLoading,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products available', style: TextStyle(fontSize: 18)));
          }

          final products = snapshot.data!;
          final mostRecommended = _getMostRecommendedProducts(products);
          final otherRecommended = _getOtherRecommendedProducts(products);
          final displayProducts = isMostRecommendedSelected ? mostRecommended : otherRecommended;

          return Column(
            children: [
              Expanded(
                child: _buildProductList(displayProducts),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildToggleButton('Most Recommended', true),
                    _buildToggleButton('Other Recommendations', false),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleButton(String text, bool value) {
    return ElevatedButton(
      onPressed: () {
        if (isMostRecommendedSelected != value) {
          setState(() => isMostRecommendedSelected = value);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isMostRecommendedSelected == value ? Colors.pink : Colors.grey,
      ),
      child: Text(text),
    );
  }

  Widget _buildProductList(List<Product> products) {
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Back to Selection'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildProductCard(products[index]),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductImage(product),
                const SizedBox(width: 16),
                Expanded(
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
                      const SizedBox(height: 4),
                      Text('Brand: ${product.brand}', style: const TextStyle(fontSize: 14)),
                      Text('Price: \£${product.price}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildConcernsChips(product),
            if (product.link.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildViewProductButton(product.link),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _getImageWidget(product),
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

    // Extract just the filename from the path if it's a full path
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

  Widget _buildConcernsChips(Product product) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: product.skinConcerns.map((concern) => Chip(
        label: Text(concern),
        backgroundColor: Colors.pink[50],
        labelStyle: const TextStyle(color: Colors.pink),
      )).toList(),
    );
  }

  Widget _buildViewProductButton(String link) {
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('View Product', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}