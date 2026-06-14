class Product {
  final String? docId;
  final int? id;
  final String name;
  final int categoryId;
  final double price;
  final int stock;
  final String unit;
  final String? description;
  final String? imagePath;
  final String? categoryName;
  final bool isUnlimitedStock;

  Product({
    this.docId,
    this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.stock,
    this.unit = 'pcs',
    this.description,
    this.imagePath,
    this.categoryName,
    this.isUnlimitedStock = false,
  });

  // SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'category_id': categoryId,
      'price': price,
      'stock': stock,
      'unit': unit,
      'description': description,
      'image_path': imagePath,
      'is_unlimited_stock': isUnlimitedStock ? 1 : 0,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      categoryId: map['category_id'] as int,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      unit: map['unit'] as String? ?? 'pcs',
      description: map['description'] as String?,
      imagePath: map['image_path'] as String?,
      categoryName: map['category_name'] as String?,
      isUnlimitedStock: (map['is_unlimited_stock'] as int?) == 1,
    );
  }

  // Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'categoryId': categoryId,
      'price': price,
      'stock': stock,
      'unit': unit,
      'description': description,
      'imagePath': imagePath,
      'categoryName': categoryName,
      'isUnlimitedStock': isUnlimitedStock,
    };
  }

  factory Product.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    return Product(
      docId: docId,
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      unit: map['unit'] ?? 'pcs',
      description: map['description'],
      imagePath: map['imagePath'],
      categoryName: map['categoryName'],
      isUnlimitedStock: map['isUnlimitedStock'] ?? false,
    );
  }

  Product copyWith({
    String? docId,
    int? id,
    String? name,
    int? categoryId,
    double? price,
    int? stock,
    String? unit,
    String? description,
    String? imagePath,
    String? categoryName,
    bool? isUnlimitedStock,
  }) {
    return Product(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      categoryName: categoryName ?? this.categoryName,
      isUnlimitedStock: isUnlimitedStock ?? this.isUnlimitedStock,
    );
  }

  bool get isLowStock {
    if (isUnlimitedStock) return false;
    return stock <= 5;
  }

  bool get isOutOfStock {
    if (isUnlimitedStock) return false;
    return stock <= 0;
  }
}