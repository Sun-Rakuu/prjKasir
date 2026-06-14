import 'package:app_pos/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../helpers/responsive_helper.dart';
import 'dashboard/dashboard_screen.dart';
import 'transaction/pos_screen.dart';
import 'products/product_list_screen.dart';
import 'stock/stock_screen.dart';
import 'reports/report_screen.dart';
import 'settings/settings_screen.dart';
import 'receivables/receivable_list_screen.dart';

class MainScreen extends StatefulWidget {
  final String role;

  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool get isAdmin => widget.role == 'admin';

  late List<_NavItem> _navItems;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    if (widget.role == 'admin') {
      _navItems = [
        _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
        _NavItem(icon: Icons.point_of_sale_rounded, label: 'Kasir'),
        _NavItem(icon: Icons.inventory_2_rounded, label: 'Produk'),
        _NavItem(icon: Icons.warehouse_rounded, label: 'Stok'),
        _NavItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
        _NavItem(icon: Icons.assignment_rounded, label: 'Piutang'),
        _NavItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
      ];

      _screens = [
        const DashboardScreen(),
        const PosScreen(),
        const ProductListScreen(),
        const StockScreen(),
        const ReportScreen(),
        const ReceivableListScreen(),
        const SettingsScreen(),
      ];
    } else {
      _navItems = [
        _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
        _NavItem(icon: Icons.point_of_sale_rounded, label: 'Kasir'),
      ];

      _screens = [const DashboardScreen(), const PosScreen()];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveHelper.isPhone(context);

    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }

    if (isPhone) {
      return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: _buildBottomNav(),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            _buildSideNav(context),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration:
                        isSelected
                            ? BoxDecoration(
                              color: AppTheme.primaryYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            )
                            : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color:
                              isSelected
                                  ? AppTheme.primaryYellowDark
                                  : AppTheme.textLight,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color:
                                isSelected
                                    ? AppTheme.primaryYellowDark
                                    : AppTheme.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: isDesktop ? 240 : 80,
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryYellow, AppTheme.primaryYellowLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment:
                  isDesktop
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: AppTheme.textDark,
                    size: 24,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'POS+',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color:
                        isSelected
                            ? AppTheme.primaryYellow.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 16 : 0,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              isDesktop
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              color:
                                  isSelected
                                      ? AppTheme.primaryYellowDark
                                      : AppTheme.textMedium,
                              size: 22,
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 14),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      isSelected
                                          ? AppTheme.primaryYellowDark
                                          : AppTheme.textMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await AuthService.instance.logout();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 0,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment:
                      isDesktop
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.red),
                    if (isDesktop) ...[
                      const SizedBox(width: 14),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
