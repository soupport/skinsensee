class Product {
  final String name;
  final String brand;
  final String price;
  final String link;
  final List<String> ingredients;
  final List<String> skinConcerns;
  final String imagePath;

  Product({
    required this.name,
    required this.brand,
    required this.price,
    required this.link,
    required this.ingredients,
    required this.skinConcerns,
    required this.imagePath,
  });

  // Empty Product constructor
  factory Product.empty() {
    return Product(
      name: '',
      brand: '',
      price: '',
      link: '',
      skinConcerns: [],
      ingredients: [],
      imagePath: '', // Added empty string for imagePath
    );
  }

  // Parse product information from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      ingredients: (json['ingredients']?.toString() ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      skinConcerns: (json['skinConcerns']?.toString() ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imagePath: json['imagePath']?.toString() ?? '',
    );
  }


// Helper function to safely get a string from JSON
  static String _getString(Map<String, dynamic> json, String key) {
    return json[key]?.toString() ?? '';
  }

  // Helper function to parse CSV-like string values
  static List<String> _parseCsvString(String input) {
    if (input.isEmpty) return [];

    // Handle both quoted and unquoted values
    final RegExp regExp = RegExp(r'"([^"]*)"|([^,]+)');
    final matches = regExp.allMatches(input);

    return matches.map((match) {
      return (match.group(1)?.trim() ?? match.group(2)?.trim() ?? '')
          .replaceAll(RegExp(r'\s+'), ' ');
    }).where((item) => item.isNotEmpty).toList();
  }

  // Optionally add a toJson method if you need serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'brand': brand,
      'price': price,
      'link': link,
      'skinConcerns': skinConcerns.join(','),
      'ingredients': ingredients.join(','),
      'imagePath': imagePath,
    };
  }
}