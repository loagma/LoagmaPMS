<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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
            $page = (int) request()->query('page', 1);
            if ($page < 1) {
                $page = 1;
            }
            $offset = ($page - 1) * $limit;
            $includeStock = filter_var(request()->query('include_stock', false), FILTER_VALIDATE_BOOLEAN);
            $includeTaxes = filter_var(request()->query('include_taxes', false), FILTER_VALIDATE_BOOLEAN);

            $selectCols = ['product_id', 'name', 'inventory_type', 'inventory_unit_type', 'gst_percent'];
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
                $likeTerm = '%' . addcslashes($term, '\\%_') . '%';
                $query->where(function ($q) use ($likeTerm) {
                    $q->where('name', 'LIKE', $likeTerm)
                        ->orWhereRaw('CAST(product_id AS CHAR) LIKE ?', [$likeTerm])
                        ->orWhere('keywords', 'LIKE', $likeTerm)
                        ->orWhere('cache_txt', 'LIKE', $likeTerm);
                });
            }

            $queryForData = clone $query;
            $total = $query->count();

            $products = $queryForData
                ->orderBy('name')
                ->limit($limit)
                ->offset($offset)
                ->get();

            $taxesByProductId = [];
            if ($includeTaxes && $products->isNotEmpty()) {
                $productIds = $products->pluck('product_id')->values();
                $taxRows = DB::table('product_taxes as pt')
                    ->join('taxes as t', 'pt.tax_id', '=', 't.id')
                    ->whereIn('pt.product_id', $productIds)
                    ->select(
                        'pt.product_id',
                        'pt.tax_id',
                        'pt.tax_percent',
                        't.tax_name',
                        't.tax_category',
                        't.tax_sub_category'
                    )
                    ->orderBy('pt.tax_id')
                    ->get();

                foreach ($taxRows as $row) {
                    $pid = (int) $row->product_id;
                    if (!isset($taxesByProductId[$pid])) {
                        $taxesByProductId[$pid] = [];
                    }
                    $taxesByProductId[$pid][] = [
                        'tax_id' => (int) $row->tax_id,
                        'tax_percent' => (float) $row->tax_percent,
                        'tax_name' => $row->tax_name,
                        'tax_category' => $row->tax_category,
                        'tax_sub_category' => $row->tax_sub_category,
                    ];
                }
            }

            $cleanProducts = $products->map(function ($product) use ($includeStock, $includeTaxes, $taxesByProductId) {
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
                    'gst_percent' => isset($product->gst_percent) ? (float) $product->gst_percent : 0,
                ];
                if ($includeStock && isset($product->stock)) {
                    $result['stock'] = $product->stock !== null ? (float) $product->stock : 0;
                }
                if ($includeTaxes) {
                    $result['taxes'] = $taxesByProductId[(int) $product->product_id] ?? [];
                }
                return $result;
            })->filter(fn ($p) => !empty($p['name']))->values();

            Log::info('Products API', ['search' => $search, 'count' => $cleanProducts->count()]);

            return response()->json([
                'success' => true,
                'data' => $cleanProducts,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'total_pages' => $limit > 0 ? (int) ceil($total / $limit) : 1,
                ],
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

    public function show(int $id): JsonResponse
    {
        $includeTaxes = filter_var(request()->query('include_taxes', false), FILTER_VALIDATE_BOOLEAN);

        try {
            $product = DB::table('product')
                ->where('product_id', $id)
                ->where('is_deleted', 0)
                ->first();

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Product not found',
                ], 404);
            }

            $payload = (array) $product;
            if ($includeTaxes) {
                $taxRows = DB::table('product_taxes as pt')
                    ->join('taxes as t', 'pt.tax_id', '=', 't.id')
                    ->where('pt.product_id', $id)
                    ->select(
                        'pt.tax_id',
                        'pt.tax_percent',
                        't.tax_name',
                        't.tax_category',
                        't.tax_sub_category'
                    )
                    ->orderBy('pt.tax_id')
                    ->get();

                $payload['taxes'] = $taxRows->map(function ($row) {
                    return [
                        'tax_id' => (int) $row->tax_id,
                        'tax_percent' => (float) $row->tax_percent,
                        'tax_name' => $row->tax_name,
                        'tax_category' => $row->tax_category,
                        'tax_sub_category' => $row->tax_sub_category,
                    ];
                })->values();
            }

            return response()->json([
                'success' => true,
                'data' => $payload,
            ]);
        } catch (\Exception $e) {
            Log::error('Product show error', ['error' => $e->getMessage(), 'product_id' => $id]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch product',
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'product_name' => 'required|string|max:255',
            'cat_id' => 'required|integer|min:0',
            'parent_cat_id' => 'nullable|integer|min:0',
            'brand' => 'required|string|max:255',
            'ctype_id' => 'nullable|string|max:250',
            'seq_no' => 'nullable|integer|min:0',
            'is_published' => 'nullable|integer|in:0,1',
            'in_stock' => 'nullable|integer|in:0,1',
            'inventory_type' => 'nullable|in:SINGLE,PACK_WISE',
            'inventory_unit_type' => 'nullable|string|max:255',
            'description' => 'required|string',
            'keywords' => 'nullable|string',
            'packs' => 'nullable',
            'default_pack_id' => 'nullable|string|max:255',
            'hsn_code' => 'required|string|max:10',
            'gst_percent' => 'nullable|numeric|min:0|max:999.99',
            'order_limit' => 'nullable|integer|min:0',
            'buffer_limit' => 'nullable|integer|min:0',
            'product_pack_count' => 'nullable|integer|min:0',
            'nop' => 'nullable|integer|min:0',
            'pack_prd_wt' => 'nullable|numeric|min:0',
            'gross_wt_of_pack' => 'nullable|numeric|min:0',
            'gst_tax_type' => 'nullable|string|max:50',
        ]);

        try {
            $nextId = ((int) DB::table('product')->max('product_id')) + 1;

            $packsValue = $validated['packs'] ?? null;
            if (is_array($packsValue)) {
                $packsValue = json_encode($packsValue, JSON_UNESCAPED_UNICODE);
            }

            DB::table('product')->insert([
                'product_id' => $nextId,
                'cat_id' => (int) ($validated['cat_id'] ?? 0),
                'parent_cat_id' => (int) ($validated['parent_cat_id'] ?? 0),
                'brand' => trim((string) $validated['brand']),
                'ctype_id' => trim((string) ($validated['ctype_id'] ?? 'vegetables_fruits')),
                'seq_no' => (int) ($validated['seq_no'] ?? 0),
                'start_date' => time(),
                'is_published' => (int) ($validated['is_published'] ?? 0),
                'is_used' => 0,
                'is_deleted' => 0,
                'in_stock' => (int) ($validated['in_stock'] ?? 0),
                'inventory_type' => (string) ($validated['inventory_type'] ?? 'SINGLE'),
                'inventory_unit_type' => (string) ($validated['inventory_unit_type'] ?? 'WEIGHT'),
                'name' => trim((string) $validated['product_name']),
                'description' => (string) $validated['description'],
                'display_photo' => null,
                'keywords' => $validated['keywords'] ?? null,
                'spec_params' => '{}',
                'packs' => $packsValue,
                'default_pack_id' => (string) ($validated['default_pack_id'] ?? ' '),
                'hsn_code' => (string) $validated['hsn_code'],
                'gst_percent' => (float) ($validated['gst_percent'] ?? 0),
                'offers' => null,
                'cache_txt' => null,
                'img_last_updated' => 0,
                'stock' => null,
                'stock_ut_id' => null,
                'order_limit' => (int) ($validated['order_limit'] ?? 0),
                'buffer_limit' => (int) ($validated['buffer_limit'] ?? 0),
                'product_pack_count' => (int) (
                    $validated['product_pack_count']
                        ?? $validated['nop']
                        ?? 0
                ),
                'nop' => (int) (
                    $validated['nop']
                        ?? $validated['product_pack_count']
                        ?? 0
                ),
                'pack_prd_wt' => isset($validated['pack_prd_wt'])
                    ? (float) $validated['pack_prd_wt']
                    : null,
                'gross_wt_of_pack' => isset($validated['gross_wt_of_pack'])
                    ? (float) $validated['gross_wt_of_pack']
                    : null,
                'gst_tax_type' => isset($validated['gst_tax_type'])
                    ? trim((string) $validated['gst_tax_type'])
                    : null,
            ]);

            $created = DB::table('product')->where('product_id', $nextId)->first();

            return response()->json([
                'success' => true,
                'message' => 'Product created successfully',
                'data' => (array) $created,
            ], 201);
        } catch (\Exception $e) {
            Log::error('Product store error', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to create product',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'product_name' => 'sometimes|required|string|max:255',
            'cat_id' => 'sometimes|required|integer|min:0',
            'parent_cat_id' => 'nullable|integer|min:0',
            'brand' => 'sometimes|required|string|max:255',
            'ctype_id' => 'nullable|string|max:250',
            'seq_no' => 'nullable|integer|min:0',
            'is_published' => 'nullable|integer|in:0,1',
            'in_stock' => 'nullable|integer|in:0,1',
            'inventory_type' => 'nullable|in:SINGLE,PACK_WISE',
            'inventory_unit_type' => 'nullable|string|max:255',
            'description' => 'sometimes|required|string',
            'keywords' => 'nullable|string',
            'packs' => 'nullable',
            'default_pack_id' => 'nullable|string|max:255',
            'hsn_code' => 'sometimes|required|string|max:10',
            'gst_percent' => 'nullable|numeric|min:0|max:999.99',
            'order_limit' => 'nullable|integer|min:0',
            'buffer_limit' => 'nullable|integer|min:0',
            'product_pack_count' => 'nullable|integer|min:0',
            'nop' => 'nullable|integer|min:0',
            'pack_prd_wt' => 'nullable|numeric|min:0',
            'gross_wt_of_pack' => 'nullable|numeric|min:0',
            'gst_tax_type' => 'nullable|string|max:50',
        ]);

        try {
            $exists = DB::table('product')->where('product_id', $id)->where('is_deleted', 0)->exists();
            if (!$exists) {
                return response()->json([
                    'success' => false,
                    'message' => 'Product not found',
                ], 404);
            }

            $updates = [];

            if (array_key_exists('product_name', $validated)) {
                $updates['name'] = trim((string) $validated['product_name']);
            }
            if (array_key_exists('cat_id', $validated)) {
                $updates['cat_id'] = (int) $validated['cat_id'];
            }
            if (array_key_exists('parent_cat_id', $validated)) {
                $updates['parent_cat_id'] = (int) ($validated['parent_cat_id'] ?? 0);
            }
            if (array_key_exists('brand', $validated)) {
                $updates['brand'] = trim((string) $validated['brand']);
            }
            if (array_key_exists('ctype_id', $validated)) {
                $updates['ctype_id'] = (string) ($validated['ctype_id'] ?? 'vegetables_fruits');
            }
            if (array_key_exists('seq_no', $validated)) {
                $updates['seq_no'] = (int) ($validated['seq_no'] ?? 0);
            }
            if (array_key_exists('is_published', $validated)) {
                $updates['is_published'] = (int) ($validated['is_published'] ?? 0);
            }
            if (array_key_exists('in_stock', $validated)) {
                $updates['in_stock'] = (int) ($validated['in_stock'] ?? 0);
            }
            if (array_key_exists('inventory_type', $validated)) {
                $updates['inventory_type'] = (string) ($validated['inventory_type'] ?? 'SINGLE');
            }
            if (array_key_exists('inventory_unit_type', $validated)) {
                $updates['inventory_unit_type'] = (string) ($validated['inventory_unit_type'] ?? 'WEIGHT');
            }
            if (array_key_exists('description', $validated)) {
                $updates['description'] = (string) $validated['description'];
            }
            if (array_key_exists('keywords', $validated)) {
                $updates['keywords'] = $validated['keywords'];
            }
            if (array_key_exists('default_pack_id', $validated)) {
                $updates['default_pack_id'] = (string) ($validated['default_pack_id'] ?? ' ');
            }
            if (array_key_exists('hsn_code', $validated)) {
                $updates['hsn_code'] = (string) $validated['hsn_code'];
            }
            if (array_key_exists('gst_percent', $validated)) {
                $updates['gst_percent'] = (float) ($validated['gst_percent'] ?? 0);
            }
            if (array_key_exists('order_limit', $validated)) {
                $updates['order_limit'] = (int) ($validated['order_limit'] ?? 0);
            }
            if (array_key_exists('buffer_limit', $validated)) {
                $updates['buffer_limit'] = (int) ($validated['buffer_limit'] ?? 0);
            }
            if (array_key_exists('product_pack_count', $validated) || array_key_exists('nop', $validated)) {
                $updates['product_pack_count'] = (int) (
                    $validated['product_pack_count']
                        ?? $validated['nop']
                        ?? 0
                );
                $updates['nop'] = (int) (
                    $validated['nop']
                        ?? $validated['product_pack_count']
                        ?? 0
                );
            }
            if (array_key_exists('pack_prd_wt', $validated)) {
                $updates['pack_prd_wt'] = $validated['pack_prd_wt'] !== null
                    ? (float) $validated['pack_prd_wt']
                    : null;
            }
            if (array_key_exists('gross_wt_of_pack', $validated)) {
                $updates['gross_wt_of_pack'] = $validated['gross_wt_of_pack'] !== null
                    ? (float) $validated['gross_wt_of_pack']
                    : null;
            }
            if (array_key_exists('gst_tax_type', $validated)) {
                $updates['gst_tax_type'] = $validated['gst_tax_type'] !== null
                    ? trim((string) $validated['gst_tax_type'])
                    : null;
            }
            if (array_key_exists('packs', $validated)) {
                $packsValue = $validated['packs'];
                if (is_array($packsValue)) {
                    $packsValue = json_encode($packsValue, JSON_UNESCAPED_UNICODE);
                }
                $updates['packs'] = $packsValue;
            }

            if (!empty($updates)) {
                DB::table('product')->where('product_id', $id)->update($updates);
            }

            $updated = DB::table('product')->where('product_id', $id)->first();

            return response()->json([
                'success' => true,
                'message' => 'Product updated successfully',
                'data' => (array) $updated,
            ]);
        } catch (\Exception $e) {
            Log::error('Product update error', ['error' => $e->getMessage(), 'product_id' => $id]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to update product',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $product = DB::table('product')
                ->where('product_id', $id)
                ->first();

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Product not found',
                ], 404);
            }

            if ((int) ($product->is_deleted ?? 0) === 1) {
                return response()->json([
                    'success' => true,
                    'message' => 'Product already deleted',
                ]);
            }

            DB::table('product')
                ->where('product_id', $id)
                ->update([
                    'is_deleted' => 1,
                ]);

            return response()->json([
                'success' => true,
                'message' => 'Product deleted successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Product delete error', ['error' => $e->getMessage(), 'product_id' => $id]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to delete product',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
