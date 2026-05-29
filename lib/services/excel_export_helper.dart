import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ims_pos_system/models/purchase.dart';
import 'package:intl/intl.dart';

class ExcelExportHelper {
  static Future<void> exportPurchaseList(String title, List<Purchase> purchases) async {
    try {
      final excel = Excel.createExcel();
      // Retrieve the default sheet
      final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
      final sheet = excel[sheetName];
      
      // Title Block
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue(title);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
      
      // Headers
      final headers = ['Date', 'Reference No', 'Supplier', 'Status', 'Payment Status', 'Grand Total'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
        cell.value = TextCellValue(headers[i]);
      }
      
      // Data
      final dateFormat = DateFormat('yyyy-MM-dd');
      for (var r = 0; r < purchases.length; r++) {
        final p = purchases[r];
        final rowIndex = 4 + r;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(dateFormat.format(p.purchaseDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(p.referenceNo);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(p.supplier?.name ?? 'Walk-in');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(p.status);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = TextCellValue(p.paymentStatus);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(p.grandTotal);
      }
      
      // Save file
      final bytes = excel.encode();
      if (bytes == null) return;
      
      final fileName = '${title.toLowerCase().replaceAll(' ', '_')}_export.xlsx';
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
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('TRANSACTION INVOICE');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = TextCellValue('Reference: ${purchase.referenceNo}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value = TextCellValue('Date: ${dateFormat.format(purchase.purchaseDate)}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = TextCellValue('Type: ${purchase.type}');
      
      // Supplier Block
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value = TextCellValue('Supplier Information:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value = TextCellValue('Name: ${purchase.supplier?.name ?? 'Walk-in'}');
      
      // Status Block
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 5)).value = TextCellValue('Status Information:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 6)).value = TextCellValue('Delivery Status: ${purchase.status}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 7)).value = TextCellValue('Payment Status: ${purchase.paymentStatus}');
      if (purchase.paymentMethod != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 8)).value = TextCellValue('Payment Method: ${purchase.paymentMethod}');
      }
      
      // Items Header
      final headers = ['#', 'Product Name', 'Product Code', 'Unit Cost', 'Quantity', 'Subtotal'];
      const itemHeaderRow = 10;
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: itemHeaderRow)).value = TextCellValue(headers[i]);
      }
      
      // Items Data
      for (var idx = 0; idx < purchase.items.length; idx++) {
        final item = purchase.items[idx];
        final row = itemHeaderRow + 1 + idx;
        
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = IntCellValue(idx + 1);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(item.product?.name ?? 'Unknown');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(item.product?.code ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = DoubleCellValue(item.unitCost);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = IntCellValue(item.quantity);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = DoubleCellValue(item.subtotal);
      }
      
      // Summary
      final totalRow = itemHeaderRow + 1 + purchase.items.length + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow)).value = TextCellValue('Grand Total:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow)).value = DoubleCellValue(purchase.grandTotal);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow + 1)).value = TextCellValue('Paid Amount:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 1)).value = DoubleCellValue(purchase.paidAmount);
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow + 2)).value = TextCellValue('Due Amount:');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 2)).value = DoubleCellValue(purchase.dueAmount);
      
      if (purchase.note != null && purchase.note!.isNotEmpty) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow + 4)).value = TextCellValue('Note: ${purchase.note}');
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
}
