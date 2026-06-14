class Category {
  final String? docId;
  final int? id;
  final String name;
  final String? description;

  Category({
    this.docId,
    this.id,
    required this.name,
    this.description,
  });

  // SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  // Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
    };
  }

  factory Category.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    return Category(
      docId: docId,
      name: map['name'] ?? '',
      description: map['description'],
    );
  }

  Category copyWith({
    String? docId,
    int? id,
    String? name,
    String? description,
  }) {
    return Category(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}