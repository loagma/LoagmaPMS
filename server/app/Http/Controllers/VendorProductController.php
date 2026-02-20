<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class VendorProductController extends Controller
{
    /**
     * Get list of vendor products with pagination and search
     * 
     * GET /api/vendor-products
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $limit = (int) $request->query('limit', 10);
            $page = (int) $request->query('page', 1);
            $search = $request->query('search', '');
            
            // Validate limit
            if ($limit < 1 || $limit > 100) {
                $limit = 10;
            }
            
            // Calculate offset
            $offset = ($page - 1) * $limit;
            
            // Build query
            $query = DB::table('vendor_products as vp')
                ->join('product as p', 'vp.product_id', '=', 'p.product_id')
                ->select(
                    'vp.id',
                    'vp.admin_vendor_id',
                    'vp.product_id',
                    'p.name as product_name',
                    'vp.packs',
                    'vp.default_pack_id',
                    'vp.status',
                    'vp.in_stock',
                    'vp.created_at'
                );
            
            // Apply search filter
            if (!empty($search)) {
                $query->where('p.name', 'LIKE', '%' . $search . '%');
            }
            
            // Get total count for pagination info
            $total = $query->count();
            
            // Apply pagination
            $vendorProducts = $query
                ->orderBy('vp.id', 'desc')
                ->limit($limit)
                ->offset($offset)
                ->get();
            
            // Format response
            $data = $vendorProducts->map(function ($vp) {
                // Parse packs to calculate actual in_stock status
                $packs = json_decode($vp->packs, true) ?? [];
                $hasStock = false;
                
                if (!empty($packs)) {
                    // Handle both array format and object format
                    $packsArray = is_array($packs) && !isset($packs[0]) 
                        ? array_values($packs) // Convert object to array
                        : $packs;
                    
                    foreach ($packsArray as $pack) {
                        if (is_array($pack) && isset($pack['stk']) && $pack['stk'] > 0) {
                            $hasStock = true;
                            break;
                        }
                    }
                }
                
                return [
                    'id' => $vp->id,
                    'admin_vendor_id' => $vp->admin_vendor_id,
                    'product_id' => $vp->product_id,
                    'product_name' => $vp->product_name,
                    'packs' => $vp->packs,
                    'default_pack_id' => $vp->default_pack_id,
                    'status' => $vp->status,
                    'in_stock' => $hasStock ? '1' : '0', // Calculate based on actual pack stock
                    'created_at' => $vp->created_at,
                ];
            });
            
            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'total_pages' => ceil($total / $limit),
                ],
            ]);
            
        } catch (\Exception $e) {
            Log::error('Vendor products list failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch vendor products',
                'error' => $e->getMessage()
            ], 500);
        }
    }
    
    /**
     * Get a single vendor product by ID
     * 
     * GET /api/vendor-products/{id}
     * 
     * @param int $id
     * @return JsonResponse
     */
    public function show(int $id): JsonResponse
    {
        try {
            $vendorProduct = DB::table('vendor_products as vp')
                ->join('product as p', 'vp.product_id', '=', 'p.product_id')
                ->where('vp.id', $id)
                ->select(
                    'vp.id',
                    'vp.admin_vendor_id',
                    'vp.product_id',
                    'p.name as product_name',
                    'vp.packs',
                    'vp.default_pack_id',
                    'vp.status',
                    'vp.in_stock',
                    'vp.created_at'
                )
                ->first();
            
            if (!$vendorProduct) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vendor product not found'
                ], 404);
            }
            
            // Parse packs to calculate actual in_stock status
            $packs = json_decode($vendorProduct->packs, true) ?? [];
            $hasStock = false;
            
            if (!empty($packs)) {
                // Handle both array format and object format
                $packsArray = is_array($packs) && !isset($packs[0]) 
                    ? array_values($packs) // Convert object to array
                    : $packs;
                
                foreach ($packsArray as $pack) {
                    if (is_array($pack) && isset($pack['stk']) && $pack['stk'] > 0) {
                        $hasStock = true;
                        break;
                    }
                }
            }
            
            return response()->json([
                'success' => true,
                'data' => [
                    'id' => $vendorProduct->id,
                    'admin_vendor_id' => $vendorProduct->admin_vendor_id,
                    'product_id' => $vendorProduct->product_id,
                    'product_name' => $vendorProduct->product_name,
                    'packs' => $vendorProduct->packs,
                    'default_pack_id' => $vendorProduct->default_pack_id,
                    'status' => $vendorProduct->status,
                    'in_stock' => $hasStock ? '1' : '0', // Calculate based on actual pack stock
                    'created_at' => $vendorProduct->created_at,
                ],
            ]);
            
        } catch (\Exception $e) {
            Log::error('Vendor product fetch failed', [
                'id' => $id,
                'error' => $e->getMessage()
            ]);
            
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch vendor product',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
