import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../helpers/currency_helper.dart';
import '../../helpers/responsive_helper.dart';
import '../../theme/app_theme.dart';
import '../../services/receipt_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _db = FirebaseDatabaseHelper.instance;
  List<SaleTransaction> _transactions = [];
  bool _loading = true;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    final transactions = await _db.getTransactions(
      dateFrom: _dateRange?.start.toIso8601String().substring(0, 10),
      dateTo: _dateRange?.end.toIso8601String().substring(0, 10),
    );
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryYellow),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      setState(() => _dateRange = range);
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveHelper.isPhone(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                setState(() => _dateRange = null);
                _loadTransactions();
              },
              tooltip: 'Reset Filter',
            ),
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: _pickDateRange,
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryYellow))
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.textLight),
                      SizedBox(height: 8),
                      Text('Belum ada transaksi', style: TextStyle(color: AppTheme.textLight)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: ResponsiveHelper.getScreenPadding(context),
                  itemCount: _transactions.length,
                  itemBuilder: (_, i) => _buildTransactionCard(_transactions[i], isPhone),
                ),
    );
  }

  Widget _buildTransactionCard(SaleTransaction tx, bool isPhone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_rounded, color: AppTheme.primaryYellowDark, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${tx.id.toString().padLeft(4, '0')}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      CurrencyHelper.formatDate(tx.date),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyHelper.format(tx.totalAmount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryYellowDark,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4, left: 42),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.paymentMethod,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMedium),
                  ),
                ),
                if (tx.paymentMethod == 'Kredit') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (tx.status == 'Lunas' ? AppTheme.success : AppTheme.error).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tx.status,
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.w600, 
                        color: tx.status == 'Lunas' ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          children: [
            const Divider(),
            ...tx.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.productName, style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        '${item.quantity} x ${CurrencyHelper.format(item.price)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: Text(
                          CurrencyHelper.format(item.subtotal),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Bayar', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                Text(CurrencyHelper.format(tx.paymentAmount),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                Text(CurrencyHelper.format(tx.changeAmount),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ReceiptService.printReceipt(context, tx),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: const Text('Cetak Struk', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
