<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProductController extends Controller
{
    public function index(): JsonResponse
    {
        try {
            $search = request()->query('search', '');
            $limit = (int) request()->query('limit', 50);
            
            // Build query
            $query = DB::table('product')
                ->select('product_id', 'name', 'inventory_type')
                ->where('is_deleted', 0)
                ->where('is_published', 1)
                ->whereNotNull('product_id')
                ->whereNotNull('name')
                ->whereRaw("TRIM(name) != ''");

            // Add search filter if provided
            if (!empty($search)) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'LIKE', "%{$search}%")
                      ->orWhere('product_id', 'LIKE', "%{$search}%");
                });
            }

            $products = $query->orderBy('name')
                ->limit($limit)
                ->get();

            // Clean and validate each product
            $cleanProducts = $products->map(function ($product) {
                $cleanName = trim($product->name);
                $cleanName = str_replace(['"', '\\', "\n", "\r", "\t"], '', $cleanName);
                
                $inventoryType = trim($product->inventory_type ?? 'SINGLE');
                if (empty($inventoryType)) {
                    $inventoryType = 'SINGLE';
                }
                
                return [
                    'product_id' => (int) $product->product_id,
                    'name' => $cleanName,
                    'inventory_type' => $inventoryType
                ];
            })
            ->filter(function ($product) {
                return !empty($product['name']);
            })
            ->values();

            Log::info('Products API called', [
                'search' => $search,
                'count' => $cleanProducts->count()
            ]);

            // Test JSON encoding before returning
            $testJson = json_encode($cleanProducts);
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new \Exception('JSON encoding failed: ' . json_last_error_msg());
            }

            return response()->json([
                'success' => true,
                'data' => $cleanProducts,
                'search' => $search,
                'count' => $cleanProducts->count()
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            Log::error('Products API error', ['error' => $e->getMessage()]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch products',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
