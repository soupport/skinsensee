class Product {
  final String name;
  final String brand;
  final String price;
  final String link;
  final List<String> skinConcerns;
  final List<String> ingredients; // Adjusted ingredients to be a List<String>

  Product({
    required this.name,
    required this.brand,
    required this.price,
    required this.link,
    required this.skinConcerns,
    required this.ingredients,  // Make sure ingredients is a List<String>
  });

  // Empty Product constructor to create default values
  factory Product.empty() {
    return Product(
      name: '',
      brand: '',
      price: '',
      link: '',
      skinConcerns: [],
      ingredients: [],  // Empty list for ingredients
    );
  }

  // Parse product information from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: _getString(json, 'name'),
      brand: _getString(json, 'brand'),
      price: _getString(json, 'price'),
      link: _getString(json, 'link'),
      ingredients: _parseCsvString(json['ingredients']?.toString() ?? ''), // Parse ingredients as a List<String>
      skinConcerns: _parseCsvString(json['skinConcerns']?.toString() ?? ''),
    );
  }

  // Helper function to safely get a string from JSON, returning empty string if key is missing
  static String _getString(Map<String, dynamic> json, String key) {
    return json[key]?.toString() ?? '';
  }

  // Helper function to parse CSV-like string values (handles commas within quotes)
  static List<String> _parseCsvString(String input) {
    if (input.isEmpty) return [];

    final RegExp regExp = RegExp(r'"([^"]*)"|([^,]+)');
    final matches = regExp.allMatches(input);

    return matches.map((match) {
      return (match.group(1)?.trim() ?? match.group(2)?.trim() ?? '')
          .replaceAll(RegExp(r'\s+'), ' '); // Remove excessive whitespace
    }).toList();
  }
}
