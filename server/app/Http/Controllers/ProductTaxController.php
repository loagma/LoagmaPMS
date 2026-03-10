<?php

namespace App\Http\Controllers;

use App\Models\ProductTax;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ProductTaxController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = ProductTax::query()->with(['tax', 'product']);

            if ($request->filled('product_id')) {
                $query->where('product_id', $request->input('product_id'));
            }

            if ($request->filled('tax_id')) {
                $query->where('tax_id', $request->input('tax_id'));
            }

            $sortField = $request->input('sort', 'created_at');
            $sortOrder = $request->input('order', 'desc');
            if (str_contains($sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', $sortField);
            }
            $query->orderBy($sortField, $sortOrder);

            $limit = (int) $request->input('limit', 50);
            $page = (int) $request->input('page', 1);
            $total = $query->count();
            $items = $query->skip(($page - 1) * $limit)->take($limit)->get();

            return response()->json([
                'success' => true,
                'data' => $items,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'pages' => $limit > 0 ? (int) ceil($total / $limit) : 0,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('ProductTax index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch product taxes',
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'product_id' => 'required|integer|exists:product,product_id',
            'tax_id' => 'required|integer|exists:taxes,id',
            'tax_percent' => 'required|numeric|min:0|max:100',
        ]);

        $exists = ProductTax::where('product_id', $validated['product_id'])
            ->where('tax_id', $validated['tax_id'])
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'message' => 'This tax is already assigned to this product.',
            ], 422);
        }

        try {
            $productTax = ProductTax::create($validated);
            return response()->json([
                'success' => true,
                'message' => 'Tax assigned to product successfully',
                'data' => $productTax->load(['tax', 'product']),
            ], 201);
        } catch (\Exception $e) {
            Log::error('ProductTax store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to assign tax to product',
            ], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $productTax = ProductTax::findOrFail($id);
            $productTax->delete();
            return response()->json([
                'success' => true,
                'message' => 'Product tax assignment removed successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('ProductTax destroy error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to remove product tax assignment',
            ], 500);
        }
    }
}
