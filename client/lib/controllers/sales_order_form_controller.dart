import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/sales_order_model.dart';

class SalesOrderFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? orderId;
  final bool startInViewOnly;

  final viewOnly = false.obs;
  final isLoading = false.obs;
  final isSaving = false.obs;

  final currentOrderId = RxnInt();
  final customerUserId = RxnInt();
  final orderDate = ''.obs;
  final orderState = 'registered'.obs;
  final paymentStatus = 'not_paid'.obs;
  final paymentMethod = 'cod'.obs;
  final remarks = ''.obs;

  final items = <SalesOrderLineRow>[].obs;

  SalesOrderFormController({this.orderId, this.startInViewOnly = false});

  bool get isEditMode => currentOrderId.value != null;
  bool get isReadOnly => viewOnly.value;

  double get subtotal => items.fold(0, (sum, row) => sum + row.lineTotal);

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    final now = DateTime.now();
    orderDate.value =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    currentOrderId.value = orderId;

    if (orderId != null) {
      loadOrder(orderId!);
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

  void addItem([SalesOrderItem? item]) {
    items.add(SalesOrderLineRow.fromItem(item));
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    items[index].dispose();
    items.removeAt(index);
  }

  Future<void> loadOrder(int id) async {
    try {
      isLoading.value = true;
      final response = await http
          .get(
            Uri.parse('${ApiConfig.salesOrders}/$id'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Failed to load sales order');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to load sales order');
      }

      final raw = (data['data'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      final order = SalesOrder.fromJson(raw);

      currentOrderId.value = order.orderId;
      customerUserId.value = order.customerUserId;
      orderDate.value = order.orderDate ?? orderDate.value;
      orderState.value = order.orderState;
      paymentStatus.value = order.paymentStatus;
      paymentMethod.value = order.paymentMethod;
      remarks.value = order.remarks ?? '';

      for (final row in items) {
        row.dispose();
      }
      items.clear();
      if (order.items.isEmpty) {
        addItem();
      } else {
        for (final item in order.items) {
          addItem(item);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load sales order: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (items.isEmpty) {
      Get.snackbar(
        'Validation',
        'Add at least one line item',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final parsedItems = <SalesOrderItem>[];
    for (final row in items) {
      final parsed = row.toItem();
      if (parsed == null) {
        Get.snackbar(
          'Validation',
          'Fix line item values before saving',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      parsedItems.add(parsed);
    }

    final model = SalesOrder(
      orderId: currentOrderId.value,
      customerUserId: customerUserId.value,
      orderState: orderState.value,
      paymentStatus: paymentStatus.value,
      paymentMethod: paymentMethod.value,
      orderDate: orderDate.value,
      remarks: remarks.value.trim().isEmpty ? null : remarks.value.trim(),
      items: parsedItems,
    );

    try {
      isSaving.value = true;
      final uri = currentOrderId.value == null
          ? Uri.parse(ApiConfig.salesOrders)
          : Uri.parse('${ApiConfig.salesOrders}/${currentOrderId.value}');

      final response =
          await (currentOrderId.value == null
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
          : (payload['order_id'] is int
                ? payload['order_id'] as int
                : int.tryParse(
                    '${payload['order_id'] ?? payload['id'] ?? ''}',
                  ));
      if (savedId != null) {
        currentOrderId.value = savedId;
      }
      viewOnly.value = true;
      Get.snackbar(
        'Success',
        'Sales order saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save sales order: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
}

class SalesOrderLineRow {
  final TextEditingController itemIdCtrl;
  final TextEditingController productIdCtrl;
  final TextEditingController vendorProductIdCtrl;
  final TextEditingController quantityCtrl;
  final TextEditingController qtyLoadedCtrl;
  final TextEditingController qtyDeliveredCtrl;
  final TextEditingController qtyReturnedCtrl;
  final TextEditingController itemPriceCtrl;

  SalesOrderLineRow({
    required this.itemIdCtrl,
    required this.productIdCtrl,
    required this.vendorProductIdCtrl,
    required this.quantityCtrl,
    required this.qtyLoadedCtrl,
    required this.qtyDeliveredCtrl,
    required this.qtyReturnedCtrl,
    required this.itemPriceCtrl,
  });

  factory SalesOrderLineRow.fromItem(SalesOrderItem? item) {
    return SalesOrderLineRow(
      itemIdCtrl: TextEditingController(text: item?.itemId?.toString() ?? ''),
      productIdCtrl: TextEditingController(
        text: item?.productId.toString() ?? '',
      ),
      vendorProductIdCtrl: TextEditingController(
        text: item?.vendorProductId?.toString() ?? '',
      ),
      quantityCtrl: TextEditingController(
        text: item?.quantity.toString() ?? '',
      ),
      qtyLoadedCtrl: TextEditingController(
        text: item?.qtyLoaded.toString() ?? '0',
      ),
      qtyDeliveredCtrl: TextEditingController(
        text: item?.qtyDelivered.toString() ?? '0',
      ),
      qtyReturnedCtrl: TextEditingController(
        text: item?.qtyReturned.toString() ?? '0',
      ),
      itemPriceCtrl: TextEditingController(
        text: item?.itemPrice.toString() ?? '',
      ),
    );
  }

  double get quantity => double.tryParse(quantityCtrl.text.trim()) ?? 0;
  double get itemPrice => double.tryParse(itemPriceCtrl.text.trim()) ?? 0;
  double get lineTotal => quantity * itemPrice;

  SalesOrderItem? toItem() {
    final productId = int.tryParse(productIdCtrl.text.trim());
    final quantity = double.tryParse(quantityCtrl.text.trim());
    final itemPrice = double.tryParse(itemPriceCtrl.text.trim());

    if (productId == null || quantity == null || itemPrice == null) {
      return null;
    }

    return SalesOrderItem(
      itemId: int.tryParse(itemIdCtrl.text.trim()),
      productId: productId,
      vendorProductId: int.tryParse(vendorProductIdCtrl.text.trim()),
      quantity: quantity,
      qtyLoaded: double.tryParse(qtyLoadedCtrl.text.trim()) ?? 0,
      qtyDelivered: double.tryParse(qtyDeliveredCtrl.text.trim()) ?? 0,
      qtyReturned: double.tryParse(qtyReturnedCtrl.text.trim()) ?? 0,
      itemPrice: itemPrice,
      itemTotal: quantity * itemPrice,
    );
  }

  void dispose() {
    itemIdCtrl.dispose();
    productIdCtrl.dispose();
    vendorProductIdCtrl.dispose();
    quantityCtrl.dispose();
    qtyLoadedCtrl.dispose();
    qtyDeliveredCtrl.dispose();
    qtyReturnedCtrl.dispose();
    itemPriceCtrl.dispose();
  }
}
