import 'dart:convert';
import 'dart:typed_data';
import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../theme/app_theme.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final List<Category> categories;

  const ProductFormScreen({super.key, this.product, required this.categories});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = FirebaseDatabaseHelper.instance;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController();
  final _descController = TextEditingController();
  int? _selectedCategoryId;
  String? _imagePath;
  Uint8List? _imageBytes;
  bool _saving = false;
  bool _isUnlimitedStock = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.product!;
      _nameController.text = p.name;
      _priceController.text = p.price.toStringAsFixed(0);
      _stockController.text = p.stock.toString();
      _unitController.text = p.unit;
      _descController.text = p.description ?? '';
      _selectedCategoryId = p.categoryId;
      _imagePath = p.imagePath;
      _isUnlimitedStock = p.isUnlimitedStock;
    } else {
      _unitController.text = 'pcs';
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        imageQuality: 60,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _imageBytes = bytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_imageBytes == null) return _imagePath;

    return base64Encode(_imageBytes!);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final imageUrl = await _uploadImageToFirebase();

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      price: double.parse(_priceController.text.replaceAll('.', '')),
      stock: _isUnlimitedStock ? 0 : int.parse(_stockController.text),
      unit: _unitController.text.trim(),
      description:
          _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
      imagePath: imageUrl,
      isUnlimitedStock: _isUnlimitedStock,
    );

    try {
      if (_isEdit) {
        await _db.updateProduct(product);
      } else {
        await _db.insertProduct(product);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Gambar Produk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryYellow.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                            child: _buildImagePreview(),
                          ),
                        ),
                        if (_imagePath != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _imagePath = null),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: AppTheme.error,
                            ),
                            label: const Text(
                              'Hapus Gambar',
                              style: TextStyle(
                                color: AppTheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Produk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nama Produk',
                          icon: Icons.inventory_2_rounded,
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _priceController,
                                label: 'Harga (Rp)',
                                icon: Icons.payments_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Wajib diisi'
                                            : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _stockController,
                                label: 'Stok',
                                icon: Icons.numbers_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator:
                                    _isUnlimitedStock
                                        ? null
                                        : (v) =>
                                            v == null || v.isEmpty
                                                ? 'Wajib diisi'
                                                : null,
                                enabled: !_isUnlimitedStock,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _unitController,
                                label: 'Satuan',
                                icon: Icons.straighten_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Stok Unlimited',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Aktifkan jika stok produk tidak terbatas/selalu ada.',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isUnlimitedStock,
                          activeColor: AppTheme.primaryYellowDark,
                          onChanged: (val) {
                            setState(() {
                              _isUnlimitedStock = val;
                              // If checked, clear out validation state on stock input implicitly
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _descController,
                          label: 'Deskripsi (opsional)',
                          icon: Icons.description_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child:
                        _saving
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              _isEdit ? 'SIMPAN PERUBAHAN' : 'SIMPAN PRODUK',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    if (_imagePath != null && _imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imagePath!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
        ),
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          color: AppTheme.primaryYellowDark,
          size: 36,
        ),
        SizedBox(height: 6),
        Text(
          'Tap untuk pilih gambar',
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category_rounded, size: 20),
      ),
      items:
          widget.categories
              .map(
                (cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)),
              )
              .toList(),
      onChanged: (val) => setState(() => _selectedCategoryId = val),
      validator: (v) => v == null ? 'Pilih kategori' : null,
    );
  }
}
