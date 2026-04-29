import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/purchase_order_form_controller.dart';
import '../controllers/purchase_return_form_controller.dart';
import '../controllers/purchase_voucher_controller.dart';
import '../controllers/sales_invoice_controller.dart';
import '../controllers/sales_order_form_controller.dart';
import '../controllers/sales_return_form_controller.dart';

class ReportExportService {
  static Future<pw.ThemeData> _pdfTheme() async {
    final regularData = await rootBundle.load('lib/assets/fonts/arial.ttf');
    final boldData = await rootBundle.load('lib/assets/fonts/arialbd.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  static String _normalizeDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '-';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      if (text.length >= 10) return text.substring(0, 10);
      return text;
    }
    final local = parsed.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  static Future<void> printPurchaseVoucher(
    PurchaseVoucherController controller,
  ) async {
    final bytes = await buildPurchaseVoucherPdf(controller);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> sharePurchaseVoucher(
    PurchaseVoucherController controller,
  ) async {
    final bytes = await buildPurchaseVoucherPdf(controller);
    final docNo =
        '${controller.docNoPrefix.value}${controller.docNoNumber.value}'.trim();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: 'purchase_voucher_${docNo.isEmpty ? 'report' : docNo}.pdf',
      ),
    ], text: 'Purchase Voucher ${docNo.isEmpty ? '' : docNo}'.trim());
  }

  static Future<void> printPurchaseOrder(
    PurchaseOrderFormController controller,
  ) async {
    final bytes = await buildPurchaseOrderPdf(controller);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> sharePurchaseOrder(
    PurchaseOrderFormController controller,
  ) async {
    final bytes = await buildPurchaseOrderPdf(controller);
    final poNumber = controller.currentPoNumber.value.trim().isEmpty
        ? (controller.currentPoSeq.value?.toString() ?? 'report')
        : controller.currentPoNumber.value.trim();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: 'purchase_order_$poNumber.pdf',
      ),
    ], text: 'Purchase Order $poNumber');
  }

  static Future<void> printPurchaseReturn(
    PurchaseReturnFormController controller,
  ) async {
    final bytes = await buildPurchaseReturnPdf(controller);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> sharePurchaseReturn(
    PurchaseReturnFormController controller,
  ) async {
    final bytes = await buildPurchaseReturnPdf(controller);
    final docNo =
        '${controller.docNoPrefix.value}${controller.docNoNumber.value}'.trim();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: 'purchase_return_${docNo.isEmpty ? 'report' : docNo}.pdf',
      ),
    ], text: 'Purchase Return ${docNo.isEmpty ? '' : docNo}'.trim());
  }

  static Future<Uint8List> buildPurchaseVoucherPdf(
    PurchaseVoucherController controller,
  ) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();

    final docNo =
        '${controller.docNoPrefix.value}${controller.docNoNumber.value}'.trim();
    final linkedPo = controller.linkedPoNumbers.join(', ');

    final rows = controller.items.map((row) {
      final qty = double.tryParse(row.quantity.value) ?? 0;
      final unitPrice = double.tryParse(row.unitPrice.value) ?? 0;
      final taxable =
          double.tryParse(row.taxableAmount.value) ?? (qty * unitPrice);
      final sgst = double.tryParse(row.sgst.value) ?? 0;
      final cgst = double.tryParse(row.cgst.value) ?? 0;
      final igst = double.tryParse(row.igst.value) ?? 0;
      final cess = double.tryParse(row.cess.value) ?? 0;
      final roff = double.tryParse(row.roff.value) ?? 0;
      final total =
          double.tryParse(row.value.value) ??
          (taxable + sgst + cgst + igst + cess + roff);
      final used = double.tryParse(row.usedQty.value) ?? 0;
      final left = double.tryParse(row.leftQty.value) ?? 0;
      final writeoff = double.tryParse(row.writeoffQty.value) ?? 0;
      final overrun = double.tryParse(row.overrunQty.value) ?? 0;
      return <String>[
        row.productName.value.trim().isEmpty
            ? '-'
            : row.productName.value.trim(),
        row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim(),
        row.unitType.value.trim().isEmpty ? '-' : row.unitType.value.trim(),
        qty.toStringAsFixed(1),
        unitPrice.toStringAsFixed(2),
        taxable.toStringAsFixed(2),
        sgst.toStringAsFixed(2),
        cgst.toStringAsFixed(2),
        igst.toStringAsFixed(2),
        cess.toStringAsFixed(2),
        roff.toStringAsFixed(2),
        total.toStringAsFixed(2),
        row.sourcePoNumber.value.trim().isEmpty
            ? '-'
            : row.sourcePoNumber.value.trim(),
        used.toStringAsFixed(1),
        left.toStringAsFixed(1),
        writeoff.toStringAsFixed(1),
        overrun.toStringAsFixed(1),
      ];
    }).toList();

    final charges = controller.charges.map((charge) {
      final amount = double.tryParse(charge.amount.value) ?? 0;
      return <String>[charge.name.value, amount.toStringAsFixed(2)];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Purchase Voucher',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _kv('Voucher No', docNo.isEmpty ? '-' : docNo),
          _kv('Status', controller.status.value),
          _kv(
            'Supplier',
            controller.vendorName.value.trim().isEmpty
                ? '-'
                : controller.vendorName.value.trim(),
          ),
          _kv('Document Date', _normalizeDate(controller.docDate.value)),
          _kv(
            'Bill No',
            controller.billNo.value.trim().isEmpty
                ? '-'
                : controller.billNo.value.trim(),
          ),
          _kv('Bill Date', _normalizeDate(controller.billDate.value)),
          _kv(
            'Purchase Type',
            controller.purchaseType.value.trim().isEmpty
                ? '-'
                : controller.purchaseType.value.trim(),
          ),
          _kv(
            'GST Reverse Charge',
            controller.gstReverseCharge.value.trim().isEmpty
                ? '-'
                : controller.gstReverseCharge.value.trim(),
          ),
          _kv(
            'Purchase Agent',
            controller.purchaseAgentId.value.trim().isEmpty
                ? '-'
                : controller.purchaseAgentId.value.trim(),
          ),
          _kv('Linked PO', linkedPo.isEmpty ? '-' : linkedPo),
          pw.SizedBox(height: 12),
          pw.Text(
            'Item Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Product',
              'HSN',
              'Unit',
              'Qty',
              'Rate',
              'Taxable',
              'SGST',
              'CGST',
              'IGST',
              'CESS',
              'ROFF',
              'Total',
              'PO',
              'Used',
              'Left',
              'WO',
              'Over',
            ],
            data: rows,
          ),
          if (charges.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Charges',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['Name', 'Amount'],
              data: charges,
            ),
          ],
          pw.SizedBox(height: 12),
          _kv('Net Total', controller.netTotal),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> buildPurchaseOrderPdf(
    PurchaseOrderFormController controller,
  ) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();

    final poNumber = controller.currentPoNumber.value.trim().isEmpty
        ? (controller.currentPoSeq.value?.toString() ?? '-')
        : controller.currentPoNumber.value.trim();

    final supplier = controller.suppliers.firstWhere(
      (s) => s['id'] == controller.supplierId.value,
      orElse: () => <String, dynamic>{},
    );
    final supplierName = supplier['supplier_name']?.toString() ?? '-';

    final rows = controller.items.map((row) {
      final qty = double.tryParse(row.quantity.value) ?? 0;
      final used = double.tryParse(row.usedQty.value) ?? 0;
      final writeoff = double.tryParse(row.writeoffQty.value) ?? 0;
      final left = double.tryParse(row.leftQty.value) ?? 0;
      final price = double.tryParse(row.price.value) ?? 0;
      final discount = double.tryParse(row.discountPercent.value) ?? 0;
      final tax = double.tryParse(row.taxPercent.value) ?? 0;
      return <String>[
        row.productName.value.trim().isEmpty
            ? '-'
            : row.productName.value.trim(),
        row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim(),
        row.unit.value.trim().isEmpty ? '-' : row.unit.value.trim(),
        qty.toStringAsFixed(1),
        used.toStringAsFixed(1),
        writeoff.toStringAsFixed(1),
        left.toStringAsFixed(1),
        price.toStringAsFixed(2),
        discount.toStringAsFixed(2),
        tax.toStringAsFixed(2),
        row.priceInclTax.toStringAsFixed(2),
        row.lineTotalExclTax.toStringAsFixed(2),
        row.lineTotal.toStringAsFixed(2),
      ];
    }).toList();

    final charges = controller.charges.map((charge) {
      final amount = double.tryParse(charge.amount.value) ?? 0;
      return <String>[charge.name.value, amount.toStringAsFixed(2)];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Purchase Order',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _kv('PO Number', poNumber),
          _kv('Status', controller.status.value),
          _kv('Supplier', supplierName),
          _kv('Document Date', _normalizeDate(controller.docDate.value)),
          _kv('Expected Date', _normalizeDate(controller.expectedDate.value)),
          _kv(
            'Financial Year',
            controller.financialYear.value.trim().isEmpty
                ? '-'
                : controller.financialYear.value.trim(),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Item Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Product',
              'HSN',
              'Unit',
              'Qty',
              'Used',
              'WO',
              'Left',
              'Rate',
              'Disc%',
              'Tax%',
              'Rate+Tax',
              'Taxable',
              'Total',
            ],
            data: rows,
          ),
          if (charges.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Charges',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: const ['Name', 'Amount'],
              data: charges,
            ),
          ],
          pw.SizedBox(height: 12),
          _kv('Grand Total', controller.grandTotal.toStringAsFixed(2)),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> buildPurchaseReturnPdf(
    PurchaseReturnFormController controller,
  ) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();

    final docNo =
        '${controller.docNoPrefix.value}${controller.docNoNumber.value}'.trim();

    final rows = controller.items.map((row) {
      final received = double.tryParse(row.originalQty.value) ?? 0;
      final returned = double.tryParse(row.returnedQty.value) ?? 0;
      return <String>[
        row.productName.value.trim().isEmpty
            ? '-'
            : row.productName.value.trim(),
        received.toStringAsFixed(2),
        returned.toStringAsFixed(2),
        row.returnReason.value.trim().isEmpty
            ? '-'
            : row.returnReason.value.trim(),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Purchase Return',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _kv('Return No', docNo.isEmpty ? '-' : docNo),
          _kv('Status', controller.status.value),
          _kv(
            'Vendor',
            controller.vendorName.value.trim().isEmpty
                ? '-'
                : controller.vendorName.value.trim(),
          ),
          _kv(
            'Source Voucher',
            controller.sourcePvNumber.value.trim().isEmpty
                ? '-'
                : controller.sourcePvNumber.value.trim(),
          ),
          _kv('Document Date', _normalizeDate(controller.docDate.value)),
          _kv(
            'Reason',
            controller.reason.value.trim().isEmpty
                ? '-'
                : controller.reason.value.trim(),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Item Details',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Product', 'Received', 'Returned', 'Reason'],
            data: rows,
          ),
          pw.SizedBox(height: 12),
          _kv('Net Total', controller.totalReturnValue),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── Sales Invoice ───────────────────────────────────────────────────────────

  static Future<void> printSalesInvoice(SalesInvoiceController c) async {
    final bytes = await buildSalesInvoicePdf(c);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareSalesInvoice(SalesInvoiceController c) async {
    final bytes = await buildSalesInvoicePdf(c);
    final docNo = '${c.docNoPrefix.value}${c.docNoNumber.value}'.trim();
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'application/pdf',
          name: 'sales_invoice_${docNo.isEmpty ? 'report' : docNo}.pdf'),
    ], text: 'Sales Invoice ${docNo.isEmpty ? '' : docNo}'.trim());
  }

  static Future<Uint8List> buildSalesInvoicePdf(SalesInvoiceController c) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();
    final docNo = '${c.docNoPrefix.value}${c.docNoNumber.value}'.trim();

    final rows = c.items.map((row) {
      final qty = double.tryParse(row.quantity.value) ?? 0;
      final rate = double.tryParse(row.unitPrice.value) ?? 0;
      final taxable = double.tryParse(row.taxableAmount.value) ?? (qty * rate);
      final sgst = double.tryParse(row.sgst.value) ?? 0;
      final cgst = double.tryParse(row.cgst.value) ?? 0;
      final igst = double.tryParse(row.igst.value) ?? 0;
      final cess = double.tryParse(row.cess.value) ?? 0;
      final roff = double.tryParse(row.roff.value) ?? 0;
      final total = double.tryParse(row.value.value) ?? (taxable + sgst + cgst + igst + cess + roff);
      return <String>[
        row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(),
        row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim(),
        row.unitType.value,
        qty.toStringAsFixed(2),
        rate.toStringAsFixed(2),
        taxable.toStringAsFixed(2),
        sgst.toStringAsFixed(2),
        cgst.toStringAsFixed(2),
        igst.toStringAsFixed(2),
        cess.toStringAsFixed(2),
        roff.toStringAsFixed(2),
        total.toStringAsFixed(2),
      ];
    }).toList();

    // Tax summary totals
    double totalSgst = 0, totalCgst = 0, totalIgst = 0, totalCess = 0, totalRoff = 0, grandTotal = 0;
    for (final row in c.items) {
      totalSgst += double.tryParse(row.sgst.value) ?? 0;
      totalCgst += double.tryParse(row.cgst.value) ?? 0;
      totalIgst += double.tryParse(row.igst.value) ?? 0;
      totalCess += double.tryParse(row.cess.value) ?? 0;
      totalRoff += double.tryParse(row.roff.value) ?? 0;
      grandTotal += double.tryParse(row.value.value) ?? 0;
    }
    for (final ch in c.charges) {
      final amt = double.tryParse(ch.amount.value) ?? 0;
      grandTotal += ch.name.value.toLowerCase().contains('discount') ? -amt : amt;
    }

    final linkedSo = c.linkedSoNumbers.join(', ');

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      build: (ctx) => [
        // Title row
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey800,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TAX INVOICE',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('No: ${docNo.isEmpty ? '-' : docNo}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${_normalizeDate(c.docDate.value)}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
                pw.Text('Status: ${c.status.value}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Billed To / Bill Details
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Billed To', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 3),
                pw.Text(c.customerName.value.trim().isEmpty ? '-' : c.customerName.value.trim(),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (c.customerShopName.value.trim().isNotEmpty)
                  pw.Text(c.customerShopName.value.trim(), style: const pw.TextStyle(fontSize: 9)),
                if (c.customerPhone.value.trim().isNotEmpty)
                  pw.Text('Ph: ${c.customerPhone.value.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Invoice Details', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 3),
                if (c.billNo.value.trim().isNotEmpty) _kv('Bill No', c.billNo.value.trim()),
                if (c.billDate.value.trim().isNotEmpty) _kv('Bill Date', _normalizeDate(c.billDate.value)),
                _kv('Sale Type', c.saleType.value.trim().isEmpty ? '-' : c.saleType.value.trim()),
                if (linkedSo.isNotEmpty) _kv('Linked SO', linkedSo),
              ]),
            ),
          ),
        ]),
        pw.SizedBox(height: 10),

        // Items table
        pw.Text('Items', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
          cellStyle: const pw.TextStyle(fontSize: 7),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.5),
            6: const pw.FlexColumnWidth(1.2),
            7: const pw.FlexColumnWidth(1.2),
            8: const pw.FlexColumnWidth(1.2),
            9: const pw.FlexColumnWidth(1),
            10: const pw.FlexColumnWidth(1),
            11: const pw.FlexColumnWidth(1.5),
          },
          headers: const ['Product', 'HSN', 'Unit', 'Qty', 'Rate', 'Taxable', 'SGST', 'CGST', 'IGST', 'CESS', 'ROFF', 'Total'],
          data: rows,
        ),
        pw.SizedBox(height: 8),

        // Charges + Tax summary aligned right
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: c.charges.isEmpty ? pw.SizedBox() : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Charges', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                ...c.charges.map((ch) {
                  final amt = double.tryParse(ch.amount.value) ?? 0;
                  final isDisc = ch.name.value.toLowerCase().contains('discount');
                  return pw.Row(children: [
                    pw.Expanded(child: pw.Text(ch.name.value, style: const pw.TextStyle(fontSize: 9))),
                    pw.Text('${isDisc ? '-' : ''}${amt.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                  ]);
                }),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(children: [
              if (totalSgst > 0) _kvRight('SGST', totalSgst.toStringAsFixed(2)),
              if (totalCgst > 0) _kvRight('CGST', totalCgst.toStringAsFixed(2)),
              if (totalIgst > 0) _kvRight('IGST', totalIgst.toStringAsFixed(2)),
              if (totalCess > 0) _kvRight('CESS', totalCess.toStringAsFixed(2)),
              if (totalRoff > 0) _kvRight('ROFF', totalRoff.toStringAsFixed(2)),
              pw.Divider(color: PdfColors.grey400),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Net Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(grandTotal.toStringAsFixed(2),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
          ),
        ]),

        if (c.narration.value.trim().isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text('Narration: ${c.narration.value.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ],
      ],
    ));
    return pdf.save();
  }

  // ─── Sales Order ─────────────────────────────────────────────────────────────

  static Future<void> printSalesOrder(SalesOrderFormController c) async {
    final bytes = await buildSalesOrderPdf(c);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareSalesOrder(SalesOrderFormController c) async {
    final bytes = await buildSalesOrderPdf(c);
    final soNo = c.currentSoNumber.value.trim().isEmpty
        ? (c.currentSoSeq.value?.toString() ?? 'report')
        : c.currentSoNumber.value.trim();
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'application/pdf', name: 'sales_order_$soNo.pdf'),
    ], text: 'Sales Order $soNo');
  }

  static Future<Uint8List> buildSalesOrderPdf(SalesOrderFormController c) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();
    final soNo = c.currentSoNumber.value.trim().isEmpty
        ? (c.currentSoSeq.value?.toString() ?? '-')
        : c.currentSoNumber.value.trim();

    final rows = c.items.map((row) {
      final qty = double.tryParse(row.quantity.value) ?? 0;
      final price = double.tryParse(row.price.value) ?? 0;
      final disc = double.tryParse(row.discountPercent.value) ?? 0;
      return <String>[
        row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(),
        row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim(),
        row.unit.value,
        qty.toStringAsFixed(2),
        price.toStringAsFixed(2),
        disc > 0 ? '${disc.toStringAsFixed(1)}%' : '-',
        row.taxPercent.value.trim().isEmpty ? '-' : '${row.taxPercent.value}%',
        row.lineTotal.toStringAsFixed(2),
      ];
    }).toList();

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      build: (ctx) => [
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey800,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('SALES ORDER',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('No: $soNo',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${_normalizeDate(c.docDate.value)}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
              pw.Text('Status: ${c.status.value}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 10),

        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Customer', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 3),
                pw.Text(c.customerName.value.trim().isEmpty ? '-' : c.customerName.value.trim(),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (c.customerShopName.value.trim().isNotEmpty)
                  pw.Text(c.customerShopName.value.trim(), style: const pw.TextStyle(fontSize: 9)),
                if (c.customerPhone.value.trim().isNotEmpty)
                  pw.Text('Ph: ${c.customerPhone.value.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Order Details', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 3),
                _kv('Financial Year', c.financialYear.value),
                if (c.expectedDate.value.trim().isNotEmpty)
                  _kv('Expected Date', _normalizeDate(c.expectedDate.value)),
                if (c.narration.value.trim().isNotEmpty)
                  _kv('Narration', c.narration.value.trim()),
              ]),
            ),
          ),
        ]),
        pw.SizedBox(height: 10),

        pw.Text('Items', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          headers: const ['Product', 'HSN', 'Unit', 'Qty', 'Rate', 'Disc%', 'Tax%', 'Total'],
          data: rows,
        ),
        pw.SizedBox(height: 8),

        pw.Row(children: [
          pw.Spacer(),
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(children: [
              if (c.charges.isNotEmpty) ...[
                pw.Text('Charges', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                ...c.charges.map((ch) {
                  final amt = double.tryParse(ch.amount.value) ?? 0;
                  return _kvRight(ch.name.value, amt.toStringAsFixed(2));
                }),
                pw.Divider(color: PdfColors.grey400),
              ],
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Grand Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(c.grandTotal.toStringAsFixed(2),
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
          ),
        ]),
      ],
    ));
    return pdf.save();
  }

  // ─── Sales Return ─────────────────────────────────────────────────────────────

  static Future<void> printSalesReturn(SalesReturnFormController c) async {
    final bytes = await buildSalesReturnPdf(c);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareSalesReturn(SalesReturnFormController c) async {
    final bytes = await buildSalesReturnPdf(c);
    final docNo = '${c.docNoPrefix.value}${c.docNoNumber.value}'.trim();
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'application/pdf',
          name: 'sales_return_${docNo.isEmpty ? 'report' : docNo}.pdf'),
    ], text: 'Sales Return ${docNo.isEmpty ? '' : docNo}'.trim());
  }

  static Future<Uint8List> buildSalesReturnPdf(SalesReturnFormController c) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();
    final docNo = '${c.docNoPrefix.value}${c.docNoNumber.value}'.trim();

    final rows = c.items
        .where((row) => row.selected.value)
        .map((row) {
      final original = double.tryParse(row.originalQty.value) ?? 0;
      final returned = double.tryParse(row.returnedQty.value) ?? 0;
      final price = double.tryParse(row.unitPrice.value) ?? 0;
      final total = returned * price;
      return <String>[
        row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(),
        row.unitType.value,
        original.toStringAsFixed(2),
        returned.toStringAsFixed(2),
        price.toStringAsFixed(2),
        total.toStringAsFixed(2),
        row.returnReason.value.trim().isEmpty ? '-' : row.returnReason.value.trim(),
      ];
    }).toList();

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      build: (ctx) => [
        pw.Container(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey800,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('SALES RETURN',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('No: ${docNo.isEmpty ? '-' : docNo}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date: ${_normalizeDate(c.docDate.value)}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
              pw.Text('Status: ${c.status.value}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 10),

        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Customer', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 3),
                pw.Text(c.customerName.value.trim().isEmpty ? '-' : c.customerName.value.trim(),
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                if (c.customerShopName.value.trim().isNotEmpty)
                  pw.Text(c.customerShopName.value.trim(), style: const pw.TextStyle(fontSize: 9)),
                if (c.customerPhone.value.trim().isNotEmpty)
                  pw.Text('Ph: ${c.customerPhone.value.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Return Details', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                pw.SizedBox(height: 3),
                if (c.sourceSiNumber.value.trim().isNotEmpty)
                  _kv('Source Invoice', c.sourceSiNumber.value.trim()),
                if (c.reason.value.trim().isNotEmpty)
                  _kv('Reason', c.reason.value.trim()),
              ]),
            ),
          ),
        ]),
        pw.SizedBox(height: 10),

        pw.Text('Returned Items', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          headers: const ['Product', 'Unit', 'Orig Qty', 'Ret Qty', 'Rate', 'Total', 'Reason'],
          data: rows,
        ),
        pw.SizedBox(height: 8),

        pw.Row(children: [
          pw.Spacer(),
          pw.Container(
            width: 200,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(children: [
              if (c.charges.isNotEmpty) ...[
                pw.Text('Charges', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                ...c.charges.map((ch) {
                  final amt = double.tryParse(ch.amount.value) ?? 0;
                  final isDisc = ch.name.value.toLowerCase().contains('discount');
                  return _kvRight(ch.name.value, '${isDisc ? '-' : ''}${amt.toStringAsFixed(2)}');
                }),
                pw.Divider(color: PdfColors.grey400),
              ],
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Net Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(c.totalReturnValue, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ]),
            ]),
          ),
        ]),
      ],
    ));
    return pdf.save();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static pw.Widget _kv(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              key,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kvRight(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(key, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}
