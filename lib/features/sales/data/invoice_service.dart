import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'sale_detail.dart';

/// Generates and prints/exports an invoice PDF for a completed sale.
/// Kept separate from SalesRepository — this is presentation of already-
/// saved data, not a database concern.
class InvoiceService {
  Future<Uint8List> _buildPdf(SaleDetail sale) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Mobile Shop',
                style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Invoice', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sale #${sale.saleId}'),
                  pw.Text(_formatDate(sale.createdAt)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier: ${sale.cashierUsername}'),
                  pw.Text('Payment: ${sale.paymentMethod}'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('Item', bold: true),
                      _cell('Qty', bold: true),
                      _cell('Unit Price', bold: true),
                      _cell('Subtotal', bold: true),
                    ],
                  ),
                  for (final item in sale.items)
                    pw.TableRow(
                      children: [
                        _cell(item.productName),
                        _cell('${item.quantity}'),
                        _cell('\$${item.unitPrice.toStringAsFixed(2)}'),
                        _cell('\$${item.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: \$${sale.total.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text(
                'Thank you for your purchase.',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Opens the OS print dialog for this sale's invoice.
  Future<void> printInvoice(SaleDetail sale) async {
    await Printing.layoutPdf(onLayout: (format) => _buildPdf(sale));
  }

  /// Lets the user save/share the invoice as a PDF file instead of printing.
  Future<void> shareInvoice(SaleDetail sale) async {
    final bytes = await _buildPdf(sale);
    await Printing.sharePdf(bytes: bytes, filename: 'invoice_sale_${sale.saleId}.pdf');
  }
}
