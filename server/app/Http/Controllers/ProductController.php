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
            $limit = min(max($limit, 1), 500);
            $includeStock = filter_var(request()->query('include_stock', false), FILTER_VALIDATE_BOOLEAN);

            $selectCols = ['product_id', 'name', 'inventory_type', 'inventory_unit_type'];
            if ($includeStock) {
                $selectCols[] = 'stock';
            }
            $query = DB::table('product')
                ->select($selectCols)
                ->where('is_deleted', 0)
                ->where('is_published', 1)
                ->whereNotNull('product_id')
                ->whereNotNull('name')
                ->whereRaw("TRIM(name) != ''");

            // Filter by role: raw_material (in BOM items) or finished (in BOM master)
            $forType = trim((string) request()->query('for', ''));
            if ($forType === 'raw_material') {
                $query->whereIn('product_id', function ($q) {
                    $q->select('raw_material_id')->from('bom_items')->distinct();
                });
            } elseif ($forType === 'finished') {
                $query->whereIn('product_id', function ($q) {
                    $q->select('product_id')->from('bom_master')->distinct();
                });
            }

            if (!empty(trim($search))) {
                $term = trim($search);
                $query->where(function ($q) use ($term) {
                    $q->where('name', 'LIKE', "%{$term}%")
                        ->orWhere('product_id', 'LIKE', "%{$term}%");
                });
            }

            $products = $query->orderBy('name')->limit($limit)->get();

            $cleanProducts = $products->map(function ($product) use ($includeStock) {
                $cleanName = trim($product->name);
                $cleanName = str_replace(['"', '\\', "\n", "\r", "\t"], '', $cleanName);

                $inventoryType = trim($product->inventory_type ?? 'SINGLE');
                if (empty($inventoryType)) {
                    $inventoryType = 'SINGLE';
                }

                $unitType = trim($product->inventory_unit_type ?? 'WEIGHT');
                if (empty($unitType)) {
                    $unitType = 'WEIGHT';
                }

                $result = [
                    'product_id' => (int) $product->product_id,
                    'name' => $cleanName,
                    'inventory_type' => $inventoryType,
                    'inventory_unit_type' => $unitType,
                ];
                if ($includeStock && isset($product->stock)) {
                    $result['stock'] = $product->stock !== null ? (float) $product->stock : 0;
                }
                return $result;
            })->filter(fn ($p) => !empty($p['name']))->values();

            Log::info('Products API', ['search' => $search, 'count' => $cleanProducts->count()]);

            return response()->json([
                'success' => true,
                'data' => $cleanProducts,
                'search' => $search,
                'count' => $cleanProducts->count(),
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            Log::error('Products API error', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch products',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
