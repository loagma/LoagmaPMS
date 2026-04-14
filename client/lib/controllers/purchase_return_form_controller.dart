import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../api_config.dart';
import '../models/purchase_return_model.dart';
import '../theme/app_colors.dart';

class PurchaseReturnFormController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final int? returnId;
  final int? sourcePvId;
  final bool startInViewOnly;

  final suppliers = <Map<String, dynamic>>[].obs;
  final purchaseVouchers = <Map<String, dynamic>>[].obs;
  final unitTypes = <String>[].obs;
  final viewOnly = false.obs;

  // Header fields
  final docNoPrefix = '25-26/'.obs;
  final docNoNumber = ''.obs;
  final sourcePvIdSelected = Rxn<int>();
  final sourcePvNumber = ''.obs;
  final vendorId = Rxn<int>();
  final vendorName = ''.obs;
  final docDate = ''.obs;
  final reason = ''.obs;
  final status = 'DRAFT'.obs;

  final items = <PRItemRow>[].obs;
  final charges = <PRChargeRow>[].obs;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isSearchingVouchers = false.obs;

  PurchaseReturnFormController({
    this.returnId,
    this.sourcePvId,
    this.startInViewOnly = false,
  });

  int? _safeInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  double? _safeDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw == null) return null;
    return double.tryParse(raw.toString());
  }

  Map<String, dynamic> _normalizeVoucherPayload(Map<String, dynamic> raw) {
    if (raw['voucher'] is Map<String, dynamic>) {
      final voucher = Map<String, dynamic>.from(
        raw['voucher'] as Map<String, dynamic>,
      );
      final items = (raw['items'] is List) ? (raw['items'] as List) : const [];
      voucher['items'] = items;
      return voucher;
    }
    return raw;
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  void onInit() {
    super.onInit();
    viewOnly.value = startInViewOnly;
    docDate.value = _formatDate(DateTime.now());
    _loadSuppliers();
    _loadUnitTypes();
    if (sourcePvId != null) {
      sourcePvIdSelected.value = sourcePvId;
    }
    if (returnId != null) {
      _loadPurchaseReturn();
    } else {
      if (sourcePvId != null) {
        _loadPurchaseVoucherItems(sourcePvId!);
      }
    }
  }

  bool get isEditMode => returnId != null;
  bool get isReadOnly => viewOnly.value;
  bool get canEditFromView => isReadOnly && status.value == 'DRAFT';

  void enterEditMode() {
    viewOnly.value = false;
  }

  Future<void> _loadSuppliers() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.suppliers),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          suppliers.value = items.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('[PR FORM] Load suppliers error: $e');
    }
  }

  String _supplierNameById(int? supplierId) {
    if (supplierId == null) return '';
    for (final supplier in suppliers) {
      final id = _safeInt(supplier['id']);
      if (id == supplierId) {
        return supplier['supplier_name']?.toString() ??
            supplier['name']?.toString() ??
            '';
      }
    }
    return '';
  }

  Future<void> setSupplier(int? supplierId) async {
    if (vendorId.value == supplierId) {
      return;
    }

    vendorId.value = supplierId;
    vendorName.value = _supplierNameById(supplierId);
    sourcePvIdSelected.value = null;
    sourcePvNumber.value = '';
    items.clear();
    charges.clear();
    docNoNumber.value = '';

    if (supplierId != null) {
      await _loadNextDocNoNumberForSupplier(supplierId);
    }
  }

  Future<void> _loadUnitTypes() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.unitTypes),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List items = data['data'] ?? [];
          unitTypes.value = items.cast<String>();
        }
      }
    } catch (e) {
      debugPrint('[PR FORM] Load unit types error: $e');
    }
  }

  Future<void> _loadNextDocNoNumberForSupplier(int supplierId) async {
    try {
      final uri = Uri.parse(
        ApiConfig.purchaseReturnSeries,
      ).replace(queryParameters: {'vendor_id': supplierId.toString()});

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final series = data['data'] as Map<String, dynamic>;
          docNoPrefix.value = series['prefix']?.toString() ?? docNoPrefix.value;
          docNoNumber.value = series['number']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('[PR FORM] Load doc number error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchPurchaseVouchers(
    String query, {
    int? vendorIdFilter,
  }) async {
    try {
      isSearchingVouchers.value = true;
      final uri = Uri.parse(ApiConfig.purchaseVouchers).replace(
        queryParameters: {
          'limit': '20',
          if (query.trim().isNotEmpty) 'search': query.trim(),
          if (vendorIdFilter != null) 'vendor_id': vendorIdFilter.toString(),
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          return list.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[PR FORM] Search vouchers error: $e');
      return [];
    } finally {
      isSearchingVouchers.value = false;
    }
  }

  Future<void> loadPurchaseVoucherItems(int pvId) async {
    await _loadPurchaseVoucherItems(pvId);
  }

  Future<void> _loadPurchaseVoucherItems(int pvId) async {
    try {
      isLoading.value = true;
      sourcePvIdSelected.value = pvId;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.purchaseVouchers}/$pvId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final pvData = _normalizeVoucherPayload(
            data['data'] as Map<String, dynamic>,
          );

          // Set header info from PV
          sourcePvNumber.value =
              pvData['doc_no']?.toString() ??
              pvData['doc_no_number']?.toString() ??
              '';
          vendorId.value = _safeInt(
            pvData['vendor_id'] ?? pvData['supplier_id'],
          );
          vendorName.value =
              pvData['vendor_name']?.toString() ??
              pvData['supplier_name']?.toString() ??
              '';
          if (vendorId.value != null) {
            await _loadNextDocNoNumberForSupplier(vendorId.value!);
          }

          // Clear and populate items from PV
          items.clear();
          final List pvItems = pvData['items'] ?? [];
          for (final item in pvItems.cast<Map<String, dynamic>>()) {
            final originalQty =
                _safeDouble(
                  item['quantity'] ??
                      item['original_quantity'] ??
                      item['received_qty'],
                ) ??
                0;
            final availableFromApi = _safeDouble(
              item['available_quantity'] ??
                  item['remaining_returnable_qty'] ??
                  item['remaining_qty'],
            );
            final effectiveAvailableQty =
                (availableFromApi != null && availableFromApi > 0)
                ? availableFromApi
                : originalQty;

            final row = PRItemRow()
              ..sourcePvItemId.value = _safeInt(item['id'])
              ..sourcePvId.value = pvId
              ..productId.value = _safeInt(item['product_id'])
              ..productName.value = item['product_name']?.toString() ?? ''
              ..productCode.value = item['product_code']?.toString() ?? ''
              ..alias.value = item['alias']?.toString() ?? ''
              ..unitType.value = item['unit']?.toString() ?? 'Nos'
              ..originalQty.value = originalQty.toString()
              ..availableQty.value = effectiveAvailableQty.toString()
              ..returnedQty.value = ''
              ..unitPrice.value =
                  (_safeDouble(item['unit_price'])?.toString()) ?? '0';

            items.add(row);
          }

          if (items.isEmpty) {
            addItemRow();
          }
        }
      }
    } catch (e) {
      debugPrint('[PR FORM] Load PV items error: $e');
      _showError('Failed to load voucher items: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPurchaseReturn() async {
    try {
      isLoading.value = true;

      final response = await http
          .get(
            Uri.parse('${ApiConfig.purchaseReturns}/$returnId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final returnData = data['data'] as Map<String, dynamic>;
          final pr = PurchaseReturn.fromJson(returnData);

          // Load header
          docNoPrefix.value = pr.header.docNoPrefix;
          docNoNumber.value = pr.header.docNoNumber;
          sourcePvNumber.value = pr.header.sourcePvNumber ?? '';
          sourcePvIdSelected.value = pr.header.sourcePurchaseVoucherId;
          vendorId.value = pr.header.vendorId;
          vendorName.value = pr.header.vendorName ?? '';
          docDate.value = pr.header.docDate;
          reason.value = pr.header.reason ?? '';
          status.value = pr.header.status ?? 'DRAFT';

          // Load items
          items.clear();
          for (final item in pr.items) {
            final row = PRItemRow()
              ..sourcePvItemId.value = item.sourcePurchaseVoucherItemId
              ..productId.value = item.productId
              ..productName.value = item.productName ?? ''
              ..productCode.value = item.productCode ?? ''
              ..alias.value = item.alias ?? ''
              ..unitType.value = item.unit ?? 'Nos'
              ..originalQty.value = item.originalQty.toString()
              ..availableQty.value = (item.availableQty ?? item.originalQty)
                  .toString()
              ..returnedQty.value = item.returnedQty.toString()
              ..unitPrice.value = item.unitPrice.toString()
              ..returnReason.value = item.returnReason ?? ''
              ..selected.value = item.returnedQty > 0;

            items.add(row);
          }

          // Load charges
          charges.clear();
          for (final charge in pr.charges) {
            final row = PRChargeRow()
              ..name.value = charge.name
              ..amount.value = charge.amount.toString()
              ..remarks.value = charge.remarks ?? '';

            charges.add(row);
          }
        }
      }
    } catch (e) {
      debugPrint('[PR FORM] Load PV error: $e');
      _showError('Failed to load return: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String get totalReturnValue {
    double total = 0;
    for (final row in items) {
      final qty = double.tryParse(row.returnedQty.value) ?? 0;
      final price = double.tryParse(row.unitPrice.value) ?? 0;
      total += qty * price;
    }

    // Add charges
    for (final charge in charges) {
      final amt = double.tryParse(charge.amount.value) ?? 0;
      final name = charge.name.value.toLowerCase();
      total += name.contains('discount') ? -amt : amt;
    }

    return total.toStringAsFixed(2);
  }

  void addItemRow() {
    items.add(PRItemRow());
  }

  void setItemSelected(int index, bool selected) {
    if (index < 0 || index >= items.length) return;

    final row = items[index];
    row.selected.value = selected;
    if (!selected) {
      row.returnedQty.value = '';
      row.returnReason.value = '';
    }
  }

  void removeItemRow(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  void addChargeRow() {
    charges.add(PRChargeRow());
  }

  void removeChargeRow(int index) {
    if (index >= 0 && index < charges.length) {
      charges.removeAt(index);
    }
  }

  Future<void> savePurchaseReturn({bool post = false}) async {
    if (!formKey.currentState!.validate()) {
      _showError('Please fill all required fields');
      return;
    }

    if (items.isEmpty) {
      _showError('Please add at least one item');
      return;
    }

    if (sourcePvIdSelected.value == null) {
      _showError('Please select a source purchase voucher');
      return;
    }

    try {
      isSaving.value = true;

      for (var i = 0; i < items.length; i++) {
        final row = items[i];
        if (!row.selected.value) {
          row.returnedQty.value = '';
          continue;
        }
        final rQty = double.tryParse(row.returnedQty.value) ?? 0;
        if (rQty <= 0) continue;
        final available =
            double.tryParse(row.availableQty.value) ??
            (double.tryParse(row.originalQty.value) ?? 0);
        if (rQty > available) {
          _showError(
            'Row ${i + 1}: return quantity exceeds available quantity ($available)',
          );
          return;
        }
      }

      final itemsList = items
          .where((row) {
            if (!row.selected.value) {
              return false;
            }
            final rQty = double.tryParse(row.returnedQty.value) ?? 0;
            return rQty > 0;
          })
          .map(
            (row) => {
              'source_purchase_voucher_item_id': row.sourcePvItemId.value,
              'product_id': row.productId.value,
              'product_name': row.productName.value,
              'original_quantity': double.tryParse(row.originalQty.value) ?? 0,
              'returned_quantity': double.tryParse(row.returnedQty.value) ?? 0,
              'unit_price': double.tryParse(row.unitPrice.value) ?? 0,
              'return_reason': row.returnReason.value,
            },
          )
          .toList();

      if (itemsList.isEmpty) {
        _showError('Please enter return quantity for at least one item');
        return;
      }

      final chargesList = charges
          .where(
            (row) =>
                row.name.value.isNotEmpty &&
                (double.tryParse(row.amount.value) ?? 0) > 0,
          )
          .map(
            (row) => {
              'name': row.name.value,
              'amount': double.tryParse(row.amount.value) ?? 0,
              'remarks': row.remarks.value,
            },
          )
          .toList();

      final payload = {
        'source_purchase_voucher_id': sourcePvIdSelected.value,
        'vendor_id': vendorId.value,
        'doc_date': docDate.value,
        'reason': reason.value.isNotEmpty ? reason.value : null,
        'status': post ? 'POSTED' : 'DRAFT',
        'items': itemsList,
        if (chargesList.isNotEmpty) 'charges': chargesList,
      };

      final uri = Uri.parse(
        returnId == null
            ? ApiConfig.createPurchaseReturn
            : '${ApiConfig.purchaseReturns}/$returnId',
      );
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      final response = returnId == null
          ? await http
                .post(uri, headers: headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 30))
          : await http
                .put(uri, headers: headers, body: jsonEncode(payload))
                .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          _showSuccess(
            returnId == null
                ? 'Return saved successfully'
                : 'Return updated successfully',
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Get.back(result: true);
          return;
        }
      }

      _showError(data['message']?.toString() ?? 'Failed to save return');
    } catch (e) {
      debugPrint('[PR FORM] Save error: $e');
      _showError('Error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteReturn() async {
    if (returnId == null) return;

    try {
      isSaving.value = true;

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.purchaseReturns}/$returnId'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          _showSuccess('Return deleted successfully');
          await Future.delayed(const Duration(milliseconds: 500));
          Get.back(result: true);
          return;
        }
      }

      _showError(data['message']?.toString() ?? 'Failed to delete return');
    } catch (e) {
      debugPrint('[PR FORM] Delete error: $e');
      _showError('Error: $e');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    for (final row in items) {
      row.dispose();
    }
    super.onClose();
  }
}

/// Reactive row for return items
class PRItemRow {
  final sourcePvId = Rxn<int>();
  final sourcePvItemId = Rxn<int>();
  final productId = Rxn<int>();
  final productName = ''.obs;
  final productCode = ''.obs;
  final alias = ''.obs;
  final unitType = 'Nos'.obs;
  final originalQty = '0'.obs; // Qty received in PV
  final availableQty = '0'.obs; // Remaining returnable qty
  final returnedQty = ''.obs; // Qty to return
  final unitPrice = '0'.obs;
  final returnReason = ''.obs; // Why item is returned
  final remarks = ''.obs;
  final selected = false.obs;

  void dispose() {
    // No controllers to dispose
  }
}

/// Reactive row for charges
class PRChargeRow {
  final name = ''.obs;
  final amount = '0'.obs;
  final remarks = ''.obs;
}

void _showSuccess(String message) {
  Get.snackbar(
    'Success',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.primary,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
    duration: const Duration(seconds: 2),
  );
}

void _showError(String message) {
  Get.snackbar(
    'Error',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.redAccent,
    colorText: Colors.white,
    margin: const EdgeInsets.all(12),
    borderRadius: 8,
  );
}
