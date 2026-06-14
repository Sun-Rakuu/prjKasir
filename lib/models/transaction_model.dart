class TransactionItem {
  final String? docId;
  final int? id;
  final int? transactionId;

  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  TransactionItem({
    this.docId,
    this.id,
    this.transactionId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  // ================= SQLITE =================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }

  // ================= FIRESTORE =================

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromFirestore(
    Map<String, dynamic> map,
  ) {
    return TransactionItem(
      productId: map['productId'] ?? 0,
      productName: map['productName'] ?? '',
      price: ((map['price'] ?? 0) as num).toDouble(),
      quantity: map['quantity'] ?? 0,
      subtotal: ((map['subtotal'] ?? 0) as num).toDouble(),
    );
  }

  TransactionItem copyWith({
    String? docId,
    int? id,
    int? transactionId,
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    double? subtotal,
  }) {
    return TransactionItem(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
    );
  }
}

class SaleTransaction {
  final String? docId;
  final int? id;

  final String date;
  final double totalAmount;
  final double paymentAmount;
  final double changeAmount;

  final String paymentMethod;
  final String? customerName;
  final String? customerPhone;
  final String? dueDate;

  final String status;
  final double remainingAmount;

  final List<TransactionItem> items;

  SaleTransaction({
    this.docId,
    this.id,
    required this.date,
    required this.totalAmount,
    required this.paymentAmount,
    required this.changeAmount,
    this.paymentMethod = 'Tunai',
    this.customerName,
    this.customerPhone,
    this.dueDate,
    this.status = 'Lunas',
    this.remainingAmount = 0,
    this.items = const [],
  });

  // ================= SQLITE =================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'total_amount': totalAmount,
      'payment_amount': paymentAmount,
      'change_amount': changeAmount,
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'due_date': dueDate,
      'status': status,
      'remaining_amount': remainingAmount,
    };
  }

  factory SaleTransaction.fromMap(
    Map<String, dynamic> map, [
    List<TransactionItem>? items,
  ]) {
    return SaleTransaction(
      id: map['id'] as int?,
      date: map['date'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paymentAmount: (map['payment_amount'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String? ?? 'Tunai',
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      dueDate: map['due_date'] as String?,
      status: map['status'] as String? ?? 'Lunas',
      remainingAmount:
          ((map['remaining_amount'] as num?) ?? 0).toDouble(),
      items: items ?? [],
    );
  }

  // ================= FIRESTORE =================

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'totalAmount': totalAmount,
      'paymentAmount': paymentAmount,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'dueDate': dueDate,
      'status': status,
      'remainingAmount': remainingAmount,
      'items': items.map((e) => e.toFirestore()).toList(),
    };
  }

  factory SaleTransaction.fromFirestore(
    String docId,
    Map<String, dynamic> map,
  ) {
    return SaleTransaction(
      docId: docId,
      date: map['date'] ?? '',
      totalAmount: ((map['totalAmount'] ?? 0) as num).toDouble(),
      paymentAmount: ((map['paymentAmount'] ?? 0) as num).toDouble(),
      changeAmount: ((map['changeAmount'] ?? 0) as num).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'Tunai',
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      dueDate: map['dueDate'],
      status: map['status'] ?? 'Lunas',
      remainingAmount:
          ((map['remainingAmount'] ?? 0) as num).toDouble(),
      items: (map['items'] as List<dynamic>? ?? [])
          .map(
            (e) => TransactionItem.fromFirestore(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }

  SaleTransaction copyWith({
    String? docId,
    int? id,
    String? date,
    double? totalAmount,
    double? paymentAmount,
    double? changeAmount,
    String? paymentMethod,
    String? customerName,
    String? customerPhone,
    String? dueDate,
    String? status,
    double? remainingAmount,
    List<TransactionItem>? items,
  }) {
    return SaleTransaction(
      docId: docId ?? this.docId,
      id: id ?? this.id,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      items: items ?? this.items,
    );
  }

  bool get isCredit => paymentMethod == 'Kredit';

  bool get isPaid => status == 'Lunas';

  bool get hasDebt => remainingAmount > 0;
}