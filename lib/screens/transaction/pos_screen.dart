import 'dart:io';
import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../models/transaction_model.dart';
import '../../helpers/currency_helper.dart';
import '../../helpers/responsive_helper.dart';
import '../../theme/app_theme.dart';
import 'payment_dialog.dart';
import 'transaction_history_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _db = FirebaseDatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Product> _products = [];
  final List<_CartItem> _cartItems = [];
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cats = await _db.getCategories();
    final prods = await _db.getProducts(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: _selectedCategoryId,
    );
    if (mounted) {
      setState(() {
        _categories = cats.map((c) => {'id': c.id, 'name': c.name}).toList();
        _products = prods;
        _loading = false;
      });
    }
  }

  double get _totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  void _addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    
    // Jika sudah ada di keranjang, hapus (toggle off)
    if (existingIndex >= 0) {
      setState(() {
        _cartItems.removeAt(existingIndex);
      });
      return;
    }

    // Jika belum ada, cek stok lalu tambah
    if (!product.isUnlimitedStock && product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok habis!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _cartItems.add(_CartItem(product: product, quantity: 1));
    });
  }

  void _updateQuantity(int index, int newQty) {
    setState(() {
      final item = _cartItems[index];
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else if (item.product.isUnlimitedStock || newQty <= item.product.stock) {
        _cartItems[index] = item.copyWith(quantity: newQty);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok ${item.product.name} hanya ${item.product.stock}'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _clearCart({VoidCallback? onCleared}) {
    if (_cartItems.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Semua item akan dihapus dari keranjang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() => _cartItems.clear());
              Navigator.pop(ctx);
              onCleared?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus Semua', style: TextStyle(color: AppTheme.white)),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (_cartItems.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentDialog(
        totalAmount: _totalAmount,
        cartItems: _cartItems
            .map((item) => TransactionItem(
                  productId: item.product.id!,
                  productName: item.product.name,
                  price: item.product.price,
                  quantity: item.quantity,
                  subtotal: item.subtotal,
                ))
            .toList(),
        onPaymentComplete: () {
          setState(() => _cartItems.clear());
          _loadData(); // Refresh products (stock updated)
        },
      ),
    );
  }

  void _showQuantityDialog(int index, VoidCallback? onChanged) {
    final item = _cartItems[index];
    final controller = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Jumlah ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah',
            suffixText: item.product.unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? 0;
              _updateQuantity(index, newQty);
              onChanged?.call();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveHelper.isPhone(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
            ),
            tooltip: 'Riwayat',
          ),
        ],
      ),
      body: isPhone ? _buildPhoneLayout() : _buildTabletLayout(),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        Expanded(child: _buildProductGrid()),
        // Cart summary bar
        if (_cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_cartItems.length} item',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                        ),
                        Text(
                          CurrencyHelper.format(_totalAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryYellowDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showCartBottomSheet(),
                    icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                    label: const Text('Lihat Keranjang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Keranjang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _clearCart(onCleared: () => Navigator.pop(ctx)),
                      child: const Text('Hapus Semua', style: TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _cartItems.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, i) => _buildCartItem(i, onChanged: () => setSheetState(() {})),
                ),
              ),
              _buildCartFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: Product catalog
        Expanded(
          flex: 3,
          child: _buildProductGrid(),
        ),
        // Right: Cart
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: AppTheme.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: _buildCartPanel(),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final cols = ResponsiveHelper.getCrossAxisCount(context, phoneCols: 2, tabletCols: 3, desktopCols: 4);

    return Column(
      children: [
        // Search & Filters
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.surfaceLight,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => _loadData(),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textLight),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadData();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip(null, 'Semua'),
                    ..._categories.map((cat) =>
                        _buildCategoryChip(cat['id'] as int, cat['name'] as String)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Products Grid
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
              : _products.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textLight),
                          SizedBox(height: 8),
                          Text('Produk tidak ditemukan',
                              style: TextStyle(color: AppTheme.textLight)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: MediaQuery.of(context).size.width > MediaQuery.of(context).size.height ? 0.85 : 0.75,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => _buildProductCard(_products[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(int? id, String name) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategoryId = id);
          _loadData();
        },
        selectedColor: AppTheme.primaryYellow.withOpacity(0.3),
        backgroundColor: AppTheme.white,
        checkmarkColor: AppTheme.primaryYellowDark,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryYellow : AppTheme.divider,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final inCart = _cartItems.any((item) => item.product.id == product.id);
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
          border: inCart
              ? Border.all(color: AppTheme.primaryYellow, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusMedium),
                      ),
                      child: _buildProductImage(product),
                    ),
                  ),
                  // Stock badge
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.isUnlimitedStock
                            ? AppTheme.info
                            : product.isOutOfStock
                                ? AppTheme.error
                                : product.isLowStock
                                    ? AppTheme.warning
                                    : AppTheme.success,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.isUnlimitedStock
                            ? '∞'
                            : product.isOutOfStock
                                ? 'Habis'
                                : '${product.stock}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      product.categoryName ?? '',
                      style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      CurrencyHelper.format(product.price),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryYellowDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      if (product.imagePath!.startsWith('assets/')) {
        return Image.asset(
          product.imagePath!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(product),
        );
      } else {
        return Image.file(
          File(product.imagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(product),
        );
      }
    }
    return _buildFallbackIcon(product);
  }

  Widget _buildFallbackIcon(Product product) {
    return Center(
      child: Icon(
        _getCategoryIcon(product.categoryName),
        color: AppTheme.primaryYellowDark,
        size: 32,
      ),
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceLight,
            border: Border(bottom: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart_rounded, color: AppTheme.primaryYellowDark, size: 20),
              const SizedBox(width: 8),
              const Text('Keranjang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_cartItems.isNotEmpty)
                TextButton(
                  onPressed: _clearCart,
                  child: const Text('Hapus', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                ),
            ],
          ),
        ),
        // Items
        Expanded(
          child: _cartItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_shopping_cart_rounded, size: 48, color: AppTheme.textLight),
                      SizedBox(height: 8),
                      Text('Keranjang kosong', style: TextStyle(color: AppTheme.textLight)),
                      SizedBox(height: 4),
                      Text('Tap produk untuk menambahkan',
                          style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _cartItems.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (_, i) => _buildCartItem(i),
                ),
        ),
        // Footer
        if (_cartItems.isNotEmpty) _buildCartFooter(),
      ],
    );
  }

  Widget _buildCartItem(int index, {VoidCallback? onChanged}) {
    final item = _cartItems[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyHelper.format(item.product.price),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          // Quantity control
          Container(
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    _updateQuantity(index, item.quantity - 1);
                    onChanged?.call();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.remove, size: 16),
                  ),
                ),
                InkWell(
                  onTap: () => _showQuantityDialog(index, onChanged),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 40),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _updateQuantity(index, item.quantity + 1);
                    onChanged?.call();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Subtotal
          SizedBox(
            width: 70,
            child: Text(
              CurrencyHelper.format(item.subtotal),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
          // Delete
          InkWell(
            onTap: () {
              _removeFromCart(index);
              onChanged?.call();
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: const Border(top: BorderSide(color: AppTheme.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(
                  CurrencyHelper.format(_totalAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryYellowDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _processPayment,
                icon: const Icon(Icons.payments_rounded),
                label: const Text('BAYAR', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'selang':
        return Icons.water_rounded;
      case 'sambungan':
        return Icons.compare_arrows_rounded;
      case 'pipa':
        return Icons.plumbing_rounded;
      case 'drat':
        return Icons.settings_rounded;
      case 'kepala selang':
        return Icons.shower_rounded;
      case 'shock & clamp':
        return Icons.build_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

class _CartItem {
  final Product product;
  final int quantity;

  _CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  _CartItem copyWith({Product? product, int? quantity}) {
    return _CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
