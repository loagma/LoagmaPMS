<?php

namespace App\Http\Controllers;

use App\Models\Supplier;
use App\Models\SupplierProduct;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SupplierController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Supplier::query();

            // Search
            if ($request->has('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('supplier_name', 'like', "%{$search}%")
                      ->orWhere('supplier_code', 'like', "%{$search}%")
                      ->orWhere('short_name', 'like', "%{$search}%");
                });
            }

            // Filter by status
            if ($request->has('status')) {
                $query->where('status', $request->input('status'));
            }

            // Sorting
            $sortField = $request->input('sort', 'created_at');
            $sortOrder = 'desc';
            
            if (str_contains($sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', $sortField);
            }

            $query->orderBy($sortField, $sortOrder);

            // Pagination
            $limit = $request->input('limit', 20);
            $page = $request->input('page', 1);
            
            $total = $query->count();
            $suppliers = $query->skip(($page - 1) * $limit)
                              ->take($limit)
                              ->get();

            return response()->json([
                'success' => true,
                'data' => $suppliers,
                'pagination' => [
                    'total' => $total,
                    'page' => (int) $page,
                    'limit' => (int) $limit,
                    'pages' => ceil($total / $limit),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Supplier index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch suppliers',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $supplier = Supplier::findOrFail($id);
            
            return response()->json([
                'success' => true,
                'data' => $supplier,
            ]);
        } catch (\Exception $e) {
            Log::error('Supplier show error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Supplier not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            DB::beginTransaction();

            // Create supplier (supplier_code will be auto-generated)
            $supplierData = $request->except(['supplier_products']);
            $supplier = Supplier::create($supplierData);

            // Create supplier products
            if ($request->has('supplier_products')) {
                foreach ($request->input('supplier_products') as $productData) {
                    $supplier->supplierProducts()->create($productData);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Supplier created successfully',
                'data' => $supplier->load('supplierProducts'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Supplier store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create supplier: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        try {
            DB::beginTransaction();

            $supplier = Supplier::findOrFail($id);
            
            // Update supplier
            $supplierData = $request->except(['supplier_products']);
            $supplier->update($supplierData);

            // Update supplier products
            if ($request->has('supplier_products')) {
                // Delete existing products
                $supplier->supplierProducts()->delete();
                
                // Create new products
                foreach ($request->input('supplier_products') as $productData) {
                    $supplier->supplierProducts()->create($productData);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Supplier updated successfully',
                'data' => $supplier->load('supplierProducts'),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Supplier update error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update supplier: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function getSupplierProducts(int $id): JsonResponse
    {
        try {
            $supplier = Supplier::findOrFail($id);
            $products = $supplier->supplierProducts()->with('product')->get();

            return response()->json([
                'success' => true,
                'data' => $products,
            ]);
        } catch (\Exception $e) {
            Log::error('Supplier products error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch supplier products',
            ], 500);
        }
    }
}
