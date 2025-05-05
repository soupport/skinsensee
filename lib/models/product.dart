class Product {
  final int? id;
  final String name;
  final String brand;
  final String price;
  final String link;
  final List<String> ingredients;
  final List<String> skinConcerns;
  final String imagePath;

  Product({
    this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.link,
    required this.ingredients,
    required this.skinConcerns,
    required this.imagePath,
  });

  factory Product.empty() {
    return Product(
      name: '',
      brand: '',
      price: '',
      link: '',
      ingredients: [],
      skinConcerns: [],
      imagePath: '',
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? brand,
    String? price,
    String? link,
    List<String>? ingredients,
    List<String>? skinConcerns,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      link: link ?? this.link,
      ingredients: ingredients ?? this.ingredients,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'link': link,
      'ingredients': ingredients.join(','),
      'skinConcerns': skinConcerns.join(','),
      'imagePath': imagePath,
    };
  }

  // Create Product from database map
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String,
      price: map['price'] as String,
      link: map['link'] as String,
      ingredients: (map['ingredients'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      skinConcerns: (map['skinConcerns'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      imagePath: map['imagePath'] as String,
    );
  }

  // For CSV parsing
  factory Product.fromCsv(List<dynamic> row, Map<String, int> headerIndices) {
    return Product(
      name: row[headerIndices['Name']!].toString().trim(),
      brand: row[headerIndices['Brand']!].toString().trim(),
      price: row[headerIndices['Price']!].toString().trim(),
      link: row[headerIndices['Link']!].toString().trim(),
      ingredients: row[headerIndices['Ingredients']!]
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      skinConcerns: row[headerIndices['Skin_Concerns']!]
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      imagePath: row[headerIndices['Image_path']!].toString().trim(),
    );
  }
}