import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:intl/intl.dart';

class ExcelExportHelper {
  static Future<void> exportPurchaseList(
    String title,
    List<Purchase> purchases,
  ) async {
    try {
      final excel = Excel.createExcel();
      // Retrieve the default sheet
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      // Title Block
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        title,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      // Headers with yellow background
      final headers = [
        'Date',
        'Reference No',
        'Supplier',
        'Status',
        'Payment Status',
        'Grand Total',
      ];
      final yellowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFF00'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
        bold: true,
      );

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = yellowStyle;
      }

      // Data
      final dateFormat = DateFormat('yyyy-MM-dd');
      double totalGrandTotal = 0;

      for (var r = 0; r < purchases.length; r++) {
        final p = purchases[r];
        final rowIndex = 4 + r;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          dateFormat.format(p.purchaseDate),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          p.referenceNo,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          p.supplier?.name ?? 'Walk-in',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          p.status,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          p.paymentStatus,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = DoubleCellValue(
          p.grandTotal,
        );

        totalGrandTotal += p.grandTotal;
      }

      // Total row with yellow background
      final totalRowIndex = 4 + purchases.length;
      final totalStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFF00'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
        bold: true,
      );

      final totalLabelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRowIndex),
      );
      totalLabelCell.value = TextCellValue('TOTAL:');
      totalLabelCell.cellStyle = totalStyle;

      final totalValueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRowIndex),
      );
      totalValueCell.value = DoubleCellValue(totalGrandTotal);
      totalValueCell.cellStyle = totalStyle;

      // Save file
      final bytes = excel.encode();
      if (bytes == null) return;

      final fileName =
          '${title.toLowerCase().replaceAll(' ', '_')}_export.xlsx';
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel Report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> exportPurchaseDetail(Purchase purchase) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      // Invoice Header
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = TextCellValue(
        'TRANSACTION INVOICE',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = TextCellValue(
        'Reference: ${purchase.referenceNo}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
          .value = TextCellValue(
        'Date: ${dateFormat.format(purchase.purchaseDate)}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
          .value = TextCellValue(
        'Type: ${purchase.type}',
      );

      // Supplier Block
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
          .value = TextCellValue(
        'Supplier Information:',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
          .value = TextCellValue(
        'Name: ${purchase.supplier?.name ?? 'Walk-in'}',
      );

      // Status Block
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 5))
          .value = TextCellValue(
        'Status Information:',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 6))
          .value = TextCellValue(
        'Delivery Status: ${purchase.status}',
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 7))
          .value = TextCellValue(
        'Payment Status: ${purchase.paymentStatus}',
      );
      if (purchase.paymentMethod != null) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 8))
            .value = TextCellValue(
          'Payment Method: ${purchase.paymentMethod}',
        );
      }

      // Items Header
      final headers = [
        '#',
        'Product Name',
        'Product Code',
        'Unit Cost',
        'Quantity',
        'Subtotal',
      ];
      const itemHeaderRow = 10;

      final yellowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFF00'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
        bold: true,
      );

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: itemHeaderRow),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = yellowStyle;
      }

      // Items Data
      for (var idx = 0; idx < purchase.items.length; idx++) {
        final item = purchase.items[idx];
        final row = itemHeaderRow + 1 + idx;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = IntCellValue(
          idx + 1,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(
          item.product?.name ?? 'Unknown',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(
          item.product?.code ?? '',
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = DoubleCellValue(
          item.unitCost,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = IntCellValue(
          item.quantity,
        );
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = DoubleCellValue(
          item.subtotal,
        );
      }

      // Summary
      final totalRow = itemHeaderRow + 1 + purchase.items.length + 1;

      final summaryStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFF00'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
        bold: true,
      );

      final totalLabelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow),
      );
      totalLabelCell.value = TextCellValue('Grand Total:');
      totalLabelCell.cellStyle = summaryStyle;

      final totalValueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow),
      );
      totalValueCell.value = DoubleCellValue(purchase.grandTotal);
      totalValueCell.cellStyle = summaryStyle;

      final paidLabelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow + 1),
      );
      paidLabelCell.value = TextCellValue('Paid Amount:');
      paidLabelCell.cellStyle = summaryStyle;

      final paidValueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 1),
      );
      paidValueCell.value = DoubleCellValue(purchase.paidAmount);
      paidValueCell.cellStyle = summaryStyle;

      final dueLabelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow + 2),
      );
      dueLabelCell.value = TextCellValue('Due Amount:');
      dueLabelCell.cellStyle = summaryStyle;

      final dueValueCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 2),
      );
      dueValueCell.value = DoubleCellValue(purchase.dueAmount);
      dueValueCell.cellStyle = summaryStyle;

      if (purchase.note != null && purchase.note!.isNotEmpty) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: totalRow + 4,
              ),
            )
            .value = TextCellValue(
          'Note: ${purchase.note}',
        );
      }

      // Save file
      final bytes = excel.encode();
      if (bytes == null) return;

      final fileName = '${purchase.referenceNo.toLowerCase()}_invoice.xlsx';
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Invoice Excel',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> exportSystemReport(String title, Map<String, dynamic> summaryData) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];

      final double totalRevenue = summaryData['totalRevenue'];
      final double totalSpend = summaryData['totalSpend'];
      final double totalProfit = summaryData['totalProfit'];
      final double totalReturns = summaryData['totalReturns'];
      final List<Map<String, dynamic>> monthlyData = summaryData['monthlyData'];

      // Title
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue(title);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');

      final yellowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFFF00'),
        fontColorHex: ExcelColor.fromHexString('#000000'),
        bold: true,
      );

      // Overview Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Metric');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).cellStyle = yellowStyle;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = TextCellValue('Amount');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).cellStyle = yellowStyle;

      // Overview Data
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value = TextCellValue('Total Revenue (Sales)');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value = DoubleCellValue(totalRevenue);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('Total Spend (Purchases)');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = DoubleCellValue(totalSpend);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = TextCellValue('Gross Profit');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6)).value = DoubleCellValue(totalProfit);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value = TextCellValue('Total Returns (Sales + Purchases)');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7)).value = DoubleCellValue(totalReturns);

      // Monthly Data Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value = TextCellValue('Monthly Performance');
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).value = TextCellValue('Period');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10)).cellStyle = yellowStyle;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).value = TextCellValue('Revenue');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10)).cellStyle = yellowStyle;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 10)).value = TextCellValue('Spend');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 10)).cellStyle = yellowStyle;

      // Monthly Data
      for (var i = 0; i < monthlyData.length; i++) {
        final row = 11 + i;
        final m = monthlyData[i];
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(m['period'].toString());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = DoubleCellValue(m['sales'] as double);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = DoubleCellValue(m['spend'] as double);
      }

      final bytes = excel.encode();
      if (bytes == null) return;

      final fileName = 'system_dashboard_report.xlsx';
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Dashboard Excel',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } catch (e) {
      rethrow;
    }
  }
}
