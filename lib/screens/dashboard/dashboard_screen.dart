import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import '../../helpers/currency_helper.dart';
import '../../helpers/responsive_helper.dart';
import '../../theme/app_theme.dart';
import '../../models/product.dart';
import '../transaction/transaction_history_screen.dart';
import '../reports/report_screen.dart';
import '../receivables/receivable_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = FirebaseDatabaseHelper.instance;
  Map<String, dynamic> _todaySales = {};
  double _monthlyRevenue = 0;
  List<Product> _lowStockProducts = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, dynamic> _receivableStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yearMonth = DateTime.now().toIso8601String().substring(0, 7);

    final todaySales = await _db.getDailySales(today);
    final monthlyRevenue = await _db.getTotalRevenue(
      dateFrom: '$yearMonth-01',
      dateTo: '$yearMonth-31',
    );
    final lowStock = await _db.getLowStockProducts();
    final topProducts = await _db.getTopProducts(limit: 5);
    final receivableStats = await _db.getReceivableStats();

    if (mounted) {
      setState(() {
        _todaySales = todaySales;
        _monthlyRevenue = monthlyRevenue;
        _lowStockProducts = lowStock;
        _topProducts = topProducts;
        _receivableStats = receivableStats;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final isPhone = ResponsiveHelper.isPhone(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryYellow),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primaryYellow,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryYellow,
                              AppTheme.primaryYellowLight,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                          boxShadow: AppTheme.elevatedShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    size: 28,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat Datang!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textMedium,
                                        ),
                                      ),
                                      Text(
                                        'POS+',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Receivable Alerts
                      if ((_receivableStats['approaching_count'] ?? 0) > 0 ||
                          (_receivableStats['overdue_count'] ?? 0) > 0)
                        _buildReceivableAlerts(),

                      // Stats Cards
                      _buildStatsGrid(isPhone),

                      const SizedBox(height: 24),

                      // Low Stock & Top Products
                      if (isPhone) ...[
                        _buildLowStockCard(),
                        const SizedBox(height: 16),
                        _buildTopProductsCard(),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLowStockCard()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTopProductsCard()),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildReceivableAlerts() {
    return Column(
      children: [
        if ((_receivableStats['overdue_count'] ?? 0) > 0)
          _buildAlertTile(
            icon: Icons.error_outline_rounded,
            color: AppTheme.error,
            title: 'Piutang Terlambat!',
            subtitle:
                '${_receivableStats['overdue_count']} transaksi sudah melewati jatuh tempo',
          ),
        if ((_receivableStats['approaching_count'] ?? 0) > 0)
          _buildAlertTile(
            icon: Icons.notification_important_rounded,
            color: AppTheme.warning,
            title: 'Mendekati Jatuh Tempo',
            subtitle:
                '${_receivableStats['approaching_count']} transaksi jatuh tempo dalam 3 hari',
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAlertTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isPhone) {
    final cards = [
      _StatData(
        icon: Icons.receipt_long_rounded,
        label: 'Transaksi Hari Ini',
        value: '${_todaySales['total_transactions'] ?? 0}',
        color: AppTheme.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
          );
        },
      ),
      _StatData(
        icon: Icons.payments_rounded,
        label: 'Penjualan Hari Ini',
        value: CurrencyHelper.formatCompact(
          ((_todaySales['total_sales'] ?? 0) as num).toDouble(),
        ),
        color: AppTheme.success,
      ),
      _StatData(
        icon: Icons.assignment_late_rounded,
        label: 'Total Piutang',
        value: CurrencyHelper.formatCompact(
          ((_receivableStats['total_amount'] ?? 0) as num).toDouble(),
        ),
        color: AppTheme.error,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReceivableListScreen()),
          );
        },
      ),

      _StatData(
        icon: Icons.trending_up_rounded,
        label: 'Omset Bulan Ini',
        value: CurrencyHelper.formatCompact(_monthlyRevenue),
        color: AppTheme.primaryYellowDark,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportScreen()),
          );
        },
      ),
      _StatData(
        icon: Icons.warning_amber_rounded,
        label: 'Stok Rendah',
        value: '${_lowStockProducts.length} produk',
        color: _lowStockProducts.isNotEmpty ? AppTheme.error : AppTheme.success,
      ),
    ];

    if (isPhone) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            cards.map((stat) {
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: _buildStatCard(stat),
              );
            }).toList(),
      );
    }

    return Row(
      children:
          cards.map((stat) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildStatCard(stat),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: stat.onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(
                  stat.value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Peringatan Stok Rendah',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _lowStockProducts.isNotEmpty
                          ? AppTheme.error.withOpacity(0.1)
                          : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_lowStockProducts.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        _lowStockProducts.isNotEmpty
                            ? AppTheme.error
                            : AppTheme.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_lowStockProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Semua stok aman 👍',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ),
            )
          else
            ...(_lowStockProducts
                .take(5)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                product.isOutOfStock
                                    ? AppTheme.error.withOpacity(0.1)
                                    : AppTheme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.isOutOfStock
                                ? 'Habis'
                                : '${product.stock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color:
                                  product.isOutOfStock
                                      ? AppTheme.error
                                      : AppTheme.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_rounded, color: AppTheme.primaryYellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Produk Terlaris',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Belum ada penjualan',
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ),
            )
          else
            ...(_topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final prod = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            index < 3
                                ? AppTheme.primaryYellow.withOpacity(0.2)
                                : AppTheme.divider.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              index < 3
                                  ? AppTheme.primaryYellowDark
                                  : AppTheme.textMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${prod['product_name']}',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${prod['total_qty']} terjual',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });
}
