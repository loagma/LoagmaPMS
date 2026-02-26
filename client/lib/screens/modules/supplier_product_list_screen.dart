import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/supplier_product_list_controller.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';

class SupplierProductListScreen extends StatelessWidget {
  const SupplierProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final supplierId = args?['supplier_id'] as int?;
    final supplierName = args?['supplier_name'] as String?;
    final controller = Get.put(SupplierProductListController(
      supplierId: supplierId,
      supplierName: supplierName,
    ));

    final appBarTitle = supplierName != null && supplierName.isNotEmpty
        ? 'Products for $supplierName'
        : 'Edit supplier products';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => controller.searchSupplierProducts(value),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.supplierProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        supplierId != null
                            ? 'No products assigned to this supplier'
                            : 'No supplier products found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadSupplierProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.supplierProducts.length,
                  itemBuilder: (context, index) {
                    final item = controller.supplierProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          item.supplierProductName ?? item.productName ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (controller.supplierId == null)
                              Text('Supplier: ${item.supplierName}'),
                            Text('Product: ${item.productName}'),
                            if (item.supplierSku != null)
                              Text('SKU: ${item.supplierSku}'),
                            if (item.price != null)
                              Text(
                                'Price: ${item.currency ?? 'INR'} ${item.price?.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.isPreferred)
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: item.isActive
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showDetailsDialog(context, controller, item),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.toNamed(
            AppRoutes.supplierProductForm,
            arguments: supplierId != null
                ? {'supplier_id': supplierId}
                : null,
          );
          if (result == true) {
            controller.loadSupplierProducts();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Assign Product'),
      ),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    SupplierProductListController controller,
    dynamic item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.supplierProductName ?? item.productName ?? 'Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Supplier', item.supplierName),
              _buildDetailRow('Product', item.productName),
              if (item.supplierSku != null)
                _buildDetailRow('SKU', item.supplierSku),
              if (item.description != null)
                _buildDetailRow('Description', item.description),
              if (item.packSize != null)
                _buildDetailRow(
                  'Pack Size',
                  '${item.packSize} ${item.packUnit ?? ''}',
                ),
              if (item.minOrderQty != null)
                _buildDetailRow('Min Order Qty', item.minOrderQty.toString()),
              if (item.price != null)
                _buildDetailRow(
                  'Price',
                  '${item.currency ?? 'INR'} ${item.price?.toStringAsFixed(2)}',
                ),
              if (item.taxPercent != null)
                _buildDetailRow('Tax', '${item.taxPercent}%'),
              if (item.discountPercent != null)
                _buildDetailRow('Discount', '${item.discountPercent}%'),
              if (item.leadTimeDays != null)
                _buildDetailRow('Lead Time', '${item.leadTimeDays} days'),
              _buildDetailRow('Preferred', item.isPreferred ? 'Yes' : 'No'),
              _buildDetailRow('Status', item.isActive ? 'Active' : 'Inactive'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _navigateToEdit(context, controller, item.id);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(context, controller, item);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit(
    BuildContext context,
    SupplierProductListController controller,
    int id,
  ) async {
    final result = await Get.toNamed(
      AppRoutes.supplierProductForm,
      arguments: {'id': id},
    );
    if (result == true) {
      controller.loadSupplierProducts();
    }
  }

  void _confirmDelete(
    BuildContext context,
    SupplierProductListController controller,
    dynamic item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete supplier product?'),
        content: Text(
          'Remove "${item.supplierProductName ?? item.productName ?? 'this assignment'}" from supplier "${item.supplierName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await controller.deleteSupplierProduct(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
