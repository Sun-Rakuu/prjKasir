class StoreSettings {
  final String? docId;
  final int? id;
  final String storeName;
  final String address;
  final String phone;
  final String? logoPath;

  StoreSettings({
    this.docId,
    this.id,
    required this.storeName,
    required this.address,
    required this.phone,
    this.logoPath,
  });

  // SQLite
  Map<String, dynamic> toMap() {
    return {
      'store_name': storeName,
      'address': address,
      'phone': phone,
      'logo_path': logoPath,
    };
  }

  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      id: map['id'] as int?,
      storeName: map['store_name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      logoPath: map['logo_path'] as String?,
    );
  }

  // Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'storeName': storeName,
      'address': address,
      'phone': phone,
      'logoPath': logoPath,
    };
  }

  factory StoreSettings.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    return StoreSettings(
      docId: docId,
      storeName: map['storeName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      logoPath: map['logoPath'],
    );
  }

  StoreSettings copyWith({
    String? docId,
    int? id,
    String? storeName,
    String? address,
    String? phone,
    String? logoPath,
  }) {
    return StoreSettings(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}