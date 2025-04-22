import 'package:flutter/material.dart';
import 'package:skinsense/models/product.dart'; // Assuming you have a Product model
import 'package:skinsense/screens/products_screen.dart'; // Import the ProductsScreen
import 'package:skinsense/services/database_helper.dart'; // Import the DatabaseHelper

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> selectedConcerns = [];
  late Future<List<String>> _skinConcernsFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSkinConcerns();
  }

  Future<void> _loadSkinConcerns() async {
    setState(() => _isLoading = true);
    try {
      // Load skin concerns from your assets or another source
      _skinConcernsFuture = DatabaseHelper.fetchProducts().then((products) {
        // Retrieve skin concerns from the products in the database
        Set<String> concernsSet = {};
        for (var product in products) {
          concernsSet.addAll(product.skinConcerns);
        }
        return concernsSet.toList();
      });
      await _skinConcernsFuture;
    } catch (e) {
      debugPrint('Error loading skin concerns: $e');
      _skinConcernsFuture = Future.value([]);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Product>> _getProductsByConcerns() async {
    final allProducts = await DatabaseHelper.fetchProducts();
    return allProducts.where((product) {
      return product.skinConcerns.any((concern) =>
          selectedConcerns.contains(concern));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkinSense'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<String>>(
        future: _skinConcernsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Failed to load skin concerns',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadSkinConcerns,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allConcerns = snapshot.data!;
          return _buildConcernsSelection(allConcerns);
        },
      ),
    );
  }

  Widget _buildConcernsSelection(List<String> concerns) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Select your skin concerns',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 30),
          _buildConcernsDropdown(concerns),
          const SizedBox(height: 30),
          _buildSelectedConcernsDisplay(),
        ],
      ),
    );
  }

  Widget _buildConcernsDropdown(List<String> concerns) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink),
      ),
      child: ExpansionTile(
        title: Text(
          selectedConcerns.isEmpty
              ? 'Select skin concerns'
              : '${selectedConcerns.length} selected',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          if (concerns.isEmpty)
            const ListTile(
              title: Text('No skin concerns available'),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: concerns.length,
                itemBuilder: (context, index) {
                  final concern = concerns[index];
                  return CheckboxListTile(
                    title: Text(concern),
                    value: selectedConcerns.contains(concern),
                    onChanged: (value) {
                      setState(() {
                        if (value == true && !selectedConcerns.contains(
                            concern)) {
                          selectedConcerns.add(concern);
                        } else {
                          selectedConcerns.remove(concern);
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedConcernsDisplay() {
    if (selectedConcerns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedConcerns.map((concern) =>
              Chip(
                label: Text(concern),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    selectedConcerns.remove(concern);
                  });
                },
              )).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            // Fetch products from the database that match the selected concerns
            final products = await DatabaseHelper.fetchProductsByConcerns(
                selectedConcerns);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ProductsScreen(
                      selectedConcerns: selectedConcerns,
                      products: products, // Pass the products list here
                    ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Find Products'),
        ),
      ],
    );
  }
}
