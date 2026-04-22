import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/purchase_order_form_controller.dart';
import '../controllers/purchase_return_form_controller.dart';
import '../controllers/purchase_voucher_controller.dart';
import '../controllers/sales_invoice_form_controller.dart';
import '../controllers/sales_order_form_controller.dart';

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

  static Future<void> printSalesOrder(
    SalesOrderFormController controller,
  ) async {
    final bytes = await buildSalesOrderPdf(controller);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareSalesOrder(
    SalesOrderFormController controller,
  ) async {
    final bytes = await buildSalesOrderPdf(controller);
    final orderNo = controller.currentOrderId.value?.toString() ?? 'report';
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: 'sales_order_$orderNo.pdf',
      ),
    ], text: 'Sales Order $orderNo');
  }

  static Future<void> printSalesInvoice(
    SalesInvoiceFormController controller,
  ) async {
    final bytes = await buildSalesInvoicePdf(controller);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<void> shareSalesInvoice(
    SalesInvoiceFormController controller,
  ) async {
    final bytes = await buildSalesInvoicePdf(controller);
    final invoiceNo = controller.invoiceNo.value.trim().isEmpty
        ? (controller.currentInvoiceId.value?.toString() ?? 'report')
        : controller.invoiceNo.value.trim();
    await Share.shareXFiles([
      XFile.fromData(
        bytes,
        mimeType: 'application/pdf',
        name: 'sales_invoice_$invoiceNo.pdf',
      ),
    ], text: 'Sales Invoice $invoiceNo');
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

  static Future<Uint8List> buildSalesOrderPdf(
    SalesOrderFormController controller,
  ) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();

    final orderNo = controller.currentOrderId.value?.toString() ?? '-';
    final customer = controller.customers.firstWhere(
      (c) => c['id'] == controller.customerUserId.value,
      orElse: () => <String, dynamic>{},
    );
    final customerName = customer['name']?.toString() ?? '-';

    final rows = controller.items.map((row) {
      final productId = row.productIdCtrl.text.trim().isEmpty
          ? '-'
          : row.productIdCtrl.text.trim();
      final vendorProductId = row.vendorProductIdCtrl.text.trim().isEmpty
          ? '-'
          : row.vendorProductIdCtrl.text.trim();
      final qty = double.tryParse(row.quantityCtrl.text.trim()) ?? 0;
      final rate = double.tryParse(row.itemPriceCtrl.text.trim()) ?? 0;
      return <String>[
        productId,
        vendorProductId,
        qty.toStringAsFixed(1),
        rate.toStringAsFixed(2),
        row.lineTotal.toStringAsFixed(2),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Sales Order',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _kv('Order ID', orderNo),
          _kv('State', controller.orderState.value),
          _kv('Customer', customerName),
          _kv('Payment Status', controller.paymentStatus.value),
          _kv('Payment Method', controller.paymentMethod.value),
          _kv('Order Date', _normalizeDate(controller.orderDate.value)),
          if (controller.remarks.value.trim().isNotEmpty)
            _kv('Remarks', controller.remarks.value.trim()),
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
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const [
              'Product',
              'Vendor Product',
              'Qty',
              'Rate',
              'Total',
            ],
            data: rows,
          ),
          pw.SizedBox(height: 12),
          _kv('Subtotal', controller.subtotal.toStringAsFixed(2)),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> buildSalesInvoicePdf(
    SalesInvoiceFormController controller,
  ) async {
    final pdf = pw.Document();
    final theme = await _pdfTheme();

    final invoiceNo = controller.invoiceNo.value.trim().isEmpty
        ? (controller.currentInvoiceId.value?.toString() ?? '-')
        : controller.invoiceNo.value.trim();
    final customer = controller.customers.firstWhere(
      (c) => c['id'] == controller.customerUserId.value,
      orElse: () => <String, dynamic>{},
    );
    final customerName = customer['name']?.toString() ?? '-';

    final orderRef = controller.salesOrders.firstWhere(
      (o) => o['order_id'] == controller.orderId.value,
      orElse: () => <String, dynamic>{},
    );
    final orderLabel = orderRef['order_id']?.toString() ?? '-';

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Sales Invoice',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _kv('Invoice No', invoiceNo),
          _kv('Order ID', orderLabel),
          _kv('Customer', customerName),
          _kv('Invoice Status', controller.invoiceStatus.value),
          _kv('Payment Status', controller.paymentStatus.value),
          _kv('Invoice Date', _normalizeDate(controller.invoiceDate.value)),
          _kv('Due Date', _normalizeDate(controller.dueDate.value)),
          if (controller.notes.value.trim().isNotEmpty)
            _kv('Notes', controller.notes.value.trim()),
          pw.SizedBox(height: 12),
          pw.Text(
            'Totals',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headers: const ['Field', 'Amount'],
            data: [
              ['Subtotal', controller.subtotal.value],
              ['Discount', controller.discountTotal.value],
              ['Delivery Charge', controller.deliveryCharge.value],
              ['Tax', controller.taxTotal.value],
              ['Grand Total', controller.grandTotal.value],
            ],
          ),
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
}
