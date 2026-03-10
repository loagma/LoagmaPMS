import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../api_config.dart';
import '../../controllers/product_tax_form_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

class ProductTaxFormScreen extends StatelessWidget {
  const ProductTaxFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductTaxFormController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleAppBar(
        title: 'Assign Tax to Product',
        subtitle: 'Link tax with percentage to a product',
        onBackPressed: () => Get.back(),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.taxes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ContentCard(
              title: 'Product Tax Assignment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductPicker(controller: controller),
                  const SizedBox(height: 16),
                  Obx(() => DropdownButtonFormField<int>(
                        value: controller.selectedTaxId.value,
                        decoration: AppInputDecoration.standard(
                          labelText: 'Tax *',
                          hintText: 'Select tax',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('-- Select tax --'),
                          ),
                          ...controller.taxes.map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                    '${t.taxName} (${t.taxSubCategory})'),
                              )),
                        ],
                        validator: (v) => v == null ? 'Required' : null,
                        onChanged: (v) => controller.selectedTaxId.value = v,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => TextFormField(
                        initialValue: controller.taxPercent.value,
                        decoration: AppInputDecoration.standard(
                          labelText: 'Tax Percent *',
                          hintText: '0.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (v) => controller.taxPercent.value = v,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          final p = double.tryParse(v);
                          if (p == null || p < 0 || p > 100) {
                            return 'Must be 0-100';
                          }
                          return null;
                        },
                      )),
                ],
              ),
            ),
          ),
        );
      }),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed: controller.isSaving.value
              ? null
              : () async {
                  final ok = await controller.save();
                  if (ok) Get.back(result: true);
                },
          backgroundColor: AppColors.primary,
          icon: controller.isSaving.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_rounded),
          label: Text(
              controller.isSaving.value ? 'Saving...' : 'Assign Tax to Product'),
        ),
      ),
    );
  }
}

class _ProductPicker extends StatelessWidget {
  final ProductTaxFormController controller;

  const _ProductPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: controller.selectedProductId.value,
      validator: (v) => v == null ? 'Please select product' : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (ctx) => _ProductSearchDialog(),
                );
                if (result != null) {
                  final rawId = result['product_id'] ?? result['id'];
                  final pid = rawId is int
                      ? rawId
                      : int.tryParse(rawId?.toString() ?? '');
                  final name = result['name']?.toString() ?? '';
                  if (pid != null) {
                    controller.setProduct(pid, name);
                    state.didChange(pid);
                    state.validate();
                  }
                }
              },
              child: InputDecorator(
                decoration: AppInputDecoration.standard(
                  labelText: 'Product *',
                  hintText: 'Tap to search and select product',
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                            controller.selectedProductName.value.isEmpty
                                ? 'Tap to search...'
                                : controller.selectedProductName.value,
                            style: TextStyle(
                              color: controller.selectedProductId.value == null
                                  ? Colors.grey
                                  : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                    if (controller.selectedProductId.value != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clearProduct();
                          state.didChange(null);
                          state.validate();
                        },
                      )
                    else
                      const Icon(Icons.search, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductSearchDialog extends StatefulWidget {
  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(ApiConfig.products).replace(
        queryParameters: {
          'limit': '50',
          if (query.trim().isNotEmpty) 'search': query.trim(),
        },
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final List list = data['data'] ?? [];
          setState(() {
            _items = list
                .map((e) => {
                      'product_id': (e as Map)['product_id'] ?? (e)['id'],
                      'name': (e)['name']?.toString() ??
                          (e)['product_name']?.toString() ??
                          '',
                    })
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('[PRODUCT_TAX] Search error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search Product',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: AppInputDecoration.standard(
                labelText: 'Name or ID',
                hintText: 'Type to search...',
              ),
              onChanged: _runSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final p = _items[i];
                            final name = p['name']?.toString() ?? 'Product';
                            final id = p['product_id'] ?? p['id'];
                            return ListTile(
                              title: Text(name),
                              subtitle: Text('ID: $id'),
                              onTap: () =>
                                  Navigator.pop(context, p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
