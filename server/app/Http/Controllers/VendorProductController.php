<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class VendorProductController extends Controller
{
    /**
     * GET /api/vendor-products
     *
     * Optional query params:
     *   admin_vendor_id  – filter by vendor (deli_staff.admin_id)
     *   search           – product name / product_id substring
     *   limit / page     – pagination
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $limit = (int) $request->query('limit', 10);
            $page  = (int) $request->query('page', 1);
            $search        = trim((string) $request->query('search', ''));
            $adminVendorId = trim((string) $request->query('admin_vendor_id', ''));

            if ($limit < 1 || $limit > 100) {
                $limit = 10;
            }
            $offset = ($page - 1) * $limit;

            $query = DB::table('vendor_products as vp')
                ->join('product as p', 'vp.product_id', '=', 'p.product_id')
                ->select(
                    'vp.id',
                    'vp.admin_vendor_id',
                    'vp.product_id',
                    'p.name as product_name',
                    'p.hsn_code',
                    'p.gst_percent',
                    'p.inventory_type',
                    'p.inventory_unit_type',
                    'vp.packs',
                    'vp.default_pack_id',
                    'vp.status',
                    'vp.in_stock',
                    'vp.created_at'
                );

            // Filter by vendor when admin_vendor_id is supplied
            if ($adminVendorId !== '') {
                $query->where('vp.admin_vendor_id', (int) $adminVendorId);
            }

            // Multi-word AND search across product name, keywords, and product_id
            if ($search !== '') {
                $terms = preg_split('/\s+/', $search, -1, PREG_SPLIT_NO_EMPTY);
                foreach ($terms as $term) {
                    $like = '%' . addcslashes(strtolower($term), '\\%_') . '%';
                    $query->where(function ($q) use ($like) {
                        $q->whereRaw('LOWER(p.name) LIKE ?', [$like])
                          ->orWhereRaw('LOWER(p.keywords) LIKE ?', [$like])
                          ->orWhereRaw('CAST(vp.product_id AS CHAR) LIKE ?', [$like]);
                    });
                }
            }

            // Fetch without pagination first to deduplicate by product_id
            $vendorProducts = (clone $query)->orderBy('p.name')->get();

            // Deduplicate: one product entry per product_id, merging packs
            $byProductId = [];
            foreach ($vendorProducts as $vp) {
                $pid   = $vp->product_id;
                $packs = json_decode($vp->packs, true) ?? [];

                // Normalise object-keyed map → array
                $packsArray = (is_array($packs) && !isset($packs[0]))
                    ? array_values($packs)
                    : $packs;

                $reshapedPacks = [];
                foreach ($packsArray as $pack) {
                    if (!is_array($pack)) continue;
                    $inStk = isset($pack['in_stk']) ? (int) $pack['in_stk'] : 1;
                    if ($inStk === 0) continue;
                    $packId = trim((string) ($pack['pi'] ?? ''));
                    if ($packId === '') continue;
                    $desc = trim((string) ($pack['ps'] ?? $packId));
                    $unit = trim((string) ($pack['pu'] ?? ''));
                    // Strip non-UTF-8 bytes so json_encode never fails on these strings
                    $desc = mb_convert_encoding($desc, 'UTF-8', 'UTF-8');
                    $unit = mb_convert_encoding($unit, 'UTF-8', 'UTF-8');
                    $packId = mb_convert_encoding($packId, 'UTF-8', 'UTF-8');
                    $reshapedPacks[$packId] = [
                        'id'           => $packId,
                        'description'  => $desc,
                        'unit'         => $unit,
                        'market_price' => isset($pack['op']) ? (float) $pack['op'] : null,
                    ];
                }

                if (!isset($byProductId[$pid])) {
                    $byProductId[$pid] = [
                        'product_id'          => $pid,
                        'name'                => mb_convert_encoding(trim((string) $vp->product_name), 'UTF-8', 'UTF-8'),
                        'hsn_code'            => $vp->hsn_code,
                        'gst_percent'         => $vp->gst_percent,
                        'inventory_type'      => $vp->inventory_type,
                        'inventory_unit_type' => $vp->inventory_unit_type,
                        'packs'               => $reshapedPacks,
                        'default_pack_id'     => $vp->default_pack_id,
                        'vendor_product_id'   => $vp->id,
                        'admin_vendor_id'     => $vp->admin_vendor_id,
                    ];
                } else {
                    // Merge packs from additional vendor rows (union by pack id)
                    $byProductId[$pid]['packs'] += $reshapedPacks;
                }
            }

            // Re-index packs as plain arrays and apply pagination
            $allProducts = array_values(array_map(function ($item) {
                $item['packs'] = array_values($item['packs']);
                return $item;
            }, $byProductId));

            $total = count($allProducts);
            $data  = array_slice($allProducts, $offset, $limit);

            return response()->json([
                'success'    => true,
                'data'       => $data,
                'pagination' => [
                    'total'       => $total,
                    'page'        => $page,
                    'limit'       => $limit,
                    'total_pages' => (int) ceil($total / max($limit, 1)),
                ],
            ], 200, [], JSON_UNESCAPED_UNICODE);

        } catch (\Exception $e) {
            Log::error('Vendor products list failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch vendor products',
            ], 500);
        }
    }

    /**
     * GET /api/vendor-products/{id}
     */
    public function show(int $id): JsonResponse
    {
        try {
            $vp = DB::table('vendor_products as vp')
                ->join('product as p', 'vp.product_id', '=', 'p.product_id')
                ->where('vp.id', $id)
                ->select(
                    'vp.id',
                    'vp.admin_vendor_id',
                    'vp.product_id',
                    'p.name as product_name',
                    'p.hsn_code',
                    'p.gst_percent',
                    'p.inventory_type',
                    'p.inventory_unit_type',
                    'vp.packs',
                    'vp.default_pack_id',
                    'vp.status',
                    'vp.in_stock',
                    'vp.created_at'
                )
                ->first();

            if (!$vp) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vendor product not found',
                ], 404);
            }

            $packs       = json_decode($vp->packs, true) ?? [];
            $packsArray  = (is_array($packs) && !isset($packs[0]))
                ? array_values($packs)
                : $packs;
            $reshapedPacks = [];

            foreach ($packsArray as $pack) {
                if (!is_array($pack)) continue;
                $inStk = isset($pack['in_stk']) ? (int) $pack['in_stk'] : 1;
                if ($inStk === 0) continue;
                $id2 = trim((string) ($pack['pi'] ?? ''));
                if ($id2 === '') continue;
                $reshapedPacks[] = [
                    'id'           => $id2,
                    'description'  => trim((string) ($pack['ps'] ?? $id2)),
                    'unit'         => trim((string) ($pack['pu'] ?? '')),
                    'market_price' => isset($pack['op']) ? (float) $pack['op'] : null,
                ];
            }

            return response()->json([
                'success' => true,
                'data'    => [
                    'product_id'          => $vp->product_id,
                    'name'                => $vp->product_name,
                    'hsn_code'            => $vp->hsn_code,
                    'gst_percent'         => $vp->gst_percent,
                    'inventory_type'      => $vp->inventory_type,
                    'inventory_unit_type' => $vp->inventory_unit_type,
                    'packs'               => $reshapedPacks,
                    'default_pack_id'     => $vp->default_pack_id,
                    'vendor_product_id'   => $vp->id,
                    'admin_vendor_id'     => $vp->admin_vendor_id,
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Vendor product fetch failed', [
                'id'    => $id,
                'error' => $e->getMessage(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch vendor product',
            ], 500);
        }
    }
}
