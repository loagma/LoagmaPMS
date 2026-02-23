<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class StockVoucherController extends Controller
{
    public function index(): JsonResponse
    {
        try {
            $vouchers = DB::table('stock_voucher')
                ->select('id', 'voucher_type', 'status', 'voucher_date', 'remarks', 'posted_at', 'created_at', 'updated_at')
                ->orderBy('created_at', 'desc')
                ->get();

            $result = $vouchers->map(function ($voucher) {
                $items = DB::table('stock_voucher_items as svi')
                    ->join('product as p', 'svi.product_id', '=', 'p.product_id')
                    ->where('svi.voucher_id', $voucher->id)
                    ->select('p.name')
                    ->limit(3)
                    ->pluck('name');
                $count = DB::table('stock_voucher_items')
                    ->where('voucher_id', $voucher->id)
                    ->count();
                $voucher->items_count = $count;
                $voucher->items_preview = $items->implode(', ');
                return $voucher;
            });

            return response()->json([
                'success' => true,
                'data' => $result
            ]);
        } catch (\Exception $e) {
            Log::error('Stock voucher list failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch vouchers',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id): JsonResponse
    {
        try {
            $voucher = DB::table('stock_voucher')
                ->where('id', $id)
                ->first();

            if (!$voucher) {
                return response()->json([
                    'success' => false,
                    'message' => 'Voucher not found'
                ], 404);
            }

            $items = DB::table('stock_voucher_items as svi')
                ->join('product as p', 'svi.product_id', '=', 'p.product_id')
                ->where('svi.voucher_id', $id)
                ->select('svi.id as item_id', 'svi.product_id', 'p.name as product_name', 'svi.quantity', 'svi.unit_type')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'voucher' => $voucher,
                    'items' => $items
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Stock voucher fetch failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch voucher',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'voucher_type' => 'required|in:IN,OUT',
                'status' => 'required|in:DRAFT,POSTED',
                'voucher_date' => 'nullable|date',
                'remarks' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.product_id' => 'required|integer|exists:product,product_id',
                'items.*.quantity' => 'required|numeric|min:0.001',
                'items.*.unit_type' => 'required|string|max:20',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Validate stock for OUT vouchers
            if ($request->status === 'POSTED' && $request->voucher_type === 'OUT') {
                $stockError = $this->validateStock($request->items);
                if ($stockError) {
                    return response()->json([
                        'success' => false,
                        'message' => $stockError['message'],
                        'errors' => $stockError['errors'],
                    ], 422);
                }
            }

            DB::beginTransaction();

            $voucherId = DB::table('stock_voucher')->insertGetId([
                'voucher_type' => $request->voucher_type,
                'status' => $request->status,
                'voucher_date' => $request->voucher_date ?: now()->format('Y-m-d'),
                'remarks' => $request->remarks,
                'posted_at' => $request->status === 'POSTED' ? now() : null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($request->items as $item) {
                DB::table('stock_voucher_items')->insert([
                    'voucher_id' => $voucherId,
                    'product_id' => $item['product_id'],
                    'quantity' => $item['quantity'],
                    'unit_type' => $item['unit_type'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Update stock if posted
            if ($request->status === 'POSTED') {
                if ($request->voucher_type === 'IN') {
                    $this->increaseStock($request->items);
                } else {
                    $this->reduceStock($request->items);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Stock voucher created successfully',
                'data' => ['voucher_id' => $voucherId, 'status' => $request->status]
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Stock voucher creation failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to create voucher',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'voucher_type' => 'required|in:IN,OUT',
                'status' => 'required|in:DRAFT,POSTED',
                'voucher_date' => 'nullable|date',
                'remarks' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.product_id' => 'required|integer|exists:product,product_id',
                'items.*.quantity' => 'required|numeric|min:0.001',
                'items.*.unit_type' => 'required|string|max:20',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $existing = DB::table('stock_voucher')->where('id', $id)->first();
            if (!$existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'Voucher not found'
                ], 404);
            }

            DB::beginTransaction();

            // Get existing items to reverse stock if needed
            $existingItems = DB::table('stock_voucher_items')
                ->where('voucher_id', $id)
                ->get()
                ->map(fn ($r) => [
                    'product_id' => $r->product_id,
                    'quantity' => (float) $r->quantity,
                ])
                ->all();

            // Reverse previous stock changes if voucher was posted
            if ($existing->status === 'POSTED' && count($existingItems) > 0) {
                if ($existing->voucher_type === 'IN') {
                    $this->reduceStock($existingItems);
                } else {
                    $this->increaseStock($existingItems);
                }
            }

            // Validate stock for OUT vouchers
            if ($request->status === 'POSTED' && $request->voucher_type === 'OUT') {
                $itemsForValidation = array_map(fn ($m) => [
                    'product_id' => $m['product_id'],
                    'quantity' => (float) $m['quantity'],
                ], $request->items);
                $stockError = $this->validateStock($itemsForValidation);
                if ($stockError) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => $stockError['message'],
                        'errors' => $stockError['errors'],
                    ], 422);
                }
            }

            DB::table('stock_voucher')
                ->where('id', $id)
                ->update([
                    'voucher_type' => $request->voucher_type,
                    'status' => $request->status,
                    'voucher_date' => $request->voucher_date ?: $existing->voucher_date,
                    'remarks' => $request->remarks,
                    'posted_at' => $request->status === 'POSTED' && !$existing->posted_at
                        ? now()
                        : $existing->posted_at,
                    'updated_at' => now(),
                ]);

            DB::table('stock_voucher_items')->where('voucher_id', $id)->delete();

            foreach ($request->items as $item) {
                DB::table('stock_voucher_items')->insert([
                    'voucher_id' => $id,
                    'product_id' => $item['product_id'],
                    'quantity' => $item['quantity'],
                    'unit_type' => $item['unit_type'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Apply new stock changes if posted
            if ($request->status === 'POSTED') {
                if ($request->voucher_type === 'IN') {
                    $this->increaseStock($request->items);
                } else {
                    $this->reduceStock($request->items);
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Stock voucher updated successfully',
                'data' => ['voucher_id' => (int) $id, 'status' => $request->status]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Stock voucher update failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to update voucher',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function validateStock(array $items): ?array
    {
        $errors = [];
        foreach ($items as $index => $item) {
            $productId = (int) $item['product_id'];
            $quantity = (float) $item['quantity'];
            
            $product = DB::table('product')
                ->where('product_id', $productId)
                ->select('product_id', 'name', 'stock')
                ->first();
            if (!$product) {
                $errors["items.{$index}"] = ['Product not found'];
                continue;
            }
            
            $vendorProductsStock = $this->getVendorProductsTotalStock($productId);
            $availableStock = $vendorProductsStock > 0 ? $vendorProductsStock : ($product->stock !== null ? (float) $product->stock : 0);
            
            if ($availableStock < $quantity) {
                $productName = $product->name ?? "Product #{$productId}";
                $errors["items.{$index}"] = [
                    "Insufficient stock for {$productName}. Available: {$availableStock}, Required: {$quantity}",
                ];
            }
        }
        if (count($errors) > 0) {
            return [
                'message' => 'Insufficient stock',
                'errors' => $errors,
            ];
        }
        return null;
    }

    private function getVendorProductsTotalStock(int $productId): float
    {
        $vendorProducts = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->get();

        $totalStock = 0;
        foreach ($vendorProducts as $vendorProduct) {
            try {
                $packsData = json_decode($vendorProduct->packs, true);
                if (is_array($packsData)) {
                    foreach ($packsData as $packData) {
                        if (isset($packData['stk'])) {
                            $totalStock += (float) $packData['stk'];
                        }
                    }
                }
            } catch (\Exception $e) {
                Log::warning('Error parsing vendor product packs', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'error' => $e->getMessage()
                ]);
            }
        }
        return $totalStock;
    }

    private function increaseStock(array $items): void
    {
        foreach ($items as $item) {
            $productId = (int) $item['product_id'];
            $quantity = (float) $item['quantity'];
            
            $this->updateVendorProductStock($productId, $quantity, 'increase');
            
            DB::statement(
                'UPDATE product SET stock = COALESCE(stock, 0) + ? WHERE product_id = ?',
                [$quantity, $productId]
            );
        }
    }

    private function reduceStock(array $items): void
    {
        foreach ($items as $item) {
            $productId = (int) $item['product_id'];
            $quantity = (float) $item['quantity'];
            
            $this->updateVendorProductStock($productId, $quantity, 'reduce');
            
            $product = DB::table('product')->where('product_id', $productId)->first();
            $currentStock = $product && $product->stock !== null ? (float) $product->stock : 0;
            
            if ($currentStock > 0) {
                $reduceAmount = min($quantity, $currentStock);
                DB::update(
                    'UPDATE product SET stock = COALESCE(stock, 0) - ? WHERE product_id = ?',
                    [$reduceAmount, $productId]
                );
            }
        }
    }

    private function updateVendorProductStock(int $productId, float $quantity, string $operation): void
    {
        $vendorProducts = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->get();

        if ($vendorProducts->isEmpty()) {
            return;
        }

        foreach ($vendorProducts as $vendorProduct) {
            try {
                $packsData = json_decode($vendorProduct->packs, true);
                if (!is_array($packsData) || empty($packsData)) {
                    continue;
                }

                $totalStock = 0;
                foreach ($packsData as $packData) {
                    if (isset($packData['stk'])) {
                        $totalStock += (float) $packData['stk'];
                    }
                }

                if ($operation === 'reduce' && $totalStock <= 0) {
                    continue;
                }

                $updatedPacks = [];
                foreach ($packsData as $packId => $packData) {
                    if (isset($packData['stk'])) {
                        $currentStock = (float) $packData['stk'];
                        
                        if ($operation === 'increase') {
                            $newStock = $currentStock + $quantity;
                        } else {
                            $newStock = max(0, $currentStock - $quantity);
                        }
                        
                        $packData['stk'] = $newStock;
                        $packData['in_stk'] = $newStock > 0 ? 1 : 0;
                    }
                    $updatedPacks[$packId] = $packData;
                }

                $updatedPacksJson = json_encode($updatedPacks);
                DB::table('vendor_products')
                    ->where('id', $vendorProduct->id)
                    ->update([
                        'packs' => $updatedPacksJson,
                        'in_stock' => $this->hasAnyStock($updatedPacks) ? '1' : '0'
                    ]);

                Log::info("Vendor product stock {$operation}d", [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'quantity' => $quantity,
                    'operation' => $operation
                ]);

                break;
            } catch (\Exception $e) {
                Log::error('Error updating vendor product stock', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'error' => $e->getMessage()
                ]);
            }
        }
    }

    private function hasAnyStock(array $packs): bool
    {
        foreach ($packs as $pack) {
            if (isset($pack['stk']) && (float) $pack['stk'] > 0) {
                return true;
            }
        }
        return false;
    }
}
