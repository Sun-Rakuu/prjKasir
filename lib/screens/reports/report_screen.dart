import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../helpers/currency_helper.dart';
import '../../helpers/responsive_helper.dart';
import '../../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  final _db = FirebaseDatabaseHelper.instance;
  late TabController _tabController;
  bool _loading = true;

  // Daily
  Map<String, dynamic> _todaySales = {};
  // Monthly data
  List<Map<String, dynamic>> _monthlySalesData = [];
  double _monthlyTotal = 0;
  // Top products
  List<Map<String, dynamic>> _topProducts = [];
  // Last 7 days
  List<Map<String, dynamic>> _last7Days = [];
  // Currently selected month
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yearMonth = DateFormat('yyyy-MM').format(_selectedMonth);

    final todaySales = await _db.getDailySales(today);
    final monthlySales = await _db.getMonthlySales(yearMonth);
    final monthlyTotal = await _db.getTotalRevenue(
      dateFrom: '$yearMonth-01',
      dateTo: '$yearMonth-31',
    );
    final topProducts = await _db.getTopProducts(limit: 10);
    final last7Days = await _db.getLast7DaysSales();

    if (mounted) {
      setState(() {
        _todaySales = todaySales;
        _monthlySalesData = monthlySales;
        _monthlyTotal = monthlyTotal;
        _topProducts = topProducts;
        _last7Days = last7Days;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.textDark,
          unselectedLabelColor: AppTheme.textMedium,
          indicatorColor: AppTheme.textDark,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Harian'),
            Tab(text: 'Bulanan'),
            Tab(text: 'Produk Laris'),
            Tab(text: 'Omset'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTab(),
                _buildMonthlyTab(),
                _buildTopProductsTab(),
                _buildRevenueTab(),
              ],
            ),
    );
  }

  Widget _buildDailyTab() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final totalTransactions = _todaySales['total_transactions'] ?? 0;
    final totalSales = ((_todaySales['total_sales'] ?? 0) as num).toDouble();

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryYellow, AppTheme.primaryYellowLight],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
                ),
                const SizedBox(height: 12),
                Text(
                  CurrencyHelper.format(totalSales),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalTransactions transaksi',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Last 7 days chart
          const Text('Penjualan 7 Hari Terakhir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
            ),
            child: _last7Days.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textLight)))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxSales(_last7Days) * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              CurrencyHelper.formatCompact(rod.toY),
                              const TextStyle(color: AppTheme.white, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                CurrencyHelper.formatCompact(value),
                                style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _last7Days.length) return const Text('');
                              final dateStr = _last7Days[index]['sale_date'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  dateStr.substring(8),
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxSales(_last7Days) > 0 ? _getMaxSales(_last7Days) / 4 : 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.divider,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _last7Days.asMap().entries.map((entry) {
                        final sales = ((entry.value['total_sales'] ?? 0) as num).toDouble();
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: sales,
                              color: AppTheme.primaryYellow,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTab() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month picker
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
                  _loadData();
                },
              ),
              Expanded(
                child: Text(
                  monthStr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _selectedMonth.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                    ? () {
                        setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
                        _loadData();
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Monthly total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                const Text('Total Penjualan Bulan Ini', style: TextStyle(color: AppTheme.textLight)),
                const SizedBox(height: 4),
                Text(
                  CurrencyHelper.format(_monthlyTotal),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.primaryYellowDark),
                ),
                Text(
                  '${_monthlySalesData.length} hari aktif',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Monthly chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
            ),
            child: _monthlySalesData.isEmpty
                ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppTheme.textLight)))
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((spot) {
                            return LineTooltipItem(
                              CurrencyHelper.formatCompact(spot.y),
                              const TextStyle(color: AppTheme.white, fontSize: 12),
                            );
                          }).toList(),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) => Text(
                              CurrencyHelper.formatCompact(value),
                              style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _monthlySalesData.length) return const Text('');
                              final dateStr = _monthlySalesData[index]['sale_date'] as String;
                              return Text(dateStr.substring(8), style: const TextStyle(fontSize: 9, color: AppTheme.textLight));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _monthlySalesData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), ((e.value['total_sales'] ?? 0) as num).toDouble());
                          }).toList(),
                          isCurved: true,
                          color: AppTheme.primaryYellow,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppTheme.primaryYellow,
                              strokeWidth: 2,
                              strokeColor: AppTheme.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryYellow.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Daily breakdown
          ...(_monthlySalesData.reversed.map((day) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(CurrencyHelper.formatDateShort(day['sale_date'] as String),
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text('${day['total_transactions']} transaksi',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                    const SizedBox(width: 16),
                    Text(CurrencyHelper.format(((day['total_sales'] ?? 0) as num).toDouble()),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildTopProductsTab() {
    final padding = ResponsiveHelper.getScreenPadding(context);

    return _topProducts.isEmpty
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_border_rounded, size: 64, color: AppTheme.textLight),
                SizedBox(height: 8),
                Text('Belum ada data penjualan', style: TextStyle(color: AppTheme.textLight)),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart
                Container(
                  height: 280,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxQty(_topProducts) * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < _topProducts.length) {
                              return BarTooltipItem(
                                '${_topProducts[groupIndex]['product_name']}\n${rod.toY.toInt()} terjual',
                                const TextStyle(color: AppTheme.white, fontSize: 11),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _topProducts.length) return const Text('');
                              final name = _topProducts[index]['product_name'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: SizedBox(
                                  width: 50,
                                  child: Text(
                                    name.length > 8 ? '${name.substring(0, 8)}...' : name,
                                    style: const TextStyle(fontSize: 8, color: AppTheme.textLight),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _topProducts.asMap().entries.map((entry) {
                        final qty = ((entry.value['total_qty'] ?? 0) as num).toDouble();
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: qty,
                              color: entry.key < 3 ? AppTheme.primaryYellow : AppTheme.accentAmber.withOpacity(0.6),
                              width: 18,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Table
                ...(_topProducts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prod = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(10),
                      border: index < 3 ? Border.all(color: AppTheme.primaryYellow.withOpacity(0.3)) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: index < 3
                                ? AppTheme.primaryYellow.withOpacity(0.2)
                                : AppTheme.divider.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: index < 3 ? AppTheme.primaryYellowDark : AppTheme.textMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${prod['product_name']}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${prod['total_qty']} terjual',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(CurrencyHelper.format(((prod['total_revenue'] ?? 0) as num).toDouble()),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                          ],
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ),
          );
  }

  Widget _buildRevenueTab() {
    final padding = ResponsiveHelper.getScreenPadding(context);
    final todaySales = ((_todaySales['total_sales'] ?? 0) as num).toDouble();

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        children: [
          // Revenue cards
          GridView.count(
            crossAxisCount: ResponsiveHelper.isPhone(context) ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: ResponsiveHelper.isPhone(context) ? 3.5 : 2.5,
            children: [
              _buildRevenueCard(
                'Hari Ini',
                CurrencyHelper.format(todaySales),
                Icons.today_rounded,
                AppTheme.info,
              ),
              _buildRevenueCard(
                'Bulan Ini',
                CurrencyHelper.format(_monthlyTotal),
                Icons.calendar_month_rounded,
                AppTheme.primaryYellowDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tren Omset 7 Hari Terakhir',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Expanded(
                  child: _last7Days.isEmpty
                      ? const Center(child: Text('Belum ada data'))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (value, meta) => Text(
                                    CurrencyHelper.formatCompact(value),
                                    style: const TextStyle(fontSize: 9, color: AppTheme.textLight),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= _last7Days.length) return const Text('');
                                    final dateStr = _last7Days[index]['sale_date'] as String;
                                    return Text(dateStr.substring(8), style: const TextStyle(fontSize: 9, color: AppTheme.textLight));
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _last7Days.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), ((e.value['total_sales'] ?? 0) as num).toDouble());
                                }).toList(),
                                isCurved: true,
                                color: AppTheme.success,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 4,
                                    color: AppTheme.success,
                                    strokeWidth: 2,
                                    strokeColor: AppTheme.white,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.success.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxSales(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 100;
    double max = 0;
    for (var d in data) {
      final val = ((d['total_sales'] ?? 0) as num).toDouble();
      if (val > max) max = val;
    }
    return max > 0 ? max : 100;
  }

  double _getMaxQty(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 10;
    double max = 0;
    for (var d in data) {
      final val = ((d['total_qty'] ?? 0) as num).toDouble();
      if (val > max) max = val;
    }
    return max > 0 ? max : 10;
  }
}
