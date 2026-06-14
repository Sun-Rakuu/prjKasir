import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../helpers/currency_helper.dart';
import '../../theme/app_theme.dart';

class ReceivableListScreen extends StatefulWidget {
  const ReceivableListScreen({super.key});

  @override
  State<ReceivableListScreen> createState() => _ReceivableListScreenState();
}

class _ReceivableListScreenState extends State<ReceivableListScreen> {
  final _db = FirebaseDatabaseHelper.instance;
  List<SaleTransaction> _receivables = [];
  bool _loading = true;
  String _selectedStatus = 'Semua';
  final _searchController = TextEditingController();

  final List<String> _statuses = ['Semua', 'Belum bayar', 'Sebagian', 'Lunas'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _db.getReceivables(
      status: _selectedStatus,
      search: _searchController.text,
    );
    if (mounted) {
      setState(() {
        _receivables = data;
        _loading = false;
      });
    }
  }

  void _showPaymentDialog(SaleTransaction tx) {
    final amountController = TextEditingController(
      text: tx.remainingAmount.toStringAsFixed(0),
    );
    String selectedMethod = 'Tunai';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: Text('Bayar Piutang: ${tx.customerName}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Sisa Tagihan: ${CurrencyHelper.format(tx.remainingAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nominal Bayar',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Metode Pembayaran'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Tunai'),
                              selected: selectedMethod == 'Tunai',
                              onSelected:
                                  (val) => setDialogState(
                                    () => selectedMethod = 'Tunai',
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Transfer'),
                              selected: selectedMethod == 'Transfer',
                              onSelected:
                                  (val) => setDialogState(
                                    () => selectedMethod = 'Transfer',
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0 || amount > tx.remainingAmount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nominal tidak valid'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                          return;
                        }

                        await _db.insertReceivablePayment(
                          transactionId: tx.id!,
                          amount: amount,
                          method: selectedMethod,
                        );

                        Navigator.pop(ctx);
                        _loadData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                      ),
                      child: const Text('Simpan Pembayaran'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Piutang')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child:
                _loading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow,
                      ),
                    )
                    : _receivables.isEmpty
                    ? const Center(child: Text('Tidak ada piutang ditemukan'))
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _receivables.length,
                      itemBuilder:
                          (ctx, i) => _buildReceivableCard(_receivables[i]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppTheme.surfaceLight,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => _loadData(),
            decoration: InputDecoration(
              hintText: 'Cari nama pelanggan...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppTheme.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              itemBuilder: (ctx, i) {
                final status = _statuses[i];
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedStatus = status);
                      _loadData();
                    },
                    selectedColor: AppTheme.primaryYellow.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryYellowDark,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivableCard(SaleTransaction tx) {
    final isOverdue =
        tx.dueDate != null &&
        DateTime.parse(tx.dueDate!).isBefore(DateTime.now()) &&
        tx.status != 'Lunas';

    final dueDate = tx.dueDate != null ? DateTime.parse(tx.dueDate!) : null;
    final isApproaching =
        dueDate != null &&
        dueDate.isBefore(DateTime.now().add(const Duration(days: 3))) &&
        !isOverdue &&
        tx.status != 'Lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: isOverdue ? Border.all(color: AppTheme.error, width: 1) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.customerName ?? 'Pelanggan Umum',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'No. Transaksi: #${tx.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(tx.status, isOverdue),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                _infoColumn(
                  'Tgl Transaksi',
                  CurrencyHelper.formatDate(tx.date),
                ),
                const Spacer(),
                _infoColumn(
                  'Jatuh Tempo',
                  tx.dueDate != null
                      ? CurrencyHelper.formatDate(tx.dueDate!)
                      : '-',
                  color:
                      isOverdue
                          ? AppTheme.error
                          : (isApproaching ? AppTheme.warning : null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _infoColumn(
                  'Total Tagihan',
                  CurrencyHelper.format(tx.totalAmount),
                ),
                const Spacer(),
                _infoColumn(
                  'Sisa Tagihan',
                  CurrencyHelper.format(tx.remainingAmount),
                  bold: true,
                  color: AppTheme.primaryYellowDark,
                ),
              ],
            ),
            if (tx.status != 'Lunas') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(tx),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text('BAYAR TAGIHAN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isOverdue) {
    Color color = AppTheme.success;
    String label = status;

    if (isOverdue) {
      color = AppTheme.error;
      label = 'Terlambat';
    } else if (status == 'Belum bayar') {
      color = AppTheme.error;
    } else if (status == 'Sebagian') {
      color = AppTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoColumn(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
