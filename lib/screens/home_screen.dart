import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/screens/products_screen.dart';
import 'package:skinsense/services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> selectedConcerns = [];
  List<String> allConcerns = [];
  bool _isExpanded = false;
  bool _isLoading = true;
  bool _isFindingProducts = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final concerns = await DatabaseHelper.fetchAllSkinConcerns();
      if (kDebugMode) {
        print('All available skin concerns: $allConcerns');
      }
      if (mounted) {
        setState(() {
          allConcerns = concerns;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load skin concerns: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SkinSense'),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
        ),
      )
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                _buildConcernsDropdown(),
                const SizedBox(height: 30),
                _buildSelectedConcernsDisplay(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConcernsDropdown() {
    return Column(
      children: [
        // Dropdown header
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.pink),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedConcerns.isEmpty
                      ? 'Select skin concerns'
                      : '${selectedConcerns.length} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.pink,
                ),
              ],
            ),
          ),
        ),
        // Dropdown content
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.pink.withOpacity(0.5)),
            ),
            child: _isExpanded
                ? ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _buildConcernsList(),
            )
                : null, // Changed from SizedBox() to null
          ),
        ),
      ],
    );
  }

  Widget _buildConcernsList() {
    if (allConcerns.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No skin concerns available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: allConcerns.length,
      itemBuilder: (context, index) {
        final concern = allConcerns[index];
        return CheckboxListTile(
          title: Text(concern),
          value: selectedConcerns.contains(concern),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedConcerns.add(concern);
              } else {
                selectedConcerns.remove(concern);
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Colors.pink,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        );
      },
    );
  }

  Widget _buildSelectedConcernsDisplay() {
    if (selectedConcerns.isEmpty) return const SizedBox();

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedConcerns.map((concern) => Chip(
            label: Text(concern),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => selectedConcerns.remove(concern)),
            backgroundColor: Colors.pink[50],
            labelStyle: const TextStyle(color: Colors.pink),
          )).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: selectedConcerns.isEmpty ? null : _findProducts,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            minimumSize: const Size(double.infinity, 50),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isFindingProducts
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text(
            'Find Products',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _findProducts() async {
    if (selectedConcerns.isEmpty) return;

    setState(() => _isFindingProducts = true);
    try {
      final products = await DatabaseHelper.fetchProductsByConcerns(
          selectedConcerns);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductsScreen(
            selectedConcerns: selectedConcerns,
            products: products,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFindingProducts = false);
      }
    }
  }
}