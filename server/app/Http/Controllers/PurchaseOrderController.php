<?php

namespace App\Http\Controllers;

use App\Models\PurchaseOrder;
use App\Models\PurchaseOrderItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class PurchaseOrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = PurchaseOrder::query()->with('supplier:id,supplier_code,supplier_name');

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where('po_number', 'like', "%{$search}%");
            }
            if ($request->filled('supplier_id')) {
                $query->where('supplier_id', $request->input('supplier_id'));
            }
            if ($request->filled('status')) {
                $query->where('status', $request->input('status'));
            }
            if ($request->filled('from_date')) {
                $query->whereDate('doc_date', '>=', $request->input('from_date'));
            }
            if ($request->filled('to_date')) {
                $query->whereDate('doc_date', '<=', $request->input('to_date'));
            }

            $sortField = $request->input('sort', 'created_at');
            $sortOrder = $request->input('order', 'desc');
            if (str_contains($sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', $sortField);
            }
            $query->orderBy($sortField, $sortOrder);

            $limit = (int) $request->input('limit', 20);
            $page = (int) $request->input('page', 1);
            $total = $query->count();
            $list = $query->skip(($page - 1) * $limit)->take($limit)->get();

            return response()->json([
                'success' => true,
                'data' => $list,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'pages' => $limit > 0 ? (int) ceil($total / $limit) : 0,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('PurchaseOrder index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch purchase orders',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $po = PurchaseOrder::with(['supplier', 'items.product'])->findOrFail($id);
            return response()->json([
                'success' => true,
                'data' => $po,
            ]);
        } catch (\Exception $e) {
            Log::error('PurchaseOrder show error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Purchase order not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'financial_year' => 'required|string|max:10',
            'supplier_id' => 'required|integer|exists:suppliers,id',
            'doc_date' => 'required|date',
            'expected_date' => 'nullable|date',
            'status' => 'nullable|in:DRAFT,SENT,PARTIALLY_RECEIVED,CLOSED,CANCELLED',
            'narration' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer|exists:product,product_id',
            'items.*.line_no' => 'required|integer|min:1',
            'items.*.unit' => 'nullable|string|max:20',
            'items.*.quantity' => 'required|numeric|min:0.001',
            'items.*.price' => 'required|numeric|min:0',
            'items.*.discount_percent' => 'nullable|numeric|min:0|max:100',
            'items.*.tax_percent' => 'nullable|numeric|min:0|max:100',
            'items.*.description' => 'nullable|string',
        ]);

        try {
            DB::beginTransaction();

            $poNumber = $this->generatePoNumber($validated['financial_year']);

            $po = PurchaseOrder::create([
                'po_number' => $poNumber,
                'financial_year' => $validated['financial_year'],
                'supplier_id' => $validated['supplier_id'],
                'doc_date' => $validated['doc_date'],
                'expected_date' => $validated['expected_date'] ?? null,
                'status' => $validated['status'] ?? 'DRAFT',
                'narration' => $validated['narration'] ?? null,
                'total_amount' => 0,
            ]);

            $totalAmount = 0;
            foreach ($validated['items'] as $row) {
                $qty = (float) $row['quantity'];
                $price = (float) $row['price'];
                $discountPct = isset($row['discount_percent']) ? (float) $row['discount_percent'] : 0;
                $taxPct = isset($row['tax_percent']) ? (float) $row['tax_percent'] : 0;
                $lineTotal = round($qty * $price * (1 - $discountPct / 100) * (1 + $taxPct / 100), 2);

                PurchaseOrderItem::create([
                    'purchase_order_id' => $po->id,
                    'product_id' => $row['product_id'],
                    'line_no' => (int) $row['line_no'],
                    'unit' => $row['unit'] ?? null,
                    'quantity' => $qty,
                    'price' => $price,
                    'discount_percent' => $discountPct ?: null,
                    'tax_percent' => $taxPct ?: null,
                    'line_total' => $lineTotal,
                    'description' => $row['description'] ?? null,
                ]);
                $totalAmount += $lineTotal;
            }

            $po->update(['total_amount' => round($totalAmount, 2)]);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Purchase order created successfully',
                'data' => $po->load(['supplier', 'items.product']),
            ], 201);
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('PurchaseOrder store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create purchase order: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'financial_year' => 'sometimes|string|max:10',
            'supplier_id' => 'sometimes|integer|exists:suppliers,id',
            'doc_date' => 'sometimes|date',
            'expected_date' => 'nullable|date',
            'status' => 'nullable|in:DRAFT,SENT,PARTIALLY_RECEIVED,CLOSED,CANCELLED',
            'narration' => 'nullable|string',
            'items' => 'sometimes|array|min:1',
            'items.*.product_id' => 'required_with:items|integer|exists:product,product_id',
            'items.*.line_no' => 'required_with:items|integer|min:1',
            'items.*.unit' => 'nullable|string|max:20',
            'items.*.quantity' => 'required_with:items|numeric|min:0.001',
            'items.*.price' => 'required_with:items|numeric|min:0',
            'items.*.discount_percent' => 'nullable|numeric|min:0|max:100',
            'items.*.tax_percent' => 'nullable|numeric|min:0|max:100',
            'items.*.description' => 'nullable|string',
        ]);

        try {
            $po = PurchaseOrder::findOrFail($id);
            if ($po->status !== 'DRAFT') {
                return response()->json([
                    'success' => false,
                    'message' => 'Only draft purchase orders can be updated.',
                ], 422);
            }

            DB::beginTransaction();

            $po->fill(array_filter([
                'financial_year' => $validated['financial_year'] ?? null,
                'supplier_id' => $validated['supplier_id'] ?? null,
                'doc_date' => $validated['doc_date'] ?? null,
                'expected_date' => $validated['expected_date'] ?? null,
                'status' => $validated['status'] ?? null,
                'narration' => array_key_exists('narration', $validated) ? $validated['narration'] : null,
            ], fn ($v) => $v !== null));
            $po->save();

            if (isset($validated['items'])) {
                $po->items()->delete();
                $totalAmount = 0;
                foreach ($validated['items'] as $row) {
                    $qty = (float) $row['quantity'];
                    $price = (float) $row['price'];
                    $discountPct = isset($row['discount_percent']) ? (float) $row['discount_percent'] : 0;
                    $taxPct = isset($row['tax_percent']) ? (float) $row['tax_percent'] : 0;
                    $lineTotal = round($qty * $price * (1 - $discountPct / 100) * (1 + $taxPct / 100), 2);

                    PurchaseOrderItem::create([
                        'purchase_order_id' => $po->id,
                        'product_id' => $row['product_id'],
                        'line_no' => (int) $row['line_no'],
                        'unit' => $row['unit'] ?? null,
                        'quantity' => $qty,
                        'price' => $price,
                        'discount_percent' => $discountPct ?: null,
                        'tax_percent' => $taxPct ?: null,
                        'line_total' => $lineTotal,
                        'description' => $row['description'] ?? null,
                    ]);
                    $totalAmount += $lineTotal;
                }
                $po->update(['total_amount' => round($totalAmount, 2)]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Purchase order updated successfully',
                'data' => $po->load(['supplier', 'items.product']),
            ]);
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('PurchaseOrder update error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update purchase order: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $po = PurchaseOrder::findOrFail($id);
            if ($po->status !== 'DRAFT') {
                $po->update(['status' => 'CANCELLED']);
                return response()->json([
                    'success' => true,
                    'message' => 'Purchase order cancelled',
                ]);
            }
            $po->delete();
            return response()->json([
                'success' => true,
                'message' => 'Purchase order deleted successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('PurchaseOrder destroy error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete purchase order',
            ], 500);
        }
    }

    private function generatePoNumber(string $financialYear): string
    {
        $last = PurchaseOrder::where('financial_year', $financialYear)
            ->orderBy('id', 'desc')
            ->first();
        $seq = 1;
        if ($last && preg_match('/-(\d+)$/', $last->po_number, $m)) {
            $seq = (int) $m[1] + 1;
        }
        return 'PO-' . $financialYear . '-' . str_pad((string) $seq, 4, '0', STR_PAD_LEFT);
    }
}
