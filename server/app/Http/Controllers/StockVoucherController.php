<?php

namespace App\Http\Controllers;

use App\Services\InventoryLedgerService;
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

            // Idempotency: a retried submission with the same key replays the original result
            // instead of creating a second voucher and double-applying stock.
            $idempotencyKey = $request->header('Idempotency-Key') ?: $request->input('idempotency_key');
            if ($idempotencyKey) {
                $existing = DB::table('stock_voucher')->where('idempotency_key', $idempotencyKey)->first();
                if ($existing) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Stock voucher created successfully',
                        'data' => ['voucher_id' => $existing->id, 'status' => $existing->status],
                    ], 200);
                }
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
                'idempotency_key' => $idempotencyKey ?: null,
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

            // Ledger entries — inside the transaction so a ledger failure rolls back the
            // stock change instead of leaving an unexplained movement (audit gap).
            if ($request->status === 'POSTED') {
                $svType   = $request->voucher_type;
                $svDate   = $request->voucher_date ?: now()->format('Y-m-d');
                $ledger   = app(InventoryLedgerService::class);
                foreach ($request->items as $svItem) {
                    $pid = (int) ($svItem['product_id'] ?? 0);
                    $vp  = $ledger->resolveVendorProduct($pid, null);
                    if (!$vp) { Log::warning('StockVoucher store: no vendor_product', ['product_id' => $pid, 'voucher_id' => $voucherId]); continue; }
                    $ledger->recordLedger(
                        vendorProductId: $vp->id,
                        productId:       $pid,
                        packId:          '',
                        quantity:        (float) ($svItem['quantity'] ?? 0),
                        unitType:        (string) ($svItem['unit_type'] ?? 'Nos'),
                        amount:          0,
                        actionType:      $svType === 'IN' ? 'stock_in' : 'stock_out',
                        invType:         $svType === 'IN' ? 'CREDIT' : 'DEBIT',
                        source:          'stock_voucher',
                        note:            "Stock Voucher #{$voucherId} {$svType} - " . ($svItem['unit_type'] ?? ''),
                        invDate:         $svDate,
                    );
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Stock voucher created successfully',
                'data' => ['voucher_id' => $voucherId, 'status' => $request->status]
            ], 201);
        } catch (\RuntimeException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 409);
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

            // Ledger entries for the final (new) stock application only — not the reversal.
            // Inside the transaction so a ledger failure rolls back the stock change.
            if ($request->status === 'POSTED') {
                $svType   = $request->voucher_type;
                $svDate   = $request->voucher_date ?: ($existing->voucher_date ?? now()->format('Y-m-d'));
                $ledger   = app(InventoryLedgerService::class);
                foreach ($request->items as $svItem) {
                    $pid = (int) ($svItem['product_id'] ?? 0);
                    $vp  = $ledger->resolveVendorProduct($pid, null);
                    if (!$vp) { Log::warning('StockVoucher update: no vendor_product', ['product_id' => $pid, 'voucher_id' => $id]); continue; }
                    $ledger->recordLedger(
                        vendorProductId: $vp->id,
                        productId:       $pid,
                        packId:          '',
                        quantity:        (float) ($svItem['quantity'] ?? 0),
                        unitType:        (string) ($svItem['unit_type'] ?? 'Nos'),
                        amount:          0,
                        actionType:      $svType === 'IN' ? 'stock_in' : 'stock_out',
                        invType:         $svType === 'IN' ? 'CREDIT' : 'DEBIT',
                        source:          'stock_voucher',
                        note:            "Stock Voucher #{$id} {$svType} - " . ($svItem['unit_type'] ?? ''),
                        invDate:         $svDate,
                    );
                }
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Stock voucher updated successfully',
                'data' => ['voucher_id' => (int) $id, 'status' => $request->status]
            ]);
        } catch (\RuntimeException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 409);
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
                ->select('product_id', 'name', 'stock', 'inventory_type')
                ->first();
            if (!$product) {
                $errors["items.{$index}"] = ['Product not found'];
                continue;
            }

            // Each product type has ONE source of truth: PACK_WISE → vendor_products.packs,
            // SINGLE → products.stock. Read whichever applies (no cross-store fallback).
            $availableStock = $this->isPackWise($product->inventory_type ?? null)
                ? $this->getVendorProductsTotalStock($productId)
                : ($product->stock !== null ? (float) $product->stock : 0.0);

            if ($availableStock + 1e-9 < $quantity) {
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

    /** True when the product tracks stock per-pack (vendor_products.packs) rather than as a single products.stock value. */
    private function isPackWise(?string $inventoryType): bool
    {
        return strtoupper(trim((string) ($inventoryType ?? 'SINGLE'))) === 'PACK_WISE';
    }

    private function productIsPackWise(int $productId): bool
    {
        return $this->isPackWise(DB::table('product')->where('product_id', $productId)->value('inventory_type'));
    }

    private function increaseStock(array $items): void
    {
        foreach ($items as $item) {
            $productId = (int) $item['product_id'];
            $quantity = (float) $item['quantity'];

            if ($this->productIsPackWise($productId)) {
                // PACK_WISE: vendor_products.packs is authoritative; products.stock is then
                // re-derived from the pack totals by the aggregator so the two cannot diverge.
                $this->updateVendorProductStock($productId, $quantity, 'increase');
                app(\App\Services\ProductStockAggregator::class)->updateProductStock($productId);
            } else {
                // SINGLE: stock lives directly on products.stock.
                DB::update('UPDATE product SET stock = COALESCE(stock, 0) + ? WHERE product_id = ?', [$quantity, $productId]);
            }
        }
    }

    private function reduceStock(array $items): void
    {
        foreach ($items as $item) {
            $productId = (int) $item['product_id'];
            $quantity = (float) $item['quantity'];

            if ($this->productIsPackWise($productId)) {
                $this->updateVendorProductStock($productId, $quantity, 'reduce');
                app(\App\Services\ProductStockAggregator::class)->updateProductStock($productId);
            } else {
                // SINGLE: lock the row, reject if insufficient, then deduct exactly (no clamp).
                $row = DB::table('product')->where('product_id', $productId)->lockForUpdate()->first();
                $current = $row && $row->stock !== null ? (float) $row->stock : 0.0;
                if ($current + 1e-9 < $quantity) {
                    throw new \RuntimeException(
                        "Insufficient stock for product {$productId}. Available: {$current}, Requested: {$quantity}"
                    );
                }
                DB::update('UPDATE product SET stock = ? WHERE product_id = ?', [$current - $quantity, $productId]);
            }
        }
    }

    private function updateVendorProductStock(int $productId, float $quantity, string $operation): void
    {
        // Lock the vendor_products rows for the duration of the transaction so a concurrent
        // voucher cannot slip stock out between the validation read and this deduction.
        $vendorProducts = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->lockForUpdate()
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

                $updatedPacks = [];
                foreach ($packsData as $packId => $packData) {
                    if (isset($packData['stk'])) {
                        $currentStock = (float) $packData['stk'];

                        if ($operation === 'increase') {
                            $newStock = $currentStock + $quantity;
                        } else {
                            // Reject rather than silently clamp to 0. The throw rolls back the
                            // whole transaction (stock + ledger), so the client can retry.
                            if ($currentStock + 1e-9 < $quantity) {
                                throw new \RuntimeException(
                                    "Insufficient stock for product {$productId} (pack {$packId}). " .
                                    "Available: {$currentStock}, Requested: {$quantity}"
                                );
                            }
                            $newStock = $currentStock - $quantity;
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
            } catch (\RuntimeException $e) {
                // Insufficient-stock rejection must propagate to roll back the transaction.
                throw $e;
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
