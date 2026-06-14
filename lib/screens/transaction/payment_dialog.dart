import 'package:app_pos/database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction_model.dart';
import '../../helpers/currency_helper.dart';
import '../../theme/app_theme.dart';
import '../../services/receipt_service.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final List<TransactionItem> cartItems;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.cartItems,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _paymentController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _paymentFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  
  final _db = FirebaseDatabaseHelper.instance;
  double _changeAmount = 0;
  bool _isProcessing = false;
  bool _showError = false;

  // Success state
  bool _paymentSuccess = false;
  SaleTransaction? _completedTransaction;
  String _paymentMethod = 'Tunai';
  DateTime? _dueDate;

  final List<int> _quickAmounts = [
    10000, 20000, 50000, 100000, 200000, 500000,
  ];


  @override
  void initState() {
    super.initState();
    _paymentController.addListener(_calculateChange);
  }

  void _calculateChange() {
    final payment = double.tryParse(_paymentController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _changeAmount = payment - widget.totalAmount;
      _showError = false;
    });
  }

  void _changePaymentMethod(String method) {
    setState(() {
      _paymentMethod = method;
      _showError = false;
    });

    // Force unfocus to reset keyboard state
    FocusScope.of(context).unfocus();

    // Handle focus switching based on method
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        if (method == 'Kredit') {
          _nameFocusNode.requestFocus();
        } else {
          _paymentFocusNode.requestFocus();
        }
      }
    });
  }


  void _setQuickAmount(int amount) {

    _paymentController.text = amount.toString();
  }

  void _setExactAmount() {
    _paymentController.text = widget.totalAmount.toStringAsFixed(0);
  }

  Future<void> _processPayment() async {
    final paymentText = _paymentController.text.replaceAll('.', '');
    final payment = double.tryParse(paymentText) ?? 0;

    if (_paymentMethod != 'Kredit' && payment < widget.totalAmount) {
      setState(() => _showError = true);
      return;
    }

    if (_paymentMethod == 'Kredit') {
      if (_customerNameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama pelanggan harus diisi untuk Kredit'), backgroundColor: AppTheme.error),
        );
        return;
      }
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tentukan tanggal jatuh tempo'), backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final transaction = SaleTransaction(
        date: DateTime.now().toIso8601String(),
        totalAmount: widget.totalAmount,
        paymentAmount: _paymentMethod == 'Kredit' ? payment : payment,
        changeAmount: _paymentMethod == 'Kredit' ? 0 : payment - widget.totalAmount,
        paymentMethod: _paymentMethod,
        customerName: _paymentMethod == 'Kredit' ? _customerNameController.text : null,
        customerPhone: _paymentMethod == 'Kredit' ? _customerPhoneController.text : null,
        dueDate: _paymentMethod == 'Kredit' ? _dueDate?.toIso8601String() : null,
        status: _paymentMethod == 'Kredit' 
            ? (payment > 0 ? 'Sebagian' : 'Belum bayar') 
            : 'Lunas',
        remainingAmount: _paymentMethod == 'Kredit' 
            ? widget.totalAmount - payment 
            : 0,
        items: widget.cartItems,
      );

      final transId = await _db.insertTransaction(transaction);

      final savedTx = await _db.getTransaction(transId);

      widget.onPaymentComplete();

      if (mounted && savedTx != null) {
        setState(() {
          _paymentSuccess = true;
          _completedTransaction = savedTx;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _paymentFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }


  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryYellow),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: _paymentSuccess ? null : _buildPaymentTitle(),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: _paymentSuccess ? _buildSuccessContent() : _buildPaymentContent(),
        ),
      ),
      actions: _paymentSuccess ? null : [_buildPaymentButton()],
    );
  }

  Widget _buildPaymentTitle() {
    return Row(
      children: [
        const Icon(Icons.payments_rounded, color: AppTheme.primaryYellowDark),
        const SizedBox(width: 8),
        const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    final tx = _completedTransaction!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0x1A4CAF50),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 56),
        ),
        const SizedBox(height: 16),
        Text(
          tx.paymentMethod == 'Kredit' ? 'Piutang Tersimpan!' : 'Pembayaran Berhasil!',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),

        // Transaction summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _summaryRow('Total Belanja', CurrencyHelper.format(tx.totalAmount)),
              const SizedBox(height: 6),
              _summaryRow('Metode', tx.paymentMethod),
              if (tx.paymentMethod == 'Kredit') ...[
                const SizedBox(height: 6),
                _summaryRow('DP / Bayar', CurrencyHelper.format(tx.paymentAmount)),
                const Divider(height: 16),
                _summaryRow(
                  'Sisa Tagihan',
                  CurrencyHelper.format(tx.remainingAmount),
                  bold: true,
                  color: AppTheme.error,
                ),
                const SizedBox(height: 4),
                _summaryRow('Jatuh Tempo', CurrencyHelper.formatDate(tx.dueDate!)),
              ] else ...[
                const SizedBox(height: 6),
                _summaryRow('Dibayar', CurrencyHelper.format(tx.paymentAmount)),
                const Divider(height: 16),
                _summaryRow(
                  'Kembalian',
                  CurrencyHelper.format(tx.changeAmount),
                  bold: true,
                  color: AppTheme.primaryYellowDark,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${tx.items.length} item • ${CurrencyHelper.formatDate(tx.date)}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
        ),
        const SizedBox(height: 20),

        // Cetak Struk button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ReceiptService.printReceipt(context, tx);
            },
            icon: const Icon(Icons.print_rounded),
            label: const Text('CETAK STRUK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Selesai', style: TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text('Total Pembayaran', style: TextStyle(color: AppTheme.textLight)),
              const SizedBox(height: 4),
              Text(
                CurrencyHelper.format(widget.totalAmount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryYellowDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Method selector
        const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Tunai', label: Text('Tunai'), icon: Icon(Icons.money, size: 16)),
              ButtonSegment(value: 'Transfer', label: Text('Transfer'), icon: Icon(Icons.account_balance, size: 16)),
              ButtonSegment(value: 'Kredit', label: Text('Kredit'), icon: Icon(Icons.assignment_rounded, size: 16)),
            ],
            selected: {_paymentMethod},
            onSelectionChanged: (val) => _changePaymentMethod(val.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: WidgetStateProperty.all(const BorderSide(color: AppTheme.divider)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_paymentMethod == 'Kredit') ...[
          const Text('Data Pelanggan', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _customerNameController,
            focusNode: _nameFocusNode,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nama Pelanggan *',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'No. Kontak (Opsional)',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDueDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.primaryYellowDark),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jatuh Tempo *', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                      Text(
                        _dueDate == null ? 'Pilih Tanggal' : CurrencyHelper.formatDate(_dueDate!.toIso8601String()),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Uang Muka (DP)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ] else ...[
          const Text('Nominal Bayar', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],

        TextField(
          controller: _paymentController,
          focusNode: _paymentFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            errorText: _showError ? 'Nominal kurang dari total' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 12),

        // Quick amounts
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Uang Pas', style: TextStyle(fontSize: 12)),
              onPressed: _setExactAmount,
              backgroundColor: AppTheme.surfaceLight,
            ),
            ..._quickAmounts.map((amount) => ActionChip(
                  label: Text(CurrencyHelper.formatCompact(amount.toDouble()),
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () => _setQuickAmount(amount),
                  backgroundColor: AppTheme.surfaceLight,
                )),
          ],
        ),
        const SizedBox(height: 16),

        // Change
        if (_changeAmount >= 0 && _paymentController.text.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1A4CAF50),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4D4CAF50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kembalian', style: TextStyle(color: AppTheme.success)),
                Text(
                  CurrencyHelper.format(_changeAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primaryYellow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('PROSES PEMBAYARAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  static Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(value, style: TextStyle(
          fontSize: bold ? 16 : 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color,
        )),
      ],
    );
  }
}
