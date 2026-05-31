import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:intl/intl.dart';

class PdfExportHelper {
  static Future<void> exportPurchaseList(String title, List<Purchase> purchases) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('Generated: ${timeFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 15),
          // Table
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Reference No', 'Supplier', 'Status', 'Payment Status', 'Grand Total'],
            data: purchases.map((p) => [
              dateFormat.format(p.purchaseDate),
              p.referenceNo,
              p.supplier?.name ?? 'Walk-in',
              p.status,
              p.paymentStatus,
              p.grandTotal.toStringAsFixed(2),
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 22,
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(3.5),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2.5),
              5: const pw.FlexColumnWidth(2.5),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${title.toLowerCase().replaceAll(' ', '_')}_report.pdf',
    );
  }

  static Future<void> exportPurchaseDetail(Purchase purchase) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Invoice Title Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INVOICE / RECEIPT', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text('Type: ${purchase.type}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Reference: ${purchase.referenceNo}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${dateFormat.format(purchase.purchaseDate)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          pw.SizedBox(height: 15),
          // Billing/Supplier info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Supplier Information:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text(purchase.supplier?.name ?? 'Walk-in', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Status Information:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    pw.SizedBox(height: 4),
                    pw.Text('Delivery Status: ${purchase.status}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Payment Status: ${purchase.paymentStatus}', style: const pw.TextStyle(fontSize: 10)),
                    if (purchase.paymentMethod != null)
                      pw.Text('Payment Method: ${purchase.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 25),
          // Table of items
          pw.Text('Purchase Items:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Product Name', 'Code', 'Unit Cost', 'Qty', 'Subtotal'],
            data: List.generate(purchase.items.length, (idx) {
              final item = purchase.items[idx];
              return [
                (idx + 1).toString(),
                item.product?.name ?? 'Unknown',
                item.product?.code ?? '',
                item.unitCost.toStringAsFixed(2),
                item.quantity.toString(),
                item.subtotal.toStringAsFixed(2),
              ];
            }),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 20,
            cellStyle: const pw.TextStyle(fontSize: 9),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FixedColumnWidth(40),
              5: const pw.FlexColumnWidth(2.5),
            },
          ),
          pw.SizedBox(height: 15),
          // Total Summary Block
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 180,
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Grand Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text(purchase.grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Paid Amount:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text(purchase.paidAmount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Due Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red800)),
                      pw.Text(purchase.dueAmount.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.red800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 25),
          if (purchase.note != null && purchase.note!.isNotEmpty) ...[
            pw.Text('Note:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(purchase.note!, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${purchase.referenceNo.toLowerCase()}_invoice.pdf',
    );
  }

  static Future<void> exportSystemReport(String title, Map<String, dynamic> summaryData) async {
    final pdf = pw.Document();
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm');

    final double totalRevenue = summaryData['totalRevenue'];
    final double totalSpend = summaryData['totalSpend'];
    final double totalProfit = summaryData['totalProfit'];
    final double totalReturns = summaryData['totalReturns'];
    final List<Map<String, dynamic>> monthlyData = summaryData['monthlyData'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('Generated: ${timeFormat.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('System Overview', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Revenue (Sales)')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(totalRevenue.toStringAsFixed(2))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Spend (Purchases)')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(totalSpend.toStringAsFixed(2))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Gross Profit')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(totalProfit.toStringAsFixed(2))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Returns (Sales + Purchases)')),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(totalReturns.toStringAsFixed(2))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text('Monthly Performance (Last 6 Months)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Period', 'Revenue', 'Spend'],
            data: monthlyData.map((m) => [
              m['period'].toString(),
              (m['sales'] as double).toStringAsFixed(2),
              (m['spend'] as double).toStringAsFixed(2),
            ]).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 22,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'system_dashboard_report.pdf',
    );
  }
}
