import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skinsense/models/product.dart';
import 'package:skinsense/screens/products_screen.dart';
import 'package:skinsense/services/database_helper.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../services/routine_provider.dart';
import '../services/tips_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<String> selectedConcerns = [];
  List<String> allConcerns = [];
  List<Product> featuredProducts = [];
  bool _isLoading = true;
  bool _isFindingProducts = false;
  bool _showAllConcerns = false;
  TextEditingController searchController = TextEditingController();
  Map<String, String> _ingredientMessages = {};
  String? _selectedIngredient; // Track selected ingredient

  // Tips banner variables
  List<String> _tips = [];
  String _currentTip = "";
  int _currentTipIndex = 0;
  Timer? _tipTimer;
  late AnimationController _tipAnimationController;
  late Animation<Offset> _currentTipAnimation;
  late Animation<Offset> _nextTipAnimation;
  String _nextTip = "";

  // Colors
  Color get primaryColor =>
      Theme
          .of(context)
          .colorScheme
          .primary;

  Color get accentColor =>
      Theme
          .of(context)
          .colorScheme
          .secondary;

  Color get backgroundColor =>
      Theme
          .of(context)
          .scaffoldBackgroundColor;

  Color get textColor =>
      Theme
          .of(context)
          .textTheme
          .bodyLarge
          ?.color ?? Colors.black;

  Color get cardColor =>
      Theme
          .of(context)
          .cardTheme
          .color ?? Colors.white;


  @override
  void initState() {
    super.initState();

    // Initialize data loading
    _initializeData();
    _loadFeaturedProducts();
    _loadIngredientMessages();

    // Initialize animation controllers first
    _initAnimationControllers();

    // Load tips after animations are set up
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTips();
    });
  }

// Extracted animation controller initialization
  void _initAnimationControllers() {
    _tipAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _currentTipAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _tipAnimationController,
      curve: Curves.easeInOut,
    ));

    _nextTipAnimation = Tween<Offset>(
      begin: const Offset(-1.5, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _tipAnimationController,
      curve: Curves.easeInOut,
    ));

    _tipAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _currentTip = _nextTip;
          _tipAnimationController.reset();
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTips();
    });
  }

  Future<void> _initializeData() async {
    try {
      // Access the instance of DatabaseHelper
      final concerns = await DatabaseHelper.instance.fetchAllSkinConcerns();
      // Access the instance of DatabaseHelper
      final products = await DatabaseHelper.instance.fetchRandomProducts(4);

      if (mounted) {
        setState(() {
          allConcerns = concerns;
          featuredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }


  Future<void> _loadTips() async {
    try {
      debugPrint('Loading tips...');
      final String tipsData = await rootBundle.loadString(
          'assets/messages/home_page_tips.txt');

      setState(() {
        _tips = tipsData.split('\n').where((tip) =>
        tip
            .trim()
            .isNotEmpty).toList();

        if (_tips.isNotEmpty) {
          _currentTipIndex = Random().nextInt(_tips.length);
          _currentTip = _tips[_currentTipIndex];
          _startTipTimer();
        }
      });
    } catch (e) {
      debugPrint('Error loading tips: $e');
      setState(() {
        _tips = []; // Ensure tips list is empty if loading fails
      });
    }
  }


  void _startTipTimer() {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);

    // Cancel any existing timer
    _tipTimer?.cancel();

    // Only start timer if tips are enabled
    if (tipsProvider.showTips && _tips.isNotEmpty) {
      _tipTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (tipsProvider.showTips) { // Double-check setting before changing tip
          _changeTip();
        } else {
          timer.cancel(); // Cancel timer if tips were disabled
        }
      });
    }
  }


  void _changeTip() {
    if (_tips.isEmpty) return;

    setState(() {
      int nextIndex;
      do {
        nextIndex = Random().nextInt(_tips.length);
      } while (nextIndex == _currentTipIndex && _tips.length > 1);

      _currentTipIndex = nextIndex;
      _nextTip = _tips[_currentTipIndex];
      _tipAnimationController.forward();
    });
  }


  Future<void> _loadIngredientMessages() async {
    try {
      final String data = await rootBundle.loadString(
          'assets/messages/Ingredient_messages.txt');
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

      if (mounted) {
        setState(() {
          _ingredientMessages = messages;
        });
      }
    } catch (e) {
      debugPrint('Error loading ingredient messages: $e');
    }
  }


  @override
  void dispose() {
    _tipTimer?.cancel();
    _tipAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _toggleAllConcerns() {
    setState(() {
      _showAllConcerns = !_showAllConcerns;
    });
  }

  void _onProductTap(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailsModal(context, product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipsProvider = Provider.of<TipsProvider>(context);
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme
          .of(context)
          .colorScheme
          .primary))
          : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              if (tipsProvider.showTips && _currentTip.isNotEmpty)
                _buildTipsBanner(),
              _buildMainContent(),
              _buildNewArrivalsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      // Use the existing method to fetch all products
      final allProducts = await DatabaseHelper.instance.readAllProducts();
      allProducts.shuffle(); // Shuffle to get random products
      final selected = allProducts.take(4).toList(); // Pick 4

      if (mounted) {
        setState(() {
          featuredProducts = selected;
        });
      }

      debugPrint("Loaded ${selected.length} featured products");
    } catch (e) {
      debugPrint("Error loading featured products: $e");
    }
  }

  Widget _buildTipsBanner() {
    final tipsProvider = Provider.of<TipsProvider>(context);

    if (!tipsProvider.showTips || _tips.isEmpty) return const SizedBox.shrink();

    return Container(
      key: UniqueKey(),
      // Add this line
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme
            .of(context)
            .cardColor, // Use cardColor
        boxShadow: [
          BoxShadow(
            color: Theme
                .of(context)
                .shadowColor
                .withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                SlideTransition(
                  position: _currentTipAnimation,
                  child: Text(
                    _currentTip,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_tipAnimationController.status == AnimationStatus.forward)
                  SlideTransition(
                    position: _nextTipAnimation,
                    child: Text(
                      _nextTip,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromoBanner(),
          _buildSkinConcernsSection(),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    final isDarkMode = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
            Colors.pink[800]!,
            Colors.pink[900]!,
          ]
              : [
            primaryColor,
            primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5)
                : primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(16),
              ),
              child: Opacity(
                opacity: 0.2,
                child: Image.network(
                  'https://placeholder.com/150x100',
                  height: 100,
                  width: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: 150,
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New products for',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'your skin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore our latest skincare collection and find the perfect products for your skin.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinConcernsSection() {
    List<String> displayedConcerns = _showAllConcerns
        ? allConcerns
        : allConcerns.take(5).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skin Concerns',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              GestureDetector(
                onTap: _toggleAllConcerns,
                child: Text(
                  _showAllConcerns ? 'Show Less' : 'Show All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayedConcerns.map((concern) {
              final isSelected = selectedConcerns.contains(concern);
              return FilterChip(
                label: Text(
                  concern,
                  style: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                  ),
                ),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    if (selected) {
                      selectedConcerns.add(concern);
                    } else {
                      selectedConcerns.remove(concern);
                    }
                  });
                },
                backgroundColor: isSelected ? primaryColor : accentColor,
                checkmarkColor: Colors.white,
                side: BorderSide(color: primaryColor.withOpacity(0.5)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFindingProducts ? null : _findProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isFindingProducts
                  ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme
                      .of(context)
                      .colorScheme
                      .onPrimary,
                ),
              )
                  : const Text(
                'Find Products',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewArrivalsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Arrivals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredProducts.length,
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey(featuredProducts[index].id), // Added key
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildProductCard(featuredProducts[index], 180, 240),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProductCard(Product product, double cardWidth,
      double cardHeight) {
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
              child: SizedBox(
                height: cardHeight * 0.6,
                width: double.infinity,
                child: _buildProductImage(product.imagePath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6), // Now uses theme color
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: TextStyle(
                      color: textColor, // Now uses theme color
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '£${product.price}',
                    style: TextStyle(
                      color: primaryColor, // Now uses theme color
                      fontSize: 14,
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
  }

  String? _getIngredientMessage(String ingredient) {
    final ingredientLower = ingredient.toLowerCase();
    return _ingredientMessages[ingredientLower];
  }


  List<String> _getMatchingIngredients(List<String> productIngredients) {
    final List<String> matches = [];
    for (final productIngredient in productIngredients) {
      final productIngredientLower = productIngredient.toLowerCase();
      if (_ingredientMessages.containsKey(productIngredientLower)) {
        matches.add(productIngredient);
      }
    }
    return matches;
  }


  Widget _buildProductImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        color: accentColor.withOpacity(0.3),
        child: Center(
          child: Icon(
            Icons.spa,
            size: 40,
            color: primaryColor.withOpacity(0.5),
          ),
        ),
      );
    }

    // Handle different path formats
    String assetPath;
    if (imagePath.startsWith('assets/')) {
      assetPath = imagePath;
    } else if (imagePath.contains('/')) {
      assetPath = 'assets/product_images/${imagePath
          .split('/')
          .last}';
    } else {
      assetPath = 'assets/product_images/$imagePath';
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
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
      },
    );
  }

  Future<void> _findProducts() async {
    if (selectedConcerns.isEmpty) return;

    setState(() => _isFindingProducts = true);
    try {
      // Access the instance of DatabaseHelper
      final products = await DatabaseHelper.instance.fetchProductsByConcerns(
          selectedConcerns);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductsScreen(
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

  // Add this method to add a product to the skincare routine
  Future<void> _addToSkincareRoutine(Product product,
      BuildContext modalContext) async {
    try {
      Navigator.pop(modalContext);
      await Provider.of<RoutineProvider>(context, listen: false).addToRoutine(
          product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to your skincare routine'),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildIngredientInfo(String ingredient) {
    final message = _getIngredientMessage(ingredient);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    if (message == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ingredient Info:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor, // Use dynamic textColor
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close, size: 20, color: textColor), // Use dynamic textColor
              onPressed: () {
                setState(() {
                  _selectedIngredient = null;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          ingredient,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor, // Use dynamic textColor
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: textColor, // Use dynamic textColor
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetailsModal(BuildContext modalContext, Product product) {
    String? localSelectedIngredient;
    final modalKey = ValueKey(product.id);

    return StatefulBuilder(
      key: modalKey,
      builder: (context, setModalState) {
        // Cache theme data *within* the StatefulBuilder
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;
        final isDarkMode = theme.brightness == Brightness.dark;
        final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

        final darkBackground = isDarkMode ? Colors.grey[850]! : Colors.white;
        final darkTextColor = isDarkMode ? Colors.white : Colors.black87;
        final darkSecondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey;
        final darkChipBackground = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
        final darkButtonColor = isDarkMode ? Colors.pink[400]! : Colors.pink[300]!;

        // --- Helper Widgets (Theme-Independent) ---
        Widget buildSectionTitle(String title) {
          return Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkTextColor,
            ),
          );
        }

        Widget buildDivider() => const SizedBox(height: 16);

        // --- Main UI ---
        return Container(
          decoration: BoxDecoration(
            color: darkBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                      child: _buildProductImage(product.imagePath),
                    ),
                    buildDivider(),
                    buildSectionTitle(product.name),
                    const SizedBox(height: 8),
                    Text(
                      product.brand,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkSecondaryTextColor,
                      ),
                    ),
                    buildDivider(),
                    Text(
                      '£${product.price}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    buildDivider(),
                    buildSectionTitle('Key Ingredients'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getMatchingIngredients(product.ingredients)
                          .map((ingredient) {
                        final isSelected = localSelectedIngredient == ingredient;
                        return ActionChip(
                          key: ValueKey('ingredient_${product.id}_$ingredient'),
                          label: Text(
                            ingredient,
                            style: TextStyle(
                              color: isSelected ? Colors.white : darkTextColor,
                            ),
                          ),
                          backgroundColor: isSelected
                              ? primaryColor
                              : darkChipBackground,
                          onPressed: () {
                            setModalState(() {
                              localSelectedIngredient =
                              isSelected ? null : ingredient;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (localSelectedIngredient != null) ...[
                      buildDivider(),
                      _buildIngredientInfo(localSelectedIngredient!),
                    ],
                    buildDivider(),
                    buildSectionTitle('Skin Concerns'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.skinConcerns
                          .map(
                            (concern) => Chip(
                          key: ValueKey('concern_${product.id}_$concern'),
                          label: Text(
                            concern,
                            style: TextStyle(color: darkTextColor),
                          ),
                          backgroundColor: isDarkMode
                              ? Colors.pink[800]!.withOpacity(0.8)
                              : Colors.pink[50],
                        ),
                      )
                          .toList(),
                    ),
                    buildDivider(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: ValueKey('add_routine_${product.id}'),
                        onPressed: () =>
                            _addToSkincareRoutine(product, modalContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkButtonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add to Skincare Routine',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: ValueKey('view_online_${product.id}'),
                        onPressed: () async {
                          final Uri url = Uri.parse(product.link);
                          if (!await launchUrl(url,
                              mode: LaunchMode.externalApplication)) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Could not launch product link.')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkButtonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Product Online',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(modalContext),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 24, color: darkTextColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  }
