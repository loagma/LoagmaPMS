<?php

namespace App\Http\Controllers;

use App\Models\PurchaseVoucher;
use App\Models\PurchaseVoucherItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class PurchaseVoucherController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = PurchaseVoucher::query()->with('vendor:id,supplier_code,supplier_name');

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where(function ($q) use ($search) {
                    $q->where('doc_no', 'like', "%{$search}%")
                        ->orWhere('doc_no_number', 'like', "%{$search}%")
                        ->orWhere('bill_no', 'like', "%{$search}%")
                        ->orWhereHas('vendor', function ($sq) use ($search) {
                            $sq->where('supplier_name', 'like', "%{$search}%")
                                ->orWhere('supplier_code', 'like', "%{$search}%");
                        });
                });
            }

            if ($request->filled('vendor_id')) {
                $query->where('vendor_id', (int) $request->input('vendor_id'));
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
            if (str_contains((string) $sortField, ':')) {
                [$sortField, $sortOrder] = explode(':', (string) $sortField);
            }
            if (!in_array($sortField, ['created_at', 'doc_date', 'doc_no_number', 'id'], true)) {
                $sortField = 'created_at';
            }
            $sortOrder = strtolower((string) $sortOrder) === 'asc' ? 'asc' : 'desc';

            $query->orderBy((string) $sortField, $sortOrder);

            $limit = max(1, (int) $request->input('limit', 20));
            $page = max(1, (int) $request->input('page', 1));
            $total = $query->count();
            $list = $query->skip(($page - 1) * $limit)->take($limit)->get();

            $data = $list->map(function (PurchaseVoucher $voucher) {
                return [
                    'id' => $voucher->id,
                    'doc_no_prefix' => $voucher->doc_no_prefix,
                    'doc_no_number' => (string) $voucher->doc_no_number,
                    'doc_no' => $voucher->doc_no,
                    'vendor_id' => $voucher->vendor_id,
                    'vendor_name' => $voucher->vendor_name,
                    'supplier_name' => $voucher->supplier_name,
                    'doc_date' => optional($voucher->doc_date)->format('Y-m-d'),
                    'bill_no' => $voucher->bill_no,
                    'status' => $voucher->status,
                    'net_total' => (float) $voucher->net_total,
                    'created_at' => optional($voucher->created_at)->toDateTimeString(),
                    'updated_at' => optional($voucher->updated_at)->toDateTimeString(),
                ];
            });

            return response()->json([
                'success' => true,
                'data' => $data,
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'pages' => (int) ceil($total / $limit),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('PurchaseVoucher index error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch purchase vouchers',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $voucher = PurchaseVoucher::with(['vendor', 'items.product'])->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => [
                    'voucher' => [
                        'id' => $voucher->id,
                        'doc_no_prefix' => $voucher->doc_no_prefix,
                        'doc_no_number' => (string) $voucher->doc_no_number,
                        'doc_no' => $voucher->doc_no,
                        'vendor_id' => $voucher->vendor_id,
                        'vendor_name' => $voucher->vendor_name,
                        'supplier_name' => $voucher->supplier_name,
                        'doc_date' => optional($voucher->doc_date)->format('Y-m-d'),
                        'bill_no' => $voucher->bill_no,
                        'bill_date' => optional($voucher->bill_date)->format('Y-m-d'),
                        'narration' => $voucher->narration,
                        'do_not_update_inventory' => (bool) $voucher->do_not_update_inventory,
                        'purchase_type' => $voucher->purchase_type,
                        'gst_reverse_charge' => $voucher->gst_reverse_charge,
                        'purchase_agent_id' => $voucher->purchase_agent_id,
                        'status' => $voucher->status,
                        'items_total' => (float) $voucher->items_total,
                        'charges_total' => (float) $voucher->charges_total,
                        'net_total' => (float) $voucher->net_total,
                    ],
                    'items' => $voucher->items->map(function (PurchaseVoucherItem $item) {
                        return [
                            'id' => $item->id,
                            'product_id' => $item->product_id,
                            'product_name' => $item->product_name,
                            'product_code' => $item->product_code,
                            'alias' => $item->alias,
                            'unit' => $item->unit,
                            'quantity' => (float) $item->quantity,
                            'unit_price' => (float) $item->unit_price,
                            'taxable_amount' => (float) $item->taxable_amount,
                            'sgst' => (float) $item->sgst,
                            'cgst' => (float) $item->cgst,
                            'igst' => (float) $item->igst,
                            'cess' => (float) $item->cess,
                            'roff' => (float) $item->roff,
                            'value' => (float) $item->value,
                            'purchase_account' => $item->purchase_account,
                            'gst_itc_eligibility' => $item->gst_itc_eligibility,
                        ];
                    })->values(),
                    'charges' => collect($voucher->charges_json ?? [])->map(function ($ch) {
                        return [
                            'name' => $ch['name'] ?? 'Others',
                            'amount' => isset($ch['amount']) ? (float) $ch['amount'] : 0,
                            'calculated_amount' => isset($ch['calculated_amount']) ? (float) $ch['calculated_amount'] : 0,
                            'remarks' => $ch['remarks'] ?? '',
                        ];
                    })->values(),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('PurchaseVoucher show error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Purchase voucher not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request, false);

        try {
            DB::beginTransaction();

            $docNoNumber = $this->resolveDocNoNumber($validated['doc_no_number'] ?? null);
            $docNoPrefix = (string) ($validated['doc_no_prefix'] ?? '25-26/');
            $docNo = $docNoPrefix . $docNoNumber;

            [$itemsTotal, $chargesTotal, $netTotal] = $this->computeTotals(
                $validated['items'],
                $validated['charges'] ?? []
            );

            $voucher = PurchaseVoucher::create([
                'doc_no_prefix' => $docNoPrefix,
                'doc_no_number' => $docNoNumber,
                'doc_no' => $docNo,
                'vendor_id' => (int) ($validated['vendor_id'] ?? $validated['supplier_id']),
                'purchase_order_id' => $validated['purchase_order_id'] ?? null,
                'doc_date' => $validated['doc_date'],
                'bill_no' => $validated['bill_no'],
                'bill_date' => $validated['bill_date'] ?? null,
                'narration' => $validated['narration'] ?? null,
                'do_not_update_inventory' => (bool) ($validated['do_not_update_inventory'] ?? false),
                'purchase_type' => $validated['purchase_type'] ?? 'Regular',
                'gst_reverse_charge' => $validated['gst_reverse_charge'] ?? 'N',
                'purchase_agent_id' => $validated['purchase_agent_id'] ?? null,
                'status' => $validated['status'] ?? 'DRAFT',
                'items_total' => $itemsTotal,
                'charges_total' => $chargesTotal,
                'net_total' => $netTotal,
                'charges_json' => $validated['charges'] ?? [],
            ]);

            $this->replaceItems($voucher, $validated['items']);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Purchase voucher created successfully',
                'data' => [
                    'id' => $voucher->id,
                    'doc_no' => $voucher->doc_no,
                    'status' => $voucher->status,
                ],
            ], 201);
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('PurchaseVoucher store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to create purchase voucher: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $this->validatePayload($request, true);

        try {
            $voucher = PurchaseVoucher::findOrFail($id);

            DB::beginTransaction();

            $docNoNumber = $this->resolveDocNoNumber(
                $validated['doc_no_number'] ?? $voucher->doc_no_number,
                $voucher->id
            );
            $docNoPrefix = (string) ($validated['doc_no_prefix'] ?? $voucher->doc_no_prefix ?? '25-26/');
            $docNo = $docNoPrefix . $docNoNumber;

            $items = $validated['items'] ?? $voucher->items()->get()->map(function (PurchaseVoucherItem $i) {
                return [
                    'product_id' => $i->product_id,
                    'product_name' => $i->product_name,
                    'product_code' => $i->product_code,
                    'alias' => $i->alias,
                    'unit' => $i->unit,
                    'quantity' => $i->quantity,
                    'unit_price' => $i->unit_price,
                    'taxable_amount' => $i->taxable_amount,
                    'sgst' => $i->sgst,
                    'cgst' => $i->cgst,
                    'igst' => $i->igst,
                    'cess' => $i->cess,
                    'roff' => $i->roff,
                    'value' => $i->value,
                    'purchase_account' => $i->purchase_account,
                    'gst_itc_eligibility' => $i->gst_itc_eligibility,
                ];
            })->toArray();

            $charges = $validated['charges'] ?? ($voucher->charges_json ?? []);

            [$itemsTotal, $chargesTotal, $netTotal] = $this->computeTotals($items, $charges);

            $voucher->fill([
                'doc_no_prefix' => $docNoPrefix,
                'doc_no_number' => $docNoNumber,
                'doc_no' => $docNo,
                'vendor_id' => (int) ($validated['vendor_id'] ?? $validated['supplier_id'] ?? $voucher->vendor_id),
                'purchase_order_id' => $validated['purchase_order_id'] ?? $voucher->purchase_order_id,
                'doc_date' => $validated['doc_date'] ?? optional($voucher->doc_date)->format('Y-m-d'),
                'bill_no' => $validated['bill_no'] ?? $voucher->bill_no,
                'bill_date' => $validated['bill_date'] ?? optional($voucher->bill_date)->format('Y-m-d'),
                'narration' => array_key_exists('narration', $validated) ? $validated['narration'] : $voucher->narration,
                'do_not_update_inventory' => (bool) ($validated['do_not_update_inventory'] ?? $voucher->do_not_update_inventory),
                'purchase_type' => $validated['purchase_type'] ?? $voucher->purchase_type,
                'gst_reverse_charge' => $validated['gst_reverse_charge'] ?? $voucher->gst_reverse_charge,
                'purchase_agent_id' => array_key_exists('purchase_agent_id', $validated)
                    ? $validated['purchase_agent_id']
                    : $voucher->purchase_agent_id,
                'status' => $validated['status'] ?? $voucher->status,
                'items_total' => $itemsTotal,
                'charges_total' => $chargesTotal,
                'net_total' => $netTotal,
                'charges_json' => $charges,
            ]);
            $voucher->save();

            if (array_key_exists('items', $validated)) {
                $this->replaceItems($voucher, $validated['items']);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Purchase voucher updated successfully',
                'data' => [
                    'id' => $voucher->id,
                    'doc_no' => $voucher->doc_no,
                    'status' => $voucher->status,
                ],
            ]);
        } catch (ValidationException $e) {
            throw $e;
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('PurchaseVoucher update error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Failed to update purchase voucher: ' . $e->getMessage(),
            ], 500);
        }
    }

    private function replaceItems(PurchaseVoucher $voucher, array $items): void
    {
        $voucher->items()->delete();

        foreach ($items as $index => $row) {
            PurchaseVoucherItem::create([
                'purchase_voucher_id' => $voucher->id,
                'product_id' => (int) $row['product_id'],
                'line_no' => (int) ($row['line_no'] ?? ($index + 1)),
                'product_name' => $row['product_name'] ?? null,
                'product_code' => $row['product_code'] ?? null,
                'alias' => $row['alias'] ?? null,
                'unit' => $row['unit'] ?? null,
                'quantity' => (float) ($row['quantity'] ?? 0),
                'unit_price' => (float) ($row['unit_price'] ?? 0),
                'taxable_amount' => (float) ($row['taxable_amount'] ?? 0),
                'sgst' => (float) ($row['sgst'] ?? 0),
                'cgst' => (float) ($row['cgst'] ?? 0),
                'igst' => (float) ($row['igst'] ?? 0),
                'cess' => (float) ($row['cess'] ?? 0),
                'roff' => (float) ($row['roff'] ?? 0),
                'value' => (float) ($row['value'] ?? 0),
                'purchase_account' => $row['purchase_account'] ?? null,
                'gst_itc_eligibility' => $row['gst_itc_eligibility'] ?? null,
            ]);
        }
    }

    private function computeTotals(array $items, array $charges): array
    {
        $itemsTotal = 0.0;
        foreach ($items as $row) {
            $itemsTotal += (float) ($row['value'] ?? 0);
        }

        $chargesTotal = 0.0;
        foreach ($charges as $charge) {
            $chargesTotal += (float) ($charge['calculated_amount'] ?? $charge['amount'] ?? 0);
        }

        $net = round($itemsTotal + $chargesTotal, 2);
        return [round($itemsTotal, 2), round($chargesTotal, 2), $net];
    }

    private function resolveDocNoNumber($requested, ?int $ignoreId = null): int
    {
        $candidate = is_null($requested) ? null : (int) $requested;

        if ($candidate && $candidate > 0) {
            $exists = PurchaseVoucher::query()
                ->when($ignoreId, fn ($q) => $q->where('id', '!=', $ignoreId))
                ->where('doc_no_number', $candidate)
                ->exists();
            if (!$exists) {
                return $candidate;
            }
        }

        $max = PurchaseVoucher::query()
            ->when($ignoreId, fn ($q) => $q->where('id', '!=', $ignoreId))
            ->max('doc_no_number');
        return ((int) $max) + 1;
    }

    private function validatePayload(Request $request, bool $isUpdate): array
    {
        $itemRules = $isUpdate ? 'sometimes|array|min:1' : 'required|array|min:1';
        $vendorRule = $isUpdate
            ? 'sometimes|integer|exists:suppliers,id'
            : 'required_without:supplier_id|integer|exists:suppliers,id';
        $supplierRule = $isUpdate
            ? 'sometimes|integer|exists:suppliers,id'
            : 'required_without:vendor_id|integer|exists:suppliers,id';

        return $request->validate([
            'doc_no_prefix' => 'nullable|string|max:20',
            'doc_no_number' => 'nullable|integer|min:1',
            'purchase_order_id' => 'nullable|integer|exists:purchase_orders,id',
            'vendor_id' => $vendorRule,
            'supplier_id' => $supplierRule,
            'doc_date' => $isUpdate ? 'sometimes|date' : 'required|date',
            'bill_no' => $isUpdate ? 'sometimes|string|max:100' : 'required|string|max:100',
            'bill_date' => 'nullable|date',
            'narration' => 'nullable|string',
            'do_not_update_inventory' => 'nullable|boolean',
            'purchase_type' => 'nullable|string|max:50',
            'gst_reverse_charge' => 'nullable|string|max:4',
            'purchase_agent_id' => 'nullable|string|max:100',
            'status' => 'nullable|in:DRAFT,POSTED,CANCELLED',

            'items' => $itemRules,
            'items.*.product_id' => 'required_with:items|integer|exists:product,product_id',
            'items.*.product_name' => 'nullable|string|max:255',
            'items.*.product_code' => 'nullable|string|max:100',
            'items.*.alias' => 'nullable|string|max:255',
            'items.*.unit' => 'nullable|string|max:20',
            'items.*.quantity' => 'required_with:items|numeric|min:0.001',
            'items.*.unit_price' => 'required_with:items|numeric|min:0',
            'items.*.taxable_amount' => 'nullable|numeric|min:0',
            'items.*.sgst' => 'nullable|numeric|min:0',
            'items.*.cgst' => 'nullable|numeric|min:0',
            'items.*.igst' => 'nullable|numeric|min:0',
            'items.*.cess' => 'nullable|numeric|min:0',
            'items.*.roff' => 'nullable|numeric|min:0',
            'items.*.value' => 'nullable|numeric|min:0',
            'items.*.purchase_account' => 'nullable|string|max:255',
            'items.*.gst_itc_eligibility' => 'nullable|string|max:255',
            'items.*.line_no' => 'nullable|integer|min:1',

            'charges' => 'nullable|array',
            'charges.*.name' => 'nullable|string|max:100',
            'charges.*.amount' => 'nullable|numeric',
            'charges.*.calculated_amount' => 'nullable|numeric',
            'charges.*.remarks' => 'nullable|string|max:255',
        ], [
            'vendor_id.exists' => 'Selected vendor does not exist',
            'supplier_id.exists' => 'Selected vendor does not exist',
        ]);
    }
}
