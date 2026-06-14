import '../database/firebase_database_helper.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';
import '../models/store_settings.dart';
import '../helpers/currency_helper.dart';

class ReceiptService {
  static Future<void> printReceipt(
    BuildContext context,
    SaleTransaction transaction,
  ) async {
    try {
      final StoreSettings settings =
          await FirebaseDatabaseHelper.instance.getStoreSettings();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context pdfContext) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Store header
                pw.Text(
                  settings.storeName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (settings.address.isNotEmpty)
                  pw.Text(
                    settings.address,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (settings.phone.isNotEmpty)
                  pw.Text(
                    'Telp: ${settings.phone}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),

                // Transaction info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'No: #${transaction.id.toString().padLeft(4, '0')}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      CurrencyHelper.formatDate(transaction.date),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),

                // Items
                pw.SizedBox(height: 4),
                ...transaction.items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.productName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '  ${item.quantity} x ${CurrencyHelper.format(item.price)}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              CurrencyHelper.format(item.subtotal),
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 4),

                // Totals
                _buildTotalRow(
                  'Total',
                  CurrencyHelper.format(transaction.totalAmount),
                  bold: true,
                ),
                _buildTotalRow(
                  'Bayar',
                  CurrencyHelper.format(transaction.paymentAmount),
                ),
                _buildTotalRow(
                  'Kembalian',
                  CurrencyHelper.format(transaction.changeAmount),
                ),

                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 8),

                // Footer
                pw.Text(
                  'Terima Kasih!',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Barang yang sudah dibeli tidak dapat dikembalikan',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Struk_${transaction.id}',
      );
    } catch (e) {
      debugPrint('PRINT ERROR: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mencetak struk: $e')));
      }
    }
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
