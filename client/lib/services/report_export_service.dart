import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/purchase_order_form_controller.dart';
import '../controllers/purchase_return_form_controller.dart';
import '../controllers/purchase_voucher_controller.dart';
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

    final itemRows = c.items.where((r) => r.productId.value != null).map((row) {
      final qty      = double.tryParse(row.quantity.value) ?? 0;
      final used     = double.tryParse(row.usedQty.value)  ?? 0;
      final wo       = double.tryParse(row.writeoffQty.value) ?? 0;
      final left     = double.tryParse(row.leftQty.value)  ?? 0;
      final price    = double.tryParse(row.price.value)    ?? 0;
      final disc     = double.tryParse(row.discountPercent.value) ?? 0;
      final packLabel= row.selectedPackLabel.value.trim();
      final unitDisp = packLabel.isNotEmpty ? packLabel : row.unit.value;

      // Tax breakdown from taxFieldValues
      final taxParts = row.taxFieldValues.entries
          .where((e) => (double.tryParse(e.value) ?? 0) > 0)
          .map((e) => '${e.key} ${e.value}%')
          .join(', ');

      return <String>[
        row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(),
        row.hsnCode.value.trim().isEmpty ? '-' : row.hsnCode.value.trim(),
        unitDisp,
        qty.toStringAsFixed(2),
        used > 0 ? used.toStringAsFixed(1) : '-',
        wo   > 0 ? wo.toStringAsFixed(1)   : '-',
        left > 0 ? left.toStringAsFixed(1) : '-',
        price.toStringAsFixed(2),
        disc > 0 ? '${disc.toStringAsFixed(1)}%' : '-',
        taxParts.isEmpty ? (row.taxPercent.value.trim().isEmpty ? '-' : '${row.taxPercent.value}%') : taxParts,
        row.priceInclTax.toStringAsFixed(2),
        row.lineTotalExclTax.toStringAsFixed(2),
        row.lineTotal.toStringAsFixed(2),
        row.description.value.trim().isEmpty ? '-' : row.description.value.trim(),
      ];
    }).toList();

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      build: (ctx) => [
        // ── Header banner ──
        pw.Container(
          decoration: const pw.BoxDecoration(color: PdfColors.grey800, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('SALES ORDER', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text('Order Confirmation', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(soNo, style: pw.TextStyle(fontSize: 12, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              pw.Text(_normalizeDate(c.docDate.value), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
              pw.Text(c.status.value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 10),

        // ── Customer | Order Details ──
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: _infoBox('CUSTOMER', [
            pw.Text(c.customerName.value.trim().isEmpty ? '-' : c.customerName.value.trim(),
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            if (c.customerShopName.value.trim().isNotEmpty)
              pw.Text(c.customerShopName.value.trim(), style: const pw.TextStyle(fontSize: 9)),
            if (c.customerPhone.value.trim().isNotEmpty)
              pw.Text('Ph: ${c.customerPhone.value.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ])),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoBox('ORDER DETAILS', [
                                                   _kvSmall('Financial Year', c.financialYear.value),
            if (c.expectedDate.value.trim().isNotEmpty) _kvSmall('Expected Date', _normalizeDate(c.expectedDate.value)),
            if (c.departmentId.value != null && c.departmentId.value!.trim().isNotEmpty)
                                                   _kvSmall('Department',    c.departmentId.value!.trim()),
            if (c.narration.value.trim().isNotEmpty) _kvSmall('Narration',    c.narration.value.trim()),
          ])),
        ]),
        pw.SizedBox(height: 10),

        // ── Items ──
        _sectionTitle('ITEM DETAILS'),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
          cellStyle: const pw.TextStyle(fontSize: 6),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(2.8),
            1: const pw.FlexColumnWidth(1.1),
            2: const pw.FlexColumnWidth(1.1),
            3: const pw.FlexColumnWidth(0.9),
            4: const pw.FlexColumnWidth(0.9),
            5: const pw.FlexColumnWidth(0.8),
            6: const pw.FlexColumnWidth(0.9),
            7: const pw.FlexColumnWidth(1.2),
            8: const pw.FlexColumnWidth(0.9),
            9: const pw.FlexColumnWidth(1.4),
            10: const pw.FlexColumnWidth(1.1),
            11: const pw.FlexColumnWidth(1.3),
            12: const pw.FlexColumnWidth(1.3),
            13: const pw.FlexColumnWidth(1.5),
          },
          headers: const [
            'Product', 'HSN', 'Pack/Unit', 'Qty',
            'Used', 'W/O', 'Left',
            'Rate', 'Disc%', 'Tax Breakdown',
            'Rate+Tax', 'Taxable Amt', 'Line Total', 'Description',
          ],
          data: itemRows,
        ),
        pw.SizedBox(height: 10),

        // ── Charges + Summary ──
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: c.charges.isEmpty
                ? pw.SizedBox()
                : _infoBox('CHARGES', c.charges.map((ch) {
                    final amt = double.tryParse(ch.amount.value) ?? 0;
                    final rem = ch.remarks.value.trim();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Row(children: [
                        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text(ch.name.value, style: const pw.TextStyle(fontSize: 9)),
                          if (rem.isNotEmpty) pw.Text(rem, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                        ])),
                        pw.Text(amt.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    );
                  }).toList()),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 210,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(children: [
              _kvRight('Subtotal (excl. tax)', c.itemsSubtotalExclTax.toStringAsFixed(2)),
              if (c.sgstTotal > 0) _kvRight('SGST',  c.sgstTotal.toStringAsFixed(2)),
              if (c.cgstTotal > 0) _kvRight('CGST',  c.cgstTotal.toStringAsFixed(2)),
              if (c.igstTotal > 0) _kvRight('IGST',  c.igstTotal.toStringAsFixed(2)),
              if (c.cessTotal > 0) _kvRight('CESS',  c.cessTotal.toStringAsFixed(2)),
              if (c.roffTotal > 0) _kvRight('ROFF',  c.roffTotal.toStringAsFixed(2)),
              if (c.addOnTotal != 0) _kvRight('Add-ons / Charges', c.addOnTotal.toStringAsFixed(2)),
              pw.Divider(color: PdfColors.grey400),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(c.grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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

    final selectedItems = c.items.where((row) => row.selected.value).toList();
    final allItems = selectedItems.isNotEmpty ? selectedItems : c.items.toList();

    final itemRows = allItems.map((row) {
      final original  = double.tryParse(row.originalQty.value)  ?? 0;
      final available = double.tryParse(row.availableQty.value) ?? 0;
      final returned  = double.tryParse(row.returnedQty.value)  ?? 0;
      final price     = double.tryParse(row.unitPrice.value)    ?? 0;
      final taxable   = returned * price;
      final total     = taxable;
      return <String>[
        row.productName.value.trim().isEmpty ? '-' : row.productName.value.trim(),
        row.unitType.value,
        original.toStringAsFixed(2),
        available > 0 ? available.toStringAsFixed(2) : '-',
        returned.toStringAsFixed(2),
        price.toStringAsFixed(2),
        taxable.toStringAsFixed(2),
        total.toStringAsFixed(2),
        row.returnReason.value.trim().isEmpty ? '-' : row.returnReason.value.trim(),
        row.remarks.value.trim().isEmpty ? '-' : row.remarks.value.trim(),
      ];
    }).toList();

    // Net total
    final netTotal = double.tryParse(c.totalReturnValue) ?? 0;

    pdf.addPage(pw.MultiPage(
      theme: theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      build: (ctx) => [
        // ── Header banner ──
        pw.Container(
          decoration: pw.BoxDecoration(color: PdfColors.grey800, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('SALES RETURN', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text('Return Document', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey300)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(docNo.isEmpty ? '-' : docNo, style: pw.TextStyle(fontSize: 12, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              pw.Text(_normalizeDate(c.docDate.value), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
              pw.Text(c.status.value, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey200)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 10),

        // ── Customer | Return Details ──
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: _infoBox('CUSTOMER', [
            pw.Text(c.customerName.value.trim().isEmpty ? '-' : c.customerName.value.trim(),
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            if (c.customerShopName.value.trim().isNotEmpty)
              pw.Text(c.customerShopName.value.trim(), style: const pw.TextStyle(fontSize: 9)),
            if (c.customerPhone.value.trim().isNotEmpty)
              pw.Text('Ph: ${c.customerPhone.value.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ])),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _infoBox('RETURN DETAILS', [
            if (c.sourceSiNumber.value.trim().isNotEmpty) _kvSmall('Source Invoice', c.sourceSiNumber.value.trim()),
            if (c.reason.value.trim().isNotEmpty)         _kvSmall('Reason',         c.reason.value.trim()),
          ])),
        ]),
        pw.SizedBox(height: 10),

        // ── Items ──
        _sectionTitle('RETURNED ITEMS'),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
          cellStyle: const pw.TextStyle(fontSize: 7),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(1.0),
            2: const pw.FlexColumnWidth(1.0),
            3: const pw.FlexColumnWidth(1.0),
            4: const pw.FlexColumnWidth(1.0),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(1.2),
            7: const pw.FlexColumnWidth(1.2),
            8: const pw.FlexColumnWidth(1.8),
            9: const pw.FlexColumnWidth(1.5),
          },
          headers: const [
            'Product', 'Unit',
            'Orig Qty', 'Avail Qty', 'Ret Qty',
            'Unit Rate', 'Taxable', 'Line Total',
            'Return Reason', 'Remarks',
          ],
          data: itemRows,
        ),
        pw.SizedBox(height: 10),

        // ── Charges + Summary ──
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: c.charges.isEmpty
                ? pw.SizedBox()
                : _infoBox('CHARGES', c.charges.map((ch) {
                    final amt    = double.tryParse(ch.amount.value) ?? 0;
                    final isDisc = ch.name.value.toLowerCase().contains('discount');
                    final rem    = ch.remarks.value.trim();
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Row(children: [
                        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text(ch.name.value, style: const pw.TextStyle(fontSize: 9)),
                          if (rem.isNotEmpty) pw.Text(rem, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                        ])),
                        pw.Text('${isDisc ? '-' : ''}${amt.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    );
                  }).toList()),
          ),
          pw.SizedBox(width: 8),
          pw.Container(
            width: 210,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Column(children: [
              pw.Divider(color: PdfColors.grey400),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('NET TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(netTotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
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

  static pw.Widget _kvSmall(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(key, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
    );
  }

  static pw.Widget _infoBox(String title, List<pw.Widget> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        ...rows,
      ]),
    );
  }
}
