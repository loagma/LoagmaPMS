<?php

namespace App\Http\Controllers;

use App\Services\InventoryLedgerService;
use App\Services\StockManagerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class IssueToProductionController extends Controller
{
    private StockManagerService $stockManager;

    public function __construct(StockManagerService $stockManager)
    {
        $this->stockManager = $stockManager;
    }
    public function index(): JsonResponse
    {
        try {
            $issues = DB::table('issue_to_production')
                ->select(
                    'issue_id',
                    'status',
                    'remarks',
                    'issued_at',
                    'created_at',
                    'updated_at'
                )
                ->orderBy('created_at', 'desc')
                ->get();

            // Add materials summary for each issue
            $result = $issues->map(function ($issue) {
                $items = DB::table('issue_to_production_items as itpi')
                    ->join('product as p', 'itpi.raw_material_id', '=', 'p.product_id')
                    ->where('itpi.issue_id', $issue->issue_id)
                    ->select('p.name')
                    ->limit(3)
                    ->pluck('name');
                $count = DB::table('issue_to_production_items')
                    ->where('issue_id', $issue->issue_id)
                    ->count();
                $issue->materials_count = $count;
                $issue->materials_preview = $items->implode(', ');
                return $issue;
            });

            return response()->json([
                'success' => true,
                'data' => $result
            ]);

        } catch (\Exception $e) {
            Log::error('Issue to production list fetch failed', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch issues',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id): JsonResponse
    {
        try {
            $issue = DB::table('issue_to_production')
                ->where('issue_id', $id)
                ->select(
                    'issue_id',
                    'status',
                    'remarks',
                    'issued_at',
                    'created_at',
                    'updated_at'
                )
                ->first();

            if (!$issue) {
                return response()->json([
                    'success' => false,
                    'message' => 'Issue not found'
                ], 404);
            }

            // Get issue items
            $items = DB::table('issue_to_production_items as itpi')
                ->join('product as p', 'itpi.raw_material_id', '=', 'p.product_id')
                ->where('itpi.issue_id', $id)
                ->select(
                    'itpi.issue_item_id',
                    'itpi.raw_material_id',
                    'p.name as raw_material_name',
                    'itpi.quantity',
                    'itpi.unit_type'
                )
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'issue' => $issue,
                    'items' => $items
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Issue fetch failed', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch issue',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'status' => 'required|in:DRAFT,ISSUED',
                'remarks' => 'nullable|string',
                'materials' => 'required|array|min:1',
                'materials.*.raw_material_id' => 'required|integer|exists:product,product_id',
                'materials.*.quantity' => 'required|numeric|min:0.001',
                'materials.*.unit_type' => 'required|string|max:20',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            if ($request->status === 'ISSUED') {
                $stockError = $this->validateStock($request->materials);
                if ($stockError) {
                    return response()->json([
                        'success' => false,
                        'message' => $stockError['message'],
                        'errors' => $stockError['errors'],
                    ], 422);
                }
            }

            DB::beginTransaction();

            // Insert issue master (raw materials only)
            $issueId = DB::table('issue_to_production')->insertGetId([
                'status' => $request->status,
                'remarks' => $request->remarks,
                'issued_at' => $request->status === 'ISSUED' ? now() : null,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Insert issue items
            $issueItems = [];
            foreach ($request->materials as $material) {
                $issueItems[] = [
                    'issue_id' => $issueId,
                    'raw_material_id' => $material['raw_material_id'],
                    'quantity' => $material['quantity'],
                    'unit_type' => $material['unit_type'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            DB::table('issue_to_production_items')->insert($issueItems);

            if ($request->status === 'ISSUED') {
                $invDate = now()->format('Y-m-d');
                $this->reduceStock($request->materials, $issueId, $invDate);
            }

            DB::commit();

            Log::info('Issue to production created', [
                'issue_id' => $issueId,
                'status' => $request->status
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Issue created successfully',
                'data' => [
                    'issue_id' => $issueId,
                    'status' => $request->status,
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Issue creation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to create issue',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function update(Request $request, $id): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'status' => 'required|in:DRAFT,ISSUED',
                'remarks' => 'nullable|string',
                'materials' => 'required|array|min:1',
                'materials.*.raw_material_id' => 'required|integer|exists:product,product_id',
                'materials.*.quantity' => 'required|numeric|min:0.001',
                'materials.*.unit_type' => 'required|string|max:20',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            DB::beginTransaction();

            $existingIssue = DB::table('issue_to_production')->where('issue_id', $id)->first();

            if (!$existingIssue) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Issue not found'
                ], 404);
            }

            $existingItems = DB::table('issue_to_production_items')
                ->where('issue_id', $id)
                ->get()
                ->map(fn ($r) => [
                    'raw_material_id' => $r->raw_material_id,
                    'quantity' => (float) $r->quantity,
                ])
                ->all();

            if ($existingIssue->status === 'ISSUED' && count($existingItems) > 0) {
                $invDate = now()->format('Y-m-d');
                $this->restoreStock($existingItems, (int) $id, $invDate);
            }

            if ($request->status === 'ISSUED') {
                $materialsForValidation = array_map(fn ($m) => [
                    'raw_material_id' => $m['raw_material_id'],
                    'quantity' => (float) $m['quantity'],
                ], $request->materials);
                $stockError = $this->validateStock($materialsForValidation);
                if ($stockError) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => $stockError['message'],
                        'errors' => $stockError['errors'],
                    ], 422);
                }
            }

            // Update issue master (raw materials only)
            DB::table('issue_to_production')
                ->where('issue_id', $id)
                ->update([
                    'status' => $request->status,
                    'remarks' => $request->remarks,
                    'issued_at' => $request->status === 'ISSUED' && !$existingIssue->issued_at
                        ? now()
                        : $existingIssue->issued_at,
                    'updated_at' => now(),
                ]);

            // Delete existing items
            DB::table('issue_to_production_items')->where('issue_id', $id)->delete();

            // Insert new items
            $issueItems = [];
            foreach ($request->materials as $material) {
                $issueItems[] = [
                    'issue_id' => $id,
                    'raw_material_id' => $material['raw_material_id'],
                    'quantity' => $material['quantity'],
                    'unit_type' => $material['unit_type'],
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            DB::table('issue_to_production_items')->insert($issueItems);

            if ($request->status === 'ISSUED') {
                $invDate = now()->format('Y-m-d');
                $this->reduceStock($request->materials, (int) $id, $invDate);
            }

            DB::commit();

            Log::info('Issue to production updated', ['issue_id' => $id]);

            return response()->json([
                'success' => true,
                'message' => 'Issue updated successfully',
                'data' => [
                    'issue_id' => $id,
                    'status' => $request->status,
                ]
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Issue update failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to update issue',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Validate that sufficient stock exists for each material.
     * Checks both product table and vendor_products packs.
     * Returns null if valid, or array with message and errors if invalid.
     *
     * @param array $materials Array of ['raw_material_id' => int, 'quantity' => float]
     * @return array|null ['message' => string, 'errors' => array] or null
     */
    private function validateStock(array $materials): ?array
    {
        $errors = [];
        foreach ($materials as $index => $material) {
            $productId = (int) $material['raw_material_id'];
            $quantity = (float) $material['quantity'];
            
            // Check product table stock
            $product = DB::table('product')
                ->where('product_id', $productId)
                ->select('product_id', 'name', 'stock')
                ->first();
            if (!$product) {
                $errors["materials.{$index}"] = ['Product not found'];
                continue;
            }
            
            // Check vendor_products total stock
            $vendorProductsStock = $this->getVendorProductsTotalStock($productId);
            
            // Prioritize vendor_products stock if available, otherwise use product table stock
            $availableStock = $vendorProductsStock > 0 ? $vendorProductsStock : ($product->stock !== null ? (float) $product->stock : 0);
            
            if ($availableStock < $quantity) {
                $productName = $product->name ?? "Product #{$productId}";
                $errors["materials.{$index}"] = [
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

    /**
     * Get total stock from all vendor_products packs for a product
     * 
     * @param int $productId
     * @return float Total stock across all vendor products
     */
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
                Log::warning('Error parsing vendor product packs for stock validation', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'error' => $e->getMessage()
                ]);
            }
        }

        return $totalStock;
    }

    private function reduceStock(array $materials, int $issueId, string $invDate): void
    {
        $ledger = app(InventoryLedgerService::class);
        foreach ($materials as $material) {
            $productId = (int) $material['raw_material_id'];
            $quantity  = (float) $material['quantity'];

            $vp = $ledger->resolveVendorProduct($productId);
            if ($vp) {
                $ledger->updatePacksStock($vp->id, $quantity, 'decrease');
                $ledger->recordLedger(
                    vendorProductId: $vp->id,
                    productId:       $productId,
                    packId:          '',
                    quantity:        $quantity,
                    unitType:        (string) ($material['unit_type'] ?? 'Nos'),
                    amount:          0,
                    actionType:      'issue_to_production',
                    invType:         'DEBIT',
                    source:          'production_issue',
                    note:            "Issue to Production #{$issueId} - Product #{$productId}",
                    invDate:         $invDate,
                );
            } else {
                Log::warning('IssueToProduction reduceStock: no vendor_product', ['product_id' => $productId, 'issue_id' => $issueId]);
            }

            // Keep product.stock in sync for SINGLE-type products
            $product      = DB::table('product')->where('product_id', $productId)->first();
            $currentStock = $product && $product->stock !== null ? (float) $product->stock : 0;
            if ($currentStock > 0) {
                $reduceAmount = min($quantity, $currentStock);
                DB::update('UPDATE product SET stock = COALESCE(stock, 0) - ? WHERE product_id = ?', [$reduceAmount, $productId]);
            }
        }
    }

    private function restoreStock(array $materials, int $issueId, string $invDate): void
    {
        $ledger = app(InventoryLedgerService::class);
        foreach ($materials as $material) {
            $productId = (int) $material['raw_material_id'];
            $quantity  = (float) $material['quantity'];

            $vp = $ledger->resolveVendorProduct($productId);
            if ($vp) {
                $ledger->updatePacksStock($vp->id, $quantity, 'increase');
                $ledger->recordLedger(
                    vendorProductId: $vp->id,
                    productId:       $productId,
                    packId:          '',
                    quantity:        $quantity,
                    unitType:        (string) ($material['unit_type'] ?? 'Nos'),
                    amount:          0,
                    actionType:      'issue_to_production_reversal',
                    invType:         'CREDIT',
                    source:          'production_issue_reversal',
                    note:            "Issue to Production Reversal #{$issueId} - Product #{$productId}",
                    invDate:         $invDate,
                );
            } else {
                Log::warning('IssueToProduction restoreStock: no vendor_product', ['product_id' => $productId, 'issue_id' => $issueId]);
            }

            DB::statement('UPDATE product SET stock = COALESCE(stock, 0) + ? WHERE product_id = ?', [$quantity, $productId]);
        }
    }

}
