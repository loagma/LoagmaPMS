import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/sales_invoice_model.dart';

class SalesInvoiceFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? invoiceId;
  final bool startInViewOnly;

  final viewOnly = false.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  final currentInvoiceId = RxnInt();
  final invoiceNo = ''.obs;
  final orderId = RxnInt();
  final customerUserId = RxnInt();
  final invoiceDate = ''.obs;
  final dueDate = ''.obs;
  final invoiceStatus = 'DRAFT'.obs;
  final paymentStatus = 'PENDING'.obs;
  final subtotal = ''.obs;
  final discountTotal = ''.obs;
  final deliveryCharge = ''.obs;
  final taxTotal = ''.obs;
  final grandTotal = ''.obs;
  final notes = ''.obs;

  SalesInvoiceFormController({this.invoiceId, this.startInViewOnly = false});

  bool get isEditMode => currentInvoiceId.value != null;
  bool get isReadOnly => viewOnly.value;

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    currentInvoiceId.value = invoiceId;
    final now = DateTime.now();
    invoiceDate.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    subtotal.value = '0';
    discountTotal.value = '0';
    deliveryCharge.value = '0';
    taxTotal.value = '0';
    grandTotal.value = '0';

    if (invoiceId != null) {
      loadInvoice(invoiceId!);
    }
  }

  Future<void> loadInvoice(int id) async {
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.salesInvoices}/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load invoice');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to load invoice');
      }

      final raw = (data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final inv = SalesInvoice.fromJson(raw);
      currentInvoiceId.value = inv.id;
      invoiceNo.value = inv.invoiceNo;
      orderId.value = inv.orderId;
      customerUserId.value = inv.customerUserId;
      invoiceDate.value = inv.invoiceDate;
      dueDate.value = inv.dueDate ?? '';
      invoiceStatus.value = inv.invoiceStatus;
      paymentStatus.value = inv.paymentStatus;
      subtotal.value = inv.subtotal.toStringAsFixed(2);
      discountTotal.value = inv.discountTotal.toStringAsFixed(2);
      deliveryCharge.value = inv.deliveryCharge.toStringAsFixed(2);
      taxTotal.value = inv.taxTotal.toStringAsFixed(2);
      grandTotal.value = inv.grandTotal.toStringAsFixed(2);
      notes.value = inv.notes ?? '';
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    final oid = orderId.value;
    if (oid == null) {
      Get.snackbar(
        'Validation',
        'Order ID is required',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    double parse(String v) => double.tryParse(v.trim()) ?? 0;

    final model = SalesInvoice(
      id: currentInvoiceId.value,
      invoiceNo: invoiceNo.value.trim(),
      orderId: oid,
      customerUserId: customerUserId.value,
      invoiceDate: invoiceDate.value,
      dueDate: dueDate.value.trim().isEmpty ? null : dueDate.value.trim(),
      invoiceStatus: invoiceStatus.value,
      paymentStatus: paymentStatus.value,
      subtotal: parse(subtotal.value),
      discountTotal: parse(discountTotal.value),
      deliveryCharge: parse(deliveryCharge.value),
      taxTotal: parse(taxTotal.value),
      grandTotal: parse(grandTotal.value),
      notes: notes.value.trim().isEmpty ? null : notes.value.trim(),
    );

    try {
      isSaving.value = true;
      final uri = currentInvoiceId.value == null
          ? Uri.parse(ApiConfig.salesInvoices)
          : Uri.parse('${ApiConfig.salesInvoices}/${currentInvoiceId.value}');

      final response =
          await (currentInvoiceId.value == null
                  ? http.post(
                      uri,
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                      },
                      body: jsonEncode(model.toJson()),
                    )
                  : http.put(
                      uri,
                      headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                      },
                      body: jsonEncode(model.toJson()),
                    ))
              .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Save failed with status ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Save failed');
      }

      final payload = data['data'] as Map<String, dynamic>?;
      final savedId = payload == null
          ? null
          : (payload['id'] is int
                ? payload['id'] as int
                : int.tryParse('${payload['id'] ?? ''}'));
      if (savedId != null) {
        currentInvoiceId.value = savedId;
      }
      viewOnly.value = true;
      Get.snackbar(
        'Success',
        'Sales invoice saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save invoice: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
