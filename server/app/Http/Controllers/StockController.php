<?php

namespace App\Http\Controllers;

use App\Services\StockManagerService;
use App\Exceptions\VendorProductNotFoundException;
use App\Exceptions\JsonParseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class StockController extends Controller
{
    private StockManagerService $stockManager;

    public function __construct(StockManagerService $stockManager)
    {
        $this->stockManager = $stockManager;
    }

    /**
     * Update stock for a specific package
     * 
     * POST /api/vendor-products/{id}/packs/{packId}/stock
     * 
     * @param Request $request
     * @param int $id Vendor product ID
     * @param string $packId Pack ID
     * @return JsonResponse
     */
    public function updatePackStock(Request $request, int $id, string $packId): JsonResponse
    {
        // Validate request
        $validator = Validator::make($request->all(), [
            'stock_change' => 'required|numeric',
            'reason' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        $stockChange = (float) $request->input('stock_change');
        $reason = $request->input('reason');

        // Call StockManagerService
        $result = $this->stockManager->updatePackStock($id, $packId, $stockChange, $reason);

        if (!$result->success) {
            Log::warning('Stock update failed', [
                'vendor_product_id' => $id,
                'pack_id' => $packId,
                'errors' => $result->errors
            ]);

            return response()->json([
                'success' => false,
                'message' => $result->message,
                'errors' => $result->errors,
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => $result->message,
            'data' => [
                'pack_updates' => array_map(fn($update) => $update->toArray(), $result->packUpdates),
            ],
        ], 200);
    }

    /**
     * Process an inventory transaction
     * 
     * POST /api/inventory-transactions
     * 
     * @param Request $request
     * @return JsonResponse
     */
    public function processInventoryTransaction(Request $request): JsonResponse
    {
        // Validate request
        $validator = Validator::make($request->all(), [
            'vendor_product_id' => 'required|integer',
            'pack_id' => 'required|string',
            'quantity' => 'required|numeric',
            'action_type' => 'required|string|in:purchase,sale,return,damage,adjustment_increase,adjustment_decrease,adjustment',
            'notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            throw new ValidationException($validator);
        }

        // Build transaction data
        $transactionData = [
            'vendor_product_id' => (int) $request->input('vendor_product_id'),
            'pack_id' => $request->input('pack_id'),
            'quantity' => (float) $request->input('quantity'),
            'action_type' => $request->input('action_type'),
        ];

        if ($request->has('notes')) {
            $transactionData['notes'] = $request->input('notes');
        }

        // Call StockManagerService
        $result = $this->stockManager->processInventoryTransaction($transactionData);

        if (!$result->success) {
            Log::warning('Inventory transaction processing failed', [
                'transaction_data' => $transactionData,
                'errors' => $result->errors
            ]);

            return response()->json([
                'success' => false,
                'message' => $result->message,
                'errors' => $result->errors,
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => $result->message,
            'data' => [
                'pack_updates' => array_map(fn($update) => $update->toArray(), $result->packUpdates),
            ],
        ], 200);
    }

    /**
     * Validate stock consistency for a vendor product
     * 
     * GET /api/vendor-products/{id}/stock-consistency
     * 
     * @param int $id Vendor product ID
     * @return JsonResponse
     */
    public function validateStockConsistency(int $id): JsonResponse
    {
        // Call StockManagerService
        $result = $this->stockManager->validateStockConsistency($id);

        return response()->json([
            'success' => true,
            'data' => [
                'is_consistent' => $result->isConsistent,
                'inconsistencies' => $result->inconsistencies,
                'reference_base_units' => $result->referenceBaseUnits,
            ],
        ], 200);
    }
}
