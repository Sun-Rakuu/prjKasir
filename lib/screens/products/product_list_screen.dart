import 'dart:io';
import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../helpers/currency_helper.dart';
import '../../helpers/responsive_helper.dart';
import '../../theme/app_theme.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _db = FirebaseDatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Product> _products = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final products = await _db.getProducts(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      categoryId: _selectedCategoryId,
    );
    final categories = await _db.getCategories();
    if (mounted) {
      setState(() {
        _products = products;
        _categories = categories;
        _loading = false;
      });
    }
  }

  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(categories: _categories)),
    );
    if (result == true) _loadData();
  }

  void _editProduct(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product, categories: _categories),
      ),
    );
    if (result == true) _loadData();
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteProduct(product.id!);
              Navigator.pop(ctx);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: AppTheme.success),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: AppTheme.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _manageCategories() {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(
        categories: _categories,
        onChanged: () {
          _loadData();
          Navigator.pop(ctx);
        },
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
    final padding = ResponsiveHelper.getScreenPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            onPressed: _manageCategories,
            tooltip: 'Kelola Kategori',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add_rounded),
        label: Text(isPhone ? 'Tambah' : 'Tambah Produk'),
      ),
      body: Column(
        children: [
          // Search & filter
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
                      _buildFilterChip(null, 'Semua (${_products.length})'),
                      ..._categories.map((cat) => _buildFilterChip(cat.id, cat.name)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Product list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
                : _products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textLight),
                            SizedBox(height: 8),
                            Text('Tidak ada produk', style: TextStyle(color: AppTheme.textLight)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: padding,
                        itemCount: _products.length,
                        itemBuilder: (_, i) => _buildProductRow(_products[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int? id, String name) {
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
        selectedColor: AppTheme.primaryYellow.withValues(alpha: 0.3),
        backgroundColor: AppTheme.white,
        checkmarkColor: AppTheme.primaryYellowDark,
        side: BorderSide(color: isSelected ? AppTheme.primaryYellow : AppTheme.divider),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      if (product.imagePath!.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            product.imagePath!,
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackIcon(),
          ),
        );
      } else if (File(product.imagePath!).existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(product.imagePath!),
            width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackIcon(),
          ),
        );
      }
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryYellowDark, size: 22),
    );
  }

  Widget _buildProductRow(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildProductImage(product),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${product.categoryName ?? '-'} • Stok: ${product.stock} ${product.unit}',
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
                  CurrencyHelper.format(product.price),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryYellowDark, fontSize: 14),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: product.isOutOfStock
                        ? AppTheme.error.withValues(alpha: 0.1)
                        : product.isLowStock
                            ? AppTheme.warning.withValues(alpha: 0.1)
                            : AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    product.isOutOfStock ? 'Habis' : product.isLowStock ? 'Stok Rendah' : 'Tersedia',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: product.isOutOfStock
                          ? AppTheme.error
                          : product.isLowStock
                              ? AppTheme.warning
                              : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _editProduct(product);
                if (value == 'delete') _deleteProduct(product);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppTheme.error))])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onChanged;

  const _CategoryDialog({required this.categories, required this.onChanged});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _db = FirebaseDatabaseHelper.instance;
  final _nameController = TextEditingController();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = List.from(widget.categories);
  }

  Future<void> _reloadCategories() async {
    final cats = await _db.getCategories();
    setState(() => _categories = cats);
  }

  void _addCategory() async {
    if (_nameController.text.isEmpty) return;
    await _db.insertCategory(Category(name: _nameController.text.trim()));
    _nameController.clear();
    await _reloadCategories();
  }

  void _deleteCategory(Category cat) async {
    await _db.deleteCategory(cat.id!);
    await _reloadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nama kategori baru',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryYellowDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  return ListTile(
                    dense: true,
                    title: Text(cat.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                      onPressed: () => _deleteCategory(cat),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: widget.onChanged,
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
