import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:app_pos/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/store_settings.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = FirebaseDatabaseHelper.instance;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _logoPath;
  Uint8List? _logoBytes;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    final settings = await _db.getStoreSettings();
    if (mounted) {
      setState(() {
        _nameController.text = settings.storeName;
        _addressController.text = settings.address;
        _phoneController.text = settings.phone;
        _logoPath = settings.logoPath;
        _loading = false;
      });
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _logoBytes = bytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih logo: $e')));
    }
  }

  Future<String?> _uploadLogoToFirebase() async {
    if (_logoBytes == null) return _logoPath;

    try {
      final fileName =
          'store/logo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putData(_logoBytes!);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload logo error: $e');
      return null;
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final logoUrl = await _uploadLogoToFirebase();
      final settings = StoreSettings(
        storeName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        logoPath: logoUrl,
      );
      await _db.updateStoreSettings(settings);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
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
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildLogoPlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_rounded,
          color: AppTheme.primaryYellowDark,
          size: 32,
        ),
        SizedBox(height: 4),
        Text(
          'Pilih Logo',
          style: TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Toko')),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryYellow),
              )
              : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo section
                        Container(
                          padding: const EdgeInsets.all(24),
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
                                'Logo Toko',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _pickLogo,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primaryYellow.withOpacity(
                                        0.5,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child:
                                        _logoBytes != null
                                            ? Image.memory(
                                              _logoBytes!,
                                              fit: BoxFit.cover,
                                            )
                                            : (_logoPath != null &&
                                                    _logoPath!.isNotEmpty
                                                ? Image.network(
                                                  _logoPath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          _buildLogoPlaceholder(),
                                                )
                                                : _buildLogoPlaceholder()),
                                  ),
                                ),
                              ),

                              if (_logoPath != null || _logoBytes != null) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _logoPath = null;
                                      _logoBytes = null;
                                    });
                                  },
                                  child: const Text(
                                    'Hapus Logo',
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

                        // Store info
                        Container(
                          padding: const EdgeInsets.all(24),
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
                                'Informasi Toko',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Toko',
                                  prefixIcon: Icon(
                                    Icons.store_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Alamat',
                                  prefixIcon: Icon(
                                    Icons.location_on_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telepon / WhatsApp',
                                  prefixIcon: Icon(
                                    Icons.phone_rounded,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: _saving ? null : _saveSettings,
                          icon:
                              _saving
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save_rounded),
                          label: const Text(
                            'SIMPAN PENGATURAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryYellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text('Logout'),
                                    content: const Text(
                                      'Apakah Anda yakin ingin keluar?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true) {
                              await AuthService.instance.logout();
                            }
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('LOGOUT'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
