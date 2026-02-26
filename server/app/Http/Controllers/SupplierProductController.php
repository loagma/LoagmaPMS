<?php

namespace App\Http\Controllers;

use App\Models\SupplierProduct;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SupplierProductController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = SupplierProduct::query()
                ->join('suppliers', 'supplier_products.supplier_id', '=', 'suppliers.id')
                ->join('product', 'supplier_products.product_id', '=', 'product.product_id')
                ->select(
                    'supplier_products.*',
                    'suppliers.supplier_name',
                    'product.name as product_name'
                );

            // Search
            if ($request->has('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('suppliers.supplier_name', 'like', "%{$search}%")
                      ->orWhere('product.name', 'like', "%{$search}%")
                      ->orWhere('supplier_products.supplier_sku', 'like', "%{$search}%")
                      ->orWhere('supplier_products.supplier_product_name', 'like', "%{$search}%");
                });
            }

            // Filter by supplier
            if ($request->has('supplier_id')) {
                $query->where('supplier_products.supplier_id', $request->input('supplier_id'));
            }

            // Filter by product
            if ($request->has('product_id')) {
                $query->where('supplier_products.product_id', $request->input('product_id'));
            }

            // Filter by active status
            if ($request->has('is_active')) {
                $query->where('supplier_products.is_active', $request->input('is_active'));
            }

            // Sorting
            $sortField = $request->input('sort', 'supplier_products.created_at');
            $sortOrder = 'desc';
            
            if (str_contains($sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', $sortField);
            }

            $query->orderBy($sortField, $sortOrder);

            // Pagination
            $limit = $request->input('limit', 20);
            $page = $request->input('page', 1);
            
            $total = (clone $query)->count();
            $supplierProducts = $query->skip(($page - 1) * $limit)
                                     ->take($limit)
                                     ->get();

            return response()->json([
                'success' => true,
                'data' => $supplierProducts,
                'pagination' => [
                    'total' => $total,
                    'page' => (int) $page,
                    'limit' => (int) $limit,
                    'pages' => ceil($total / $limit),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Supplier product index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch supplier products',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $supplierProduct = SupplierProduct::with(['supplier', 'product'])->findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $supplierProduct,
            ]);
        } catch (\Exception $e) {
            Log::error('Supplier product show error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Supplier product not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'supplier_id' => 'required|integer|exists:suppliers,id',
            'product_id' => 'required|integer|exists:product,product_id',
            'supplier_sku' => 'nullable|string|max:100',
            'supplier_product_name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'pack_size' => 'nullable|numeric|min:0',
            'pack_unit' => 'nullable|string|max:20',
            'min_order_qty' => 'nullable|numeric|min:0',
            'price' => 'nullable|numeric|min:0',
            'currency' => 'nullable|string|max:3',
            'tax_percent' => 'nullable|numeric|min:0|max:100',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'lead_time_days' => 'nullable|integer|min:0',
            'last_purchase_price' => 'nullable|numeric|min:0',
            'last_purchase_date' => 'nullable|date',
            'is_preferred' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        try {
            $exists = SupplierProduct::where('supplier_id', $validated['supplier_id'])
                ->where('product_id', $validated['product_id'])
                ->exists();
            if ($exists) {
                return response()->json([
                    'success' => false,
                    'message' => 'This product is already assigned to the selected supplier.',
                ], 422);
            }

            $supplierProduct = SupplierProduct::create($validated);

            return response()->json([
                'success' => true,
                'message' => 'Supplier product created successfully',
                'data' => $supplierProduct->load(['supplier', 'product']),
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('Supplier product store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create supplier product: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'supplier_id' => 'sometimes|integer|exists:suppliers,id',
            'product_id' => 'sometimes|integer|exists:product,product_id',
            'supplier_sku' => 'nullable|string|max:100',
            'supplier_product_name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'pack_size' => 'nullable|numeric|min:0',
            'pack_unit' => 'nullable|string|max:20',
            'min_order_qty' => 'nullable|numeric|min:0',
            'price' => 'nullable|numeric|min:0',
            'currency' => 'nullable|string|max:3',
            'tax_percent' => 'nullable|numeric|min:0|max:100',
            'discount_percent' => 'nullable|numeric|min:0|max:100',
            'lead_time_days' => 'nullable|integer|min:0',
            'last_purchase_price' => 'nullable|numeric|min:0',
            'last_purchase_date' => 'nullable|date',
            'is_preferred' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'notes' => 'nullable|string',
        ]);

        try {
            $supplierProduct = SupplierProduct::findOrFail($id);
            $supplierId = $validated['supplier_id'] ?? $supplierProduct->supplier_id;
            $productId = $validated['product_id'] ?? $supplierProduct->product_id;

            $exists = SupplierProduct::where('supplier_id', $supplierId)
                ->where('product_id', $productId)
                ->where('id', '!=', $id)
                ->exists();
            if ($exists) {
                return response()->json([
                    'success' => false,
                    'message' => 'This product is already assigned to the selected supplier.',
                ], 422);
            }

            $supplierProduct->update($validated);

            return response()->json([
                'success' => true,
                'message' => 'Supplier product updated successfully',
                'data' => $supplierProduct->load(['supplier', 'product']),
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error('Supplier product update error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update supplier product: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $supplierProduct = SupplierProduct::findOrFail($id);
            $supplierProduct->delete();

            return response()->json([
                'success' => true,
                'message' => 'Supplier product deleted successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Supplier product delete error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete supplier product',
            ], 500);
        }
    }
}
