import 'package:app_pos/models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import '../models/product.dart';
import '../models/store_settings.dart';

class FirebaseDatabaseHelper {
  static final FirebaseDatabaseHelper instance = FirebaseDatabaseHelper._init();

  FirebaseDatabaseHelper._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =====================================================
  // CATEGORY
  // =====================================================

  Future<int> _getNextCategoryId() async {
    final snapshot =
        await _firestore
            .collection('categories')
            .orderBy('id', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return 1;
    }

    return (snapshot.docs.first.data()['id'] ?? 0) + 1;
  }

  Future<int> insertCategory(Category category) async {
    final newId = await _getNextCategoryId();

    await _firestore.collection('categories').add({
      'id': newId,
      'name': category.name,
      'description': category.description,
    });

    return newId;
  }

  Future<List<Category>> getCategories() async {
    final snapshot =
        await _firestore.collection('categories').orderBy('name').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Category(
        docId: doc.id,
        id: data['id'],
        name: data['name'] ?? '',
        description: data['description'],
      );
    }).toList();
  }

  Future<void> updateCategory(int id, Category category) async {
    final snapshot =
        await _firestore
            .collection('categories')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({
      'name': category.name,
      'description': category.description,
    });
  }

  Future<void> deleteCategory(int id) async {
    final snapshot =
        await _firestore
            .collection('categories')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.delete();
  }

  // =====================================================
  // PRODUCT
  // =====================================================

  Future<int> _getNextProductId() async {
    final snapshot =
        await _firestore
            .collection('products')
            .orderBy('id', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return 1;
    }

    return (snapshot.docs.first.data()['id'] ?? 0) + 1;
  }

  Future<int> insertProduct(Product product) async {
    final newId = await _getNextProductId();

    await _firestore.collection('products').add({
      'id': newId,
      'name': product.name,
      'categoryId': product.categoryId,
      'categoryName': product.categoryName,
      'price': product.price,
      'stock': product.stock,
      'unit': product.unit,
      'description': product.description,
      'imagePath': product.imagePath,
      'isUnlimitedStock': product.isUnlimitedStock,
    });

    return newId;
  }

  Future<Product?> getProduct(int id) async {
    final snapshot =
        await _firestore
            .collection('products')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data();

    return Product(
      docId: doc.id,
      id: data['id'],
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? 0,
      categoryName: data['categoryName'],
      price: ((data['price'] ?? 0) as num).toDouble(),
      stock: data['stock'] ?? 0,
      unit: data['unit'] ?? 'pcs',
      description: data['description'],
      imagePath: data['imagePath'],
      isUnlimitedStock: data['isUnlimitedStock'] ?? false,
    );
  }

  Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('products');

    final snapshot = await query.get();

    List<Product> products =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return Product(
            docId: doc.id,
            id: data['id'],
            name: data['name'] ?? '',
            categoryId: data['categoryId'] ?? 0,
            categoryName: data['categoryName'],
            price: ((data['price'] ?? 0) as num).toDouble(),
            stock: data['stock'] ?? 0,
            unit: data['unit'] ?? 'pcs',
            description: data['description'],
            imagePath: data['imagePath'],
            isUnlimitedStock: data['isUnlimitedStock'] ?? false,
          );
        }).toList();

    if (search != null && search.isNotEmpty) {
      products =
          products.where((p) {
            return p.name.toLowerCase().contains(search.toLowerCase());
          }).toList();
    }

    if (categoryId != null) {
      products =
          products.where((p) {
            return p.categoryId == categoryId;
          }).toList();
    }

    products.sort((a, b) => a.name.compareTo(b.name));

    return products;
  }

  Future<void> updateProduct(Product product) async {
    final snapshot =
        await _firestore
            .collection('products')
            .where('id', isEqualTo: product.id)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({
      'name': product.name,
      'categoryId': product.categoryId,
      'categoryName': product.categoryName,
      'price': product.price,
      'stock': product.stock,
      'unit': product.unit,
      'description': product.description,
      'imagePath': product.imagePath,
      'isUnlimitedStock': product.isUnlimitedStock,
    });
  }

  Future<void> deleteProduct(int id) async {
    final snapshot =
        await _firestore
            .collection('products')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.delete();
  }

  // =====================================================
  // STOCK
  // =====================================================

  Future<void> updateStock(int productId, int stock) async {
    final snapshot =
        await _firestore
            .collection('products')
            .where('id', isEqualTo: productId)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({'stock': stock});
  }

  Future<List<Product>> getLowStockProducts() async {
    final products = await getProducts();

    return products.where((p) {
      if (p.isUnlimitedStock) {
        return false;
      }

      return p.stock <= 5;
    }).toList();
  }

  // =====================================================
  // TRANSACTION
  // =====================================================

  Future<int> _getNextTransactionId() async {
    final snapshot =
        await _firestore
            .collection('transactions')
            .orderBy('id', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return 1;
    }

    return (snapshot.docs.first.data()['id'] ?? 0) + 1;
  }

  Future<int> insertTransaction(SaleTransaction transaction) async {
    final newId = await _getNextTransactionId();

    await _firestore.collection('transactions').add({
      'id': newId,
      'date': transaction.date,
      'totalAmount': transaction.totalAmount,
      'paymentAmount': transaction.paymentAmount,
      'changeAmount': transaction.changeAmount,
      'paymentMethod': transaction.paymentMethod,
      'customerName': transaction.customerName,
      'customerPhone': transaction.customerPhone,
      'dueDate': transaction.dueDate,
      'status': transaction.status,
      'remainingAmount': transaction.remainingAmount,

      'items':
          transaction.items.map((item) {
            return {
              'productId': item.productId,
              'productName': item.productName,
              'price': item.price,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
            };
          }).toList(),
    });

    // otomatis kurangi stok
    for (final item in transaction.items) {
      final product = await getProduct(item.productId);

      if (product == null) continue;

      if (product.isUnlimitedStock) continue;

      await updateStock(item.productId, product.stock - item.quantity);
    }

    return newId;
  }

  Future<SaleTransaction?> getTransaction(int transactionId) async {
    final snapshot =
        await _firestore
            .collection('transactions')
            .where('id', isEqualTo: transactionId)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    final items =
        (data['items'] as List<dynamic>? ?? [])
            .map(
              (e) => TransactionItem(
                productId: e['productId'] ?? 0,
                productName: e['productName'] ?? '',
                price: ((e['price'] ?? 0) as num).toDouble(),
                quantity: e['quantity'] ?? 0,
                subtotal: ((e['subtotal'] ?? 0) as num).toDouble(),
              ),
            )
            .toList();

    return SaleTransaction(
      docId: doc.id,
      id: data['id'],
      date: data['date'] ?? '',
      totalAmount: ((data['totalAmount'] ?? 0) as num).toDouble(),
      paymentAmount: ((data['paymentAmount'] ?? 0) as num).toDouble(),
      changeAmount: ((data['changeAmount'] ?? 0) as num).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Tunai',
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      dueDate: data['dueDate'],
      status: data['status'] ?? 'Lunas',
      remainingAmount: ((data['remainingAmount'] ?? 0) as num).toDouble(),
      items: items,
    );
  }

  Future<List<SaleTransaction>> getTransactions({
    String? dateFrom,
    String? dateTo,
  }) async {
    final snapshot = await _firestore.collection('transactions').get();

    List<SaleTransaction> transactions =
        snapshot.docs.map((doc) {
          final data = doc.data();

          final items =
              (data['items'] as List<dynamic>? ?? [])
                  .map(
                    (e) => TransactionItem(
                      productId: e['productId'] ?? 0,
                      productName: e['productName'] ?? '',
                      price: ((e['price'] ?? 0) as num).toDouble(),
                      quantity: e['quantity'] ?? 0,
                      subtotal: ((e['subtotal'] ?? 0) as num).toDouble(),
                    ),
                  )
                  .toList();

          return SaleTransaction(
            docId: doc.id,
            id: data['id'],
            date: data['date'] ?? '',
            totalAmount: ((data['totalAmount'] ?? 0) as num).toDouble(),
            paymentAmount: ((data['paymentAmount'] ?? 0) as num).toDouble(),
            changeAmount: ((data['changeAmount'] ?? 0) as num).toDouble(),
            paymentMethod: data['paymentMethod'] ?? 'Tunai',
            customerName: data['customerName'],
            customerPhone: data['customerPhone'],
            dueDate: data['dueDate'],
            status: data['status'] ?? 'Lunas',
            remainingAmount: ((data['remainingAmount'] ?? 0) as num).toDouble(),
            items: items,
          );
        }).toList();

    if (dateFrom != null) {
      transactions =
          transactions.where((tx) {
            return tx.date.compareTo(dateFrom) >= 0;
          }).toList();
    }

    if (dateTo != null) {
      transactions =
          transactions.where((tx) {
            return tx.date.compareTo(dateTo) <= 0;
          }).toList();
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  Future<StoreSettings> getStoreSettings() async {
    final doc = await _firestore.collection('store_settings').doc('main').get();

    if (!doc.exists) {
      return StoreSettings(storeName: 'POS+', address: '', phone: '');
    }

    final data = doc.data()!;

    return StoreSettings(
      docId: doc.id,
      storeName: data['storeName'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      logoPath: data['logoPath'],
    );
  }

  Future<void> updateStoreSettings(StoreSettings settings) async {
    await _firestore.collection('store_settings').doc('main').set({
      'storeName': settings.storeName,
      'address': settings.address,
      'phone': settings.phone,
      'logoPath': settings.logoPath,
    });
  }

  Future<List<SaleTransaction>> getReceivables({
    String? status,
    String? search,
  }) async {
    List<SaleTransaction> data = await getTransactions();

    data =
        data.where((tx) {
          return tx.paymentMethod == 'Kredit';
        }).toList();

    if (status != null && status.isNotEmpty && status != 'Semua') {
      data =
          data.where((tx) {
            return tx.status == status;
          }).toList();
    }

    if (search != null && search.isNotEmpty) {
      data =
          data.where((tx) {
            return (tx.customerName ?? '').toLowerCase().contains(
              search.toLowerCase(),
            );
          }).toList();
    }

    return data;
  }

  Future<void> insertReceivablePayment({
    required int transactionId,
    required double amount,
    required String method,
  }) async {
    final tx = await getTransaction(transactionId);

    if (tx == null) return;

    final remaining = tx.remainingAmount - amount;

    final snapshot =
        await _firestore
            .collection('transactions')
            .where('id', isEqualTo: transactionId)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return;

    await snapshot.docs.first.reference.update({
      'remainingAmount': remaining < 0 ? 0 : remaining,
      'status': remaining <= 0 ? 'Lunas' : 'Belum Lunas',
    });

    await _firestore.collection('receivable_payments').add({
      'transactionId': transactionId,
      'amount': amount,
      'method': method,
      'date': DateTime.now().toIso8601String().substring(0, 10),
    });
  }

  Future<Map<String, dynamic>> getReceivableStats() async {
    final receivables = await getReceivables();

    double total = 0;

    for (final r in receivables) {
      total += r.remainingAmount;
    }

    return {'count': receivables.length, 'total': total};
  }

  Future<Map<String, dynamic>> getDailySales(String date) async {
    final transactions = await getTransactions();

    final todayTransactions =
        transactions.where((tx) {
          return tx.date.startsWith(date);
        }).toList();

    double totalSales = 0;

    for (final tx in todayTransactions) {
      totalSales += tx.totalAmount;
    }

    return {
      'total_transactions': todayTransactions.length,
      'total_sales': totalSales,
    };
  }

  Future<double> getTotalRevenue({String? dateFrom, String? dateTo}) async {
    List<SaleTransaction> data = await getTransactions();

    if (dateFrom != null) {
      data =
          data.where((tx) {
            return tx.date.compareTo(dateFrom) >= 0;
          }).toList();
    }

    if (dateTo != null) {
      data =
          data.where((tx) {
            return tx.date.compareTo(dateTo) <= 0;
          }).toList();
    }

    double total = 0;

    for (final tx in data) {
      total += tx.totalAmount;
    }

    return total;
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 10}) async {
    final transactions = await getTransactions();

    final Map<String, Map<String, dynamic>> products = {};

    for (final tx in transactions) {
      for (final item in tx.items) {
        products.putIfAbsent(item.productName, () {
          return {
            'product_name': item.productName,
            'total_qty': 0,
            'total_revenue': 0.0,
          };
        });

        products[item.productName]!['total_qty'] =
            (products[item.productName]!['total_qty'] as int) + item.quantity;

        products[item.productName]!['total_revenue'] =
            ((products[item.productName]!['total_revenue'] as num).toDouble()) +
            item.subtotal;
      }
    }

    final result = products.values.toList();

    result.sort((a, b) {
      return (b['total_qty'] as int).compareTo(a['total_qty'] as int);
    });

    return result.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlySales(String yearMonth) async {
    final transactions = await getTransactions();

    final Map<String, Map<String, dynamic>> daily = {};

    for (final tx in transactions) {
      if (!tx.date.startsWith(yearMonth)) continue;

      final date = tx.date.substring(0, 10);

      daily.putIfAbsent(date, () {
        return {'sale_date': date, 'total_sales': 0.0, 'total_transactions': 0};
      });

      daily[date]!['total_sales'] =
          ((daily[date]!['total_sales'] as num).toDouble()) + tx.totalAmount;

      daily[date]!['total_transactions'] =
          (daily[date]!['total_transactions'] as int) + 1;
    }

    final result = daily.values.toList();

    result.sort((a, b) {
      return (a['sale_date'] as String).compareTo(b['sale_date'] as String);
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> getLast7DaysSales() async {
    final transactions = await getTransactions();

    final result = <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));

      final date = day.toIso8601String().substring(0, 10);

      double sales = 0;

      for (final tx in transactions) {
        if (tx.date.startsWith(date)) {
          sales += tx.totalAmount;
        }
      }

      result.add({'sale_date': date, 'total_sales': sales});
    }

    return result;
  }
}
