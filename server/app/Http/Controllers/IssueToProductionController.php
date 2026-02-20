<?php

namespace App\Http\Controllers;

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
                $this->reduceStock($request->materials);
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
                $this->restoreStock($existingItems);
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
                $this->reduceStock($request->materials);
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

    /**
     * Reduce product stock for each material.
     * Reduces stock from vendor_products packs (all packages simultaneously)
     * and also updates the product table stock.
     *
     * @param array $materials Array of ['raw_material_id' => int, 'quantity' => float]
     * @throws \RuntimeException if any product has insufficient stock at update time
     */
    private function reduceStock(array $materials): void
    {
        foreach ($materials as $material) {
            $productId = (int) $material['raw_material_id'];
            $quantity = (float) $material['quantity'];
            
            // First, reduce stock from vendor_products packs
            $this->reduceVendorProductStock($productId, $quantity);
            
            // Then, reduce stock from product table (only if stock exists)
            $product = DB::table('product')->where('product_id', $productId)->first();
            $currentStock = $product && $product->stock !== null ? (float) $product->stock : 0;
            
            if ($currentStock > 0) {
                // Only reduce if there's stock in product table
                $reduceAmount = min($quantity, $currentStock);
                DB::update(
                    'UPDATE product SET stock = COALESCE(stock, 0) - ? WHERE product_id = ?',
                    [$reduceAmount, $productId]
                );
                
                Log::info('Product table stock reduced', [
                    'product_id' => $productId,
                    'reduced_amount' => $reduceAmount,
                    'original_stock' => $currentStock
                ]);
            } else {
                Log::info('Product table has no stock, only vendor_products stock reduced', [
                    'product_id' => $productId,
                    'quantity' => $quantity
                ]);
            }
        }
    }

    /**
     * Reduce stock from all vendor_products packs for a given product_id
     * 
     * @param int $productId
     * @param float $quantityToReduce
     * @throws \RuntimeException if stock reduction fails
     */
    private function reduceVendorProductStock(int $productId, float $quantityToReduce): void
    {
        // Get all vendor_products for this product_id
        $vendorProducts = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->get();

        if ($vendorProducts->isEmpty()) {
            Log::info('No vendor products found for product', ['product_id' => $productId]);
            return;
        }

        foreach ($vendorProducts as $vendorProduct) {
            try {
                // Parse packs JSON
                $packsData = json_decode($vendorProduct->packs, true);
                if (!is_array($packsData) || empty($packsData)) {
                    Log::warning('Invalid or empty packs JSON', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId
                    ]);
                    continue;
                }

                // Get the default pack or first pack
                $defaultPackId = $vendorProduct->default_pack_id;
                $packToUpdate = null;

                // Find the default pack or use first available pack
                foreach ($packsData as $packId => $packData) {
                    if ($packId === $defaultPackId) {
                        $packToUpdate = $packId;
                        break;
                    }
                    if ($packToUpdate === null) {
                        $packToUpdate = $packId;
                    }
                }

                if ($packToUpdate === null) {
                    Log::warning('No pack found to update', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId
                    ]);
                    continue;
                }

                // Calculate total available stock in base units
                $totalStock = 0;
                foreach ($packsData as $packData) {
                    if (isset($packData['stk'])) {
                        $totalStock += (float) $packData['stk'];
                    }
                }

                // Check if sufficient stock is available
                if ($totalStock < $quantityToReduce) {
                    Log::warning('Insufficient vendor product stock', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId,
                        'available' => $totalStock,
                        'required' => $quantityToReduce
                    ]);
                    continue;
                }

                // Use StockManagerService to reduce stock (negative value for reduction)
                $result = $this->stockManager->updatePackStock(
                    $vendorProduct->id,
                    $packToUpdate,
                    -$quantityToReduce,
                    'Issue to Production'
                );

                if (!$result->success) {
                    Log::error('Failed to reduce vendor product stock', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId,
                        'pack_id' => $packToUpdate,
                        'quantity' => $quantityToReduce,
                        'error' => $result->message
                    ]);
                    throw new \RuntimeException(
                        "Failed to reduce vendor product stock: {$result->message}"
                    );
                }

                Log::info('Vendor product stock reduced successfully', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'pack_id' => $packToUpdate,
                    'quantity_reduced' => $quantityToReduce
                ]);

            } catch (\Exception $e) {
                Log::error('Error reducing vendor product stock', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                // Continue with other vendor products instead of failing completely
            }
        }
    }

    /**
     * Restore product stock for each material (reverse of reduceStock).
     * Restores stock to vendor_products packs and product table.
     *
     * @param array $materials Array of ['raw_material_id' => int, 'quantity' => float]
     */
    private function restoreStock(array $materials): void
    {
        foreach ($materials as $material) {
            $productId = (int) $material['raw_material_id'];
            $quantity = (float) $material['quantity'];
            
            // First, restore stock to vendor_products packs
            $this->restoreVendorProductStock($productId, $quantity);
            
            // Then, restore stock to product table
            DB::statement(
                'UPDATE product SET stock = COALESCE(stock, 0) + ? WHERE product_id = ?',
                [$quantity, $productId]
            );
        }
    }

    /**
     * Restore stock to all vendor_products packs for a given product_id
     * 
     * @param int $productId
     * @param float $quantityToRestore
     */
    private function restoreVendorProductStock(int $productId, float $quantityToRestore): void
    {
        // Get all vendor_products for this product_id
        $vendorProducts = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->get();

        if ($vendorProducts->isEmpty()) {
            Log::info('No vendor products found for product restoration', ['product_id' => $productId]);
            return;
        }

        foreach ($vendorProducts as $vendorProduct) {
            try {
                // Parse packs JSON
                $packsData = json_decode($vendorProduct->packs, true);
                if (!is_array($packsData) || empty($packsData)) {
                    Log::warning('Invalid or empty packs JSON for restoration', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId
                    ]);
                    continue;
                }

                // Get the default pack or first pack
                $defaultPackId = $vendorProduct->default_pack_id;
                $packToUpdate = null;

                // Find the default pack or use first available pack
                foreach ($packsData as $packId => $packData) {
                    if ($packId === $defaultPackId) {
                        $packToUpdate = $packId;
                        break;
                    }
                    if ($packToUpdate === null) {
                        $packToUpdate = $packId;
                    }
                }

                if ($packToUpdate === null) {
                    Log::warning('No pack found to restore', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId
                    ]);
                    continue;
                }

                // Use StockManagerService to restore stock (positive value for increase)
                $result = $this->stockManager->updatePackStock(
                    $vendorProduct->id,
                    $packToUpdate,
                    $quantityToRestore,
                    'Restore from Issue to Production (Edit/Cancel)'
                );

                if (!$result->success) {
                    Log::error('Failed to restore vendor product stock', [
                        'vendor_product_id' => $vendorProduct->id,
                        'product_id' => $productId,
                        'pack_id' => $packToUpdate,
                        'quantity' => $quantityToRestore,
                        'error' => $result->message
                    ]);
                }

                Log::info('Vendor product stock restored successfully', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'pack_id' => $packToUpdate,
                    'quantity_restored' => $quantityToRestore
                ]);

            } catch (\Exception $e) {
                Log::error('Error restoring vendor product stock', [
                    'vendor_product_id' => $vendorProduct->id,
                    'product_id' => $productId,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                // Continue with other vendor products
            }
        }
    }
}
