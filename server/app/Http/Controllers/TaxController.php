<?php

namespace App\Http\Controllers;

use App\Models\Tax;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TaxController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Tax::query();

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('tax_name', 'like', "%{$search}%")
                        ->orWhere('tax_category', 'like', "%{$search}%")
                        ->orWhere('tax_sub_category', 'like', "%{$search}%");
                });
            }

            if ($request->has('is_active')) {
                $query->where('is_active', filter_var($request->input('is_active'), FILTER_VALIDATE_BOOLEAN));
            }

            $sortField = $request->input('sort', 'created_at');
            $sortOrder = $request->input('order', 'desc');
            if (str_contains($sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', $sortField);
            }
            $query->orderBy($sortField, $sortOrder);

            $limit = (int) $request->input('limit', 20);
            $page = (int) $request->input('page', 1);
            $total = $query->count();
            $taxes = $query->skip(($page - 1) * $limit)->take($limit)->get();

            return response()->json([
                'success' => true,
                'data' => $taxes,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'pages' => $limit > 0 ? (int) ceil($total / $limit) : 0,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('Tax index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch taxes',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $tax = Tax::with('productTaxes.product')->findOrFail($id);
            return response()->json([
                'success' => true,
                'data' => $tax,
            ]);
        } catch (\Exception $e) {
            Log::error('Tax show error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Tax not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'tax_category' => 'required|string|max:100',
            'tax_sub_category' => 'required|string|max:100',
            'tax_name' => 'required|string|max:150',
            'is_active' => 'nullable|boolean',
        ]);

        try {
            $tax = Tax::create([
                'tax_category' => $validated['tax_category'],
                'tax_sub_category' => $validated['tax_sub_category'],
                'tax_name' => $validated['tax_name'],
                'is_active' => $validated['is_active'] ?? true,
            ]);
            return response()->json([
                'success' => true,
                'message' => 'Tax created successfully',
                'data' => $tax,
            ], 201);
        } catch (\Exception $e) {
            Log::error('Tax store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create tax',
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'tax_category' => 'sometimes|required|string|max:100',
            'tax_sub_category' => 'sometimes|required|string|max:100',
            'tax_name' => 'sometimes|required|string|max:150',
            'is_active' => 'nullable|boolean',
        ]);

        try {
            $tax = Tax::findOrFail($id);
            $tax->update($validated);
            return response()->json([
                'success' => true,
                'message' => 'Tax updated successfully',
                'data' => $tax->fresh(),
            ]);
        } catch (\Exception $e) {
            Log::error('Tax update error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update tax',
            ], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $tax = Tax::findOrFail($id);
            $tax->productTaxes()->delete();
            $tax->delete();
            return response()->json([
                'success' => true,
                'message' => 'Tax deleted successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Tax destroy error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete tax',
            ], 500);
        }
    }
}
