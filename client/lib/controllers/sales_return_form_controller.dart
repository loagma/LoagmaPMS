import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/sales_return_model.dart';

class SalesReturnFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? returnId;
  final bool startInViewOnly;

  final viewOnly = false.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  final currentReturnId = RxnInt();
  final orderId = RxnInt();
  final returnDate = ''.obs;
  final returnStatus = 'DRAFT'.obs;
  final reason = ''.obs;

  final items = <SalesReturnLineRow>[].obs;

  SalesReturnFormController({this.returnId, this.startInViewOnly = false});

  bool get isEditMode => currentReturnId.value != null;
  bool get isReadOnly => viewOnly.value;

  double get totalRefund => items.fold(0, (sum, row) => sum + row.refundAmount);

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    currentReturnId.value = returnId;
    final now = DateTime.now();
    returnDate.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (returnId != null) {
      loadReturn(returnId!);
    } else {
      addItem();
    }
  }

  @override
  void onClose() {
    for (final row in items) {
      row.dispose();
    }
    super.onClose();
  }

  void addItem([SalesReturnItem? item]) {
    items.add(SalesReturnLineRow.fromItem(item));
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    items[index].dispose();
    items.removeAt(index);
  }

  Future<void> loadReturn(int id) async {
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.salesReturns}/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load sales return');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to load sales return');
      }

      final raw = (data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final sr = SalesReturn.fromJson(raw);
      currentReturnId.value = sr.id;
      orderId.value = sr.orderId;
      returnDate.value = sr.returnDate;
      returnStatus.value = sr.returnStatus;
      reason.value = sr.reason ?? '';

      for (final row in items) {
        row.dispose();
      }
      items.clear();
      if (sr.items.isEmpty) {
        addItem();
      } else {
        for (final item in sr.items) {
          addItem(item);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load sales return: $e',
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

    final parsedItems = <SalesReturnItem>[];
    for (final row in items) {
      final parsed = row.toItem();
      if (parsed == null) {
        Get.snackbar(
          'Validation',
          'Fix return line values before saving',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      parsedItems.add(parsed);
    }

    final model = SalesReturn(
      id: currentReturnId.value,
      orderId: oid,
      returnDate: returnDate.value,
      returnStatus: returnStatus.value,
      reason: reason.value.trim().isEmpty ? null : reason.value.trim(),
      items: parsedItems,
    );

    try {
      isSaving.value = true;
      final uri = currentReturnId.value == null
          ? Uri.parse(ApiConfig.salesReturns)
          : Uri.parse('${ApiConfig.salesReturns}/${currentReturnId.value}');

      final response =
          await (currentReturnId.value == null
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
        currentReturnId.value = savedId;
      }
      viewOnly.value = true;
      Get.snackbar(
        'Success',
        'Sales return saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save sales return: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
}

class SalesReturnLineRow {
  final TextEditingController itemIdCtrl;
  final TextEditingController productIdCtrl;
  final TextEditingController originalQtyCtrl;
  final TextEditingController returnQtyCtrl;
  final TextEditingController refundAmountCtrl;
  final TextEditingController reasonCtrl;

  SalesReturnLineRow({
    required this.itemIdCtrl,
    required this.productIdCtrl,
    required this.originalQtyCtrl,
    required this.returnQtyCtrl,
    required this.refundAmountCtrl,
    required this.reasonCtrl,
  });

  factory SalesReturnLineRow.fromItem(SalesReturnItem? item) {
    return SalesReturnLineRow(
      itemIdCtrl: TextEditingController(text: item?.itemId?.toString() ?? ''),
      productIdCtrl: TextEditingController(
        text: item?.productId.toString() ?? '',
      ),
      originalQtyCtrl: TextEditingController(
        text: item?.originalQty.toString() ?? '',
      ),
      returnQtyCtrl: TextEditingController(
        text: item?.returnQty.toString() ?? '',
      ),
      refundAmountCtrl: TextEditingController(
        text: item?.refundAmount.toString() ?? '',
      ),
      reasonCtrl: TextEditingController(text: item?.reason ?? ''),
    );
  }

  double get refundAmount => double.tryParse(refundAmountCtrl.text.trim()) ?? 0;

  SalesReturnItem? toItem() {
    final productId = int.tryParse(productIdCtrl.text.trim());
    final originalQty = double.tryParse(originalQtyCtrl.text.trim());
    final returnQty = double.tryParse(returnQtyCtrl.text.trim());
    final refundAmount = double.tryParse(refundAmountCtrl.text.trim());

    if (productId == null ||
        originalQty == null ||
        returnQty == null ||
        refundAmount == null) {
      return null;
    }

    return SalesReturnItem(
      itemId: int.tryParse(itemIdCtrl.text.trim()),
      productId: productId,
      originalQty: originalQty,
      returnQty: returnQty,
      refundAmount: refundAmount,
      reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    );
  }

  void dispose() {
    itemIdCtrl.dispose();
    productIdCtrl.dispose();
    originalQtyCtrl.dispose();
    returnQtyCtrl.dispose();
    refundAmountCtrl.dispose();
    reasonCtrl.dispose();
  }
}
