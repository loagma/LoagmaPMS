import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';
import '../../models/inventory_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class InventoryDetailsScreen extends StatefulWidget {
  final int vendorProductId;

  const InventoryDetailsScreen({super.key, required this.vendorProductId});

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  VendorProduct? product;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}/vendor-products/${widget.vendorProductId}',
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          setState(() {
            product = VendorProduct.fromJson(
              data['data'] as Map<String, dynamic>,
            );
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load product');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INVENTORY_DETAILS] Failed: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _showStockUpdateDialog(Pack pack) async {
    final stockChangeController = TextEditingController();
    final reasonController = TextEditingController();
    String actionType = 'increase';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Stock - ${pack.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock: ${pack.stock.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),

                // Action Type
                const Text(
                  'Action',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Increase'),
                        value: 'increase',
                        groupValue: actionType,
                        onChanged: (value) {
                          setDialogState(() {
                            actionType = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Decrease'),
                        value: 'decrease',
                        groupValue: actionType,
                        onChanged: (value) {
                          setDialogState(() {
                            actionType = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quantity
                TextField(
                  controller: stockChangeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Reason
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Enter reason for stock change',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantityText = stockChangeController.text.trim();
                final reason = reasonController.text.trim();

                if (quantityText.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please enter quantity',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                  return;
                }

                if (reason.isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Please enter reason',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                  return;
                }

                final quantity = double.tryParse(quantityText);
                if (quantity == null || quantity <= 0) {
                  Get.snackbar(
                    'Error',
                    'Please enter a valid quantity',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                  return;
                }

                final stockChange = actionType == 'increase'
                    ? quantity
                    : -quantity;

                Navigator.pop(context);
                await _updateStock(pack.packId, stockChange, reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStock(
    String packId,
    double stockChange,
    String reason,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}/vendor-products/${widget.vendorProductId}/packs/$packId/stock',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'stock_change': stockChange, 'reason': reason}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          Get.snackbar(
            'Success',
            'Stock updated successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Refresh product details
          await _fetchProductDetails();
        } else {
          throw Exception(data['message'] ?? 'Failed to update stock');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INVENTORY_DETAILS] Failed to update stock: $e');
      Get.snackbar(
        'Error',
        'Failed to update stock: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _checkConsistency() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.apiBaseUrl}/vendor-products/${widget.vendorProductId}/stock-consistency',
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          final consistencyData = data['data'] as Map<String, dynamic>;
          final isConsistent = consistencyData['is_consistent'] as bool;

          if (isConsistent) {
            Get.snackbar(
              'Consistency Check',
              'All packages have consistent stock levels',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            final inconsistencies = consistencyData['inconsistencies'] as List;
            _showInconsistenciesDialog(inconsistencies);
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to check consistency');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[INVENTORY_DETAILS] Failed to check consistency: $e');
      Get.snackbar(
        'Error',
        'Failed to check consistency: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _showInconsistenciesDialog(List inconsistencies) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Inconsistencies Found'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following packages have inconsistent stock levels:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...inconsistencies.map((item) {
                final packId = item['pack_id'] ?? '';
                final expected = item['expected_stock'] ?? 0;
                final actual = item['actual_stock'] ?? 0;
                final diff = item['difference'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pack: $packId',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Expected: ${expected.toStringAsFixed(2)}'),
                        Text('Actual: ${actual.toStringAsFixed(2)}'),
                        Text(
                          'Difference: ${diff.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Inventory Details',
        subtitle: 'VP-${widget.vendorProductId}',
        onBackPressed: () => Get.back(result: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProductDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded),
            onPressed: _checkConsistency,
            tooltip: 'Check Consistency',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading product',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchProductDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : product == null
          ? const Center(child: Text('Product not found'))
          : RefreshIndicator(
              onRefresh: _fetchProductDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info Card
                    ContentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'Product Name',
                            value: product!.productName,
                          ),
                          _InfoRow(
                            label: 'Vendor Product ID',
                            value: product!.id.toString(),
                          ),
                          _InfoRow(
                            label: 'Product ID',
                            value: product!.productId.toString(),
                          ),
                          _InfoRow(
                            label: 'Status',
                            value: product!.status == '1'
                                ? 'Active'
                                : 'Inactive',
                          ),
                          _InfoRow(
                            label: 'In Stock',
                            value: product!.inStock == '1' ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Packages Section
                    const Text(
                      'Packages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (product!.packs.isEmpty)
                      ContentCard(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          message: 'No packages configured',
                        ),
                      )
                    else
                      ...product!.packs.map(
                        (pack) => _PackCard(
                          pack: pack,
                          onUpdateStock: () => _showStockUpdateDialog(pack),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  final Pack pack;
  final VoidCallback onUpdateStock;

  const _PackCard({required this.pack, required this.onUpdateStock});

  Color _getStockColor() {
    if (pack.stock <= 0) return Colors.red;
    if (pack.stock < 10) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pack ID: ${pack.packId}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStockColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${pack.stock.toStringAsFixed(2)} ${pack.packUnit}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _getStockColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Original Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '₹${pack.originalPrice}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Retail Price',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '₹${pack.retailPrice}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tax',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${pack.tax}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpdateStock,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Update Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
