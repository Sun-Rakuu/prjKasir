import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../helpers/currency_helper.dart';
import '../../helpers/responsive_helper.dart';
import '../../theme/app_theme.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  final _db = FirebaseDatabaseHelper.instance;
  List<Product> _allProducts = [];
  List<Product> _lowStockProducts = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final all = await _db.getProducts();
    final low = await _db.getLowStockProducts();
    if (mounted) {
      setState(() {
        _allProducts = all;
        _lowStockProducts = low;
        _loading = false;
      });
    }
  }

  void _updateStock(Product product) {
    final controller = TextEditingController(text: product.stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Stok: ${product.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stok saat ini: ${product.stock} ${product.unit}',
                style: const TextStyle(color: AppTheme.textLight)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Stok Baru',
                prefixIcon: Icon(Icons.inventory_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text) ?? 0;
              await _db.updateStock(product.id!, newStock);
              Navigator.pop(ctx);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stok ${product.name} diupdate menjadi $newStock'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.textDark,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.textDark,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Semua Produk'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Stok Rendah'),
                  if (_lowStockProducts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_lowStockProducts.length}',
                        style: const TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(_allProducts, padding),
                _buildProductList(_lowStockProducts, padding, showEmpty: true),
              ],
            ),
    );
  }

  Widget _buildProductList(List<Product> products, EdgeInsets padding, {bool showEmpty = false}) {
    if (products.isEmpty && showEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.success),
            SizedBox(height: 8),
            Text('Semua stok dalam kondisi aman!',
                style: TextStyle(color: AppTheme.textLight, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryYellow,
      child: ListView.builder(
        padding: padding,
        itemCount: products.length,
        itemBuilder: (_, i) {
          final product = products[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
              border: product.isOutOfStock
                  ? Border.all(color: AppTheme.error.withOpacity(0.3), width: 1)
                  : product.isLowStock
                      ? Border.all(color: AppTheme.warning.withOpacity(0.3), width: 1)
                      : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: product.isOutOfStock
                      ? AppTheme.error.withOpacity(0.1)
                      : product.isLowStock
                          ? AppTheme.warning.withOpacity(0.1)
                          : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  product.isOutOfStock
                      ? Icons.error_outline_rounded
                      : product.isLowStock
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                  color: product.isOutOfStock
                      ? AppTheme.error
                      : product.isLowStock
                          ? AppTheme.warning
                          : AppTheme.success,
                  size: 22,
                ),
              ),
              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                '${product.categoryName ?? '-'} • ${CurrencyHelper.format(product.price)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${product.stock}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: product.isOutOfStock
                              ? AppTheme.error
                              : product.isLowStock
                                  ? AppTheme.warning
                                  : AppTheme.textDark,
                        ),
                      ),
                      Text(product.unit,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _updateStock(product),
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryYellowDark),
                    tooltip: 'Update Stok',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
