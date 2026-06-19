<?php

namespace App\Http\Controllers;

use App\Services\InventoryLedgerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ReceiveFromProductionController extends Controller
{
    public function index(): JsonResponse
    {
        try {
            $receives = DB::table('receive_from_production')
                ->select('id', 'status', 'remarks', 'received_at', 'created_at', 'updated_at')
                ->orderBy('created_at', 'desc')
                ->get();

            $result = $receives->map(function ($receive) {
                $items = DB::table('receive_from_production_items as rfpi')
                    ->join('product as p', 'rfpi.finished_product_id', '=', 'p.product_id')
                    ->where('rfpi.receive_id', $receive->id)
                    ->select('p.name')
                    ->limit(3)
                    ->pluck('name');
                $count = DB::table('receive_from_production_items')
                    ->where('receive_id', $receive->id)
                    ->count();
                $receive->items_count = $count;
                $receive->items_preview = $items->implode(', ');
                return $receive;
            });

            return response()->json([
                'success' => true,
                'data' => $result
            ]);
        } catch (\Exception $e) {
            Log::error('Receive from production list failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch receives',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id): JsonResponse
    {
        try {
            $receive = DB::table('receive_from_production')
                ->where('id', $id)
                ->first();

            if (!$receive) {
                return response()->json([
                    'success' => false,
                    'message' => 'Receive not found'
                ], 404);
            }

            $items = DB::table('receive_from_production_items as rfpi')
                ->join('product as p', 'rfpi.finished_product_id', '=', 'p.product_id')
                ->where('rfpi.receive_id', $id)
                ->select('rfpi.id as item_id', 'rfpi.finished_product_id', 'p.name as finished_product_name', 'rfpi.quantity', 'rfpi.unit_type')
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'receive' => $receive,
                    'items' => $items
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('Receive fetch failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch receive',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'status' => 'required|in:DRAFT,RECEIVED',
                'remarks' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.finished_product_id' => 'required|integer|exists:product,product_id',
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

            DB::beginTransaction();

            $receiveId = DB::table('receive_from_production')->insertGetId([
                'status' => $request->status,
                'remarks' => $request->remarks,
                'received_at' => $request->status === 'RECEIVED' ? now() : null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($request->items as $item) {
                DB::table('receive_from_production_items')->insert([
                    'receive_id' => $receiveId,
                    'finished_product_id' => $item['finished_product_id'],
                    'quantity' => $item['quantity'],
                    'unit_type' => $item['unit_type'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Update stock if received
            if ($request->status === 'RECEIVED') {
                $invDate = now()->format('Y-m-d');
                $this->increaseStock($request->items, $receiveId, $invDate);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Receive created successfully',
                'data' => ['receive_id' => $receiveId, 'status' => $request->status]
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Receive creation failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to create receive',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'status' => 'required|in:DRAFT,RECEIVED',
                'remarks' => 'nullable|string',
                'items' => 'required|array|min:1',
                'items.*.finished_product_id' => 'required|integer|exists:product,product_id',
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

            $existing = DB::table('receive_from_production')->where('id', $id)->first();
            if (!$existing) {
                return response()->json([
                    'success' => false,
                    'message' => 'Receive not found'
                ], 404);
            }

            DB::beginTransaction();

            // Get existing items to reverse stock if needed
            $existingItems = DB::table('receive_from_production_items')
                ->where('receive_id', $id)
                ->get()
                ->map(fn ($r) => [
                    'finished_product_id' => $r->finished_product_id,
                    'quantity' => (float) $r->quantity,
                ])
                ->all();

            // Reverse previous stock changes if receive was posted
            if ($existing->status === 'RECEIVED' && count($existingItems) > 0) {
                $invDate = now()->format('Y-m-d');
                $this->reduceStock($existingItems, (int) $id, $invDate);
            }

            DB::table('receive_from_production')
                ->where('id', $id)
                ->update([
                    'status' => $request->status,
                    'remarks' => $request->remarks,
                    'received_at' => $request->status === 'RECEIVED' && !$existing->received_at
                        ? now()
                        : $existing->received_at,
                    'updated_at' => now(),
                ]);

            DB::table('receive_from_production_items')->where('receive_id', $id)->delete();

            foreach ($request->items as $item) {
                DB::table('receive_from_production_items')->insert([
                    'receive_id' => $id,
                    'finished_product_id' => $item['finished_product_id'],
                    'quantity' => $item['quantity'],
                    'unit_type' => $item['unit_type'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }

            // Apply new stock changes if received
            if ($request->status === 'RECEIVED') {
                $invDate = now()->format('Y-m-d');
                $this->increaseStock($request->items, (int) $id, $invDate);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Receive updated successfully',
                'data' => ['receive_id' => (int) $id, 'status' => $request->status]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Receive update failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to update receive',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    private function increaseStock(array $items, int $receiveId, string $invDate): void
    {
        $ledger = app(InventoryLedgerService::class);
        foreach ($items as $item) {
            $productId = (int) $item['finished_product_id'];
            $quantity  = (float) $item['quantity'];

            $vp = $ledger->resolveVendorProduct($productId);
            if ($vp) {
                $ledger->updatePacksStock($vp->id, $quantity, 'increase');
                $ledger->recordLedger(
                    vendorProductId: $vp->id,
                    productId:       $productId,
                    packId:          '',
                    quantity:        $quantity,
                    unitType:        (string) ($item['unit_type'] ?? 'Nos'),
                    amount:          0,
                    actionType:      'receive_from_production',
                    invType:         'CREDIT',
                    source:          'production_receive',
                    note:            "Receive from Production #{$receiveId} - Product #{$productId}",
                    invDate:         $invDate,
                );
            } else {
                Log::warning('ReceiveFromProduction increaseStock: no vendor_product', ['product_id' => $productId, 'receive_id' => $receiveId]);
            }

            DB::statement('UPDATE product SET stock = COALESCE(stock, 0) + ? WHERE product_id = ?', [$quantity, $productId]);
        }
    }

    private function reduceStock(array $items, int $receiveId, string $invDate): void
    {
        $ledger = app(InventoryLedgerService::class);
        foreach ($items as $item) {
            $productId = (int) $item['finished_product_id'];
            $quantity  = (float) $item['quantity'];

            $vp = $ledger->resolveVendorProduct($productId);
            if ($vp) {
                $ledger->updatePacksStock($vp->id, $quantity, 'decrease');
                $ledger->recordLedger(
                    vendorProductId: $vp->id,
                    productId:       $productId,
                    packId:          '',
                    quantity:        $quantity,
                    unitType:        (string) ($item['unit_type'] ?? 'Nos'),
                    amount:          0,
                    actionType:      'receive_from_production_reversal',
                    invType:         'DEBIT',
                    source:          'production_receive_reversal',
                    note:            "Receive from Production Reversal #{$receiveId} - Product #{$productId}",
                    invDate:         $invDate,
                );
            } else {
                Log::warning('ReceiveFromProduction reduceStock: no vendor_product', ['product_id' => $productId, 'receive_id' => $receiveId]);
            }

            $product      = DB::table('product')->where('product_id', $productId)->first();
            $currentStock = $product && $product->stock !== null ? (float) $product->stock : 0;
            if ($currentStock > 0) {
                $reduceAmount = min($quantity, $currentStock);
                DB::update('UPDATE product SET stock = COALESCE(stock, 0) - ? WHERE product_id = ?', [$reduceAmount, $productId]);
            }
        }
    }

}
