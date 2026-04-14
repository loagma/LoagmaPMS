<?php

namespace App\Http\Controllers;

use App\Models\PurchaseReturn;
use App\Models\PurchaseReturnItem;
use App\Models\PurchaseVoucher;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class PurchaseReturnController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $search = trim((string) $request->query('search', ''));
        $status = trim((string) $request->query('status', ''));

        $query = PurchaseReturn::query()
            ->with(['vendor:id,supplier_name,supplier_code'])
            ->withCount('items')
            ->orderByDesc('doc_date')
            ->orderByDesc('id');

        if ($search !== '') {
            $like = '%' . $search . '%';
            $query->where(function ($q) use ($like): void {
                $q->where('doc_no', 'like', $like)
                    ->orWhereHas('vendor', function ($vq) use ($like): void {
                        $vq->where('supplier_name', 'like', $like)
                            ->orWhere('supplier_code', 'like', $like);
                    });
            });
        }

        if ($status !== '') {
            $query->where('status', $status);
        }

        $paginator = $query->paginate((int) $request->query('per_page', 25));

        $rows = collect($paginator->items())->map(function (PurchaseReturn $row): array {
            return [
                'id' => $row->id,
                'doc_no' => $row->doc_no,
                'doc_date' => optional($row->doc_date)->format('Y-m-d'),
                'status' => $row->status,
                'vendor_id' => $row->vendor_id,
                'vendor_name' => $row->vendor?->supplier_name,
                'source_purchase_voucher_id' => $row->source_purchase_voucher_id,
                'items_total' => (float) $row->items_total,
                'charges_total' => (float) $row->charges_total,
                'net_total' => (float) $row->net_total,
                'items_count' => (int) $row->items_count,
                'updated_at' => optional($row->updated_at)->toISOString(),
            ];
        })->values()->all();

        return response()->json([
            'success' => true,
            'data' => [
                'data' => $rows,
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
            ],
        ]);
    }

    public function series(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'vendor_id' => ['required', 'integer', 'exists:suppliers,id'],
            'doc_no_prefix' => ['nullable', 'string', 'max:20'],
        ]);

        $series = $this->resolveDocumentSeries(
            (int) $validated['vendor_id'],
            $validated['doc_no_prefix'] ?? null
        );

        return response()->json([
            'success' => true,
            'data' => $series,
        ]);
    }

    public function show(PurchaseReturn $purchaseReturn): JsonResponse
    {
        $purchaseReturn->load([
            'vendor:id,supplier_name,supplier_code',
            'sourcePurchaseVoucher:id,doc_no',
            'items.sourcePurchaseVoucherItem:id,purchase_voucher_id,quantity',
        ]);

        $items = $purchaseReturn->items->map(function (PurchaseReturnItem $item) use ($purchaseReturn): array {
            $alreadyReturnedExcludingThis = $this->getAlreadyReturnedQuantity(
                (int) ($item->source_purchase_voucher_item_id ?? 0),
                $purchaseReturn->id
            );
            $remaining = max(0.0, (float) $item->original_quantity - $alreadyReturnedExcludingThis);

            return [
                'id' => $item->id,
                'source_purchase_voucher_item_id' => $item->source_purchase_voucher_item_id,
                'product_id' => $item->product_id,
                'line_no' => $item->line_no,
                'product_name' => $item->product_name,
                'product_code' => $item->product_code,
                'alias' => $item->alias,
                'unit' => $item->unit,
                'original_quantity' => (float) $item->original_quantity,
                'returned_quantity' => (float) $item->returned_quantity,
                'available_quantity' => $remaining,
                'unit_price' => (float) $item->unit_price,
                'taxable_amount' => (float) $item->taxable_amount,
                'sgst' => (float) $item->sgst,
                'cgst' => (float) $item->cgst,
                'igst' => (float) $item->igst,
                'cess' => (float) $item->cess,
                'roff' => (float) $item->roff,
                'value' => (float) $item->value,
                'return_reason' => $item->return_reason,
                'remarks' => $item->remarks,
            ];
        })->values()->all();

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $purchaseReturn->id,
                'doc_no_prefix' => $purchaseReturn->doc_no_prefix,
                'doc_no_number' => $purchaseReturn->doc_no_number,
                'doc_no' => $purchaseReturn->doc_no,
                'doc_date' => optional($purchaseReturn->doc_date)->format('Y-m-d'),
                'status' => $purchaseReturn->status,
                'vendor_id' => $purchaseReturn->vendor_id,
                'vendor_name' => $purchaseReturn->vendor?->supplier_name,
                'source_purchase_voucher_id' => $purchaseReturn->source_purchase_voucher_id,
                'source_purchase_voucher_no' => $purchaseReturn->sourcePurchaseVoucher?->doc_no,
                'reason' => $purchaseReturn->reason,
                'items_total' => (float) $purchaseReturn->items_total,
                'charges_total' => (float) $purchaseReturn->charges_total,
                'net_total' => (float) $purchaseReturn->net_total,
                'charges' => $purchaseReturn->charges_json ?? [],
                'items' => $items,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $header = $this->extractHeader($validated);
        $items = $validated['items'];

        $sourceVoucher = PurchaseVoucher::query()
            ->with('items')
            ->findOrFail($header['source_purchase_voucher_id']);

        if ((int) $sourceVoucher->vendor_id !== (int) $header['vendor_id']) {
            throw ValidationException::withMessages([
                'header.vendor_id' => 'Vendor must match the selected source purchase voucher.',
            ]);
        }

        $computedItems = $this->normalizeAndValidateItems(
            $items,
            (int) $sourceVoucher->id,
            null
        );

        $totals = $this->computeTotals($computedItems, $validated['charges'] ?? []);
        $series = $this->resolveDocumentSeries(
            (int) $header['vendor_id'],
            $header['doc_no_prefix'] ?? null
        );

        $created = DB::transaction(function () use ($header, $computedItems, $totals, $series, $validated): PurchaseReturn {
            $purchaseReturn = PurchaseReturn::query()->create([
                'doc_no_prefix' => $series['prefix'],
                'doc_no_number' => $series['number'],
                'doc_no' => $series['doc_no'],
                'source_purchase_voucher_id' => $header['source_purchase_voucher_id'],
                'vendor_id' => $header['vendor_id'],
                'doc_date' => $header['doc_date'],
                'reason' => $header['reason'] ?? null,
                'status' => $header['status'] ?? 'DRAFT',
                'items_total' => $totals['items_total'],
                'charges_total' => $totals['charges_total'],
                'net_total' => $totals['net_total'],
                'charges_json' => $validated['charges'] ?? [],
                'created_by' => optional(auth()->user())->id,
                'updated_by' => optional(auth()->user())->id,
            ]);

            foreach ($computedItems as $line) {
                $purchaseReturn->items()->create($line);
            }

            return $purchaseReturn;
        });

        return response()->json([
            'success' => true,
            'message' => 'Purchase return created successfully.',
            'data' => ['id' => $created->id],
        ], 201);
    }

    public function update(Request $request, PurchaseReturn $purchaseReturn): JsonResponse
    {
        $validated = $this->validatePayload($request);
        $header = $this->extractHeader($validated);
        $items = $validated['items'];

        $sourceVoucher = PurchaseVoucher::query()
            ->with('items')
            ->findOrFail($header['source_purchase_voucher_id']);

        if ((int) $sourceVoucher->vendor_id !== (int) $header['vendor_id']) {
            throw ValidationException::withMessages([
                'header.vendor_id' => 'Vendor must match the selected source purchase voucher.',
            ]);
        }

        $computedItems = $this->normalizeAndValidateItems(
            $items,
            (int) $sourceVoucher->id,
            (int) $purchaseReturn->id
        );

        $totals = $this->computeTotals($computedItems, $validated['charges'] ?? []);

        DB::transaction(function () use ($purchaseReturn, $header, $computedItems, $totals, $validated): void {
            $purchaseReturn->update([
                'source_purchase_voucher_id' => $header['source_purchase_voucher_id'],
                'vendor_id' => $header['vendor_id'],
                'doc_date' => $header['doc_date'],
                'reason' => $header['reason'] ?? null,
                'status' => $header['status'] ?? $purchaseReturn->status,
                'items_total' => $totals['items_total'],
                'charges_total' => $totals['charges_total'],
                'net_total' => $totals['net_total'],
                'charges_json' => $validated['charges'] ?? [],
                'updated_by' => optional(auth()->user())->id,
            ]);

            $purchaseReturn->items()->delete();
            foreach ($computedItems as $line) {
                $purchaseReturn->items()->create($line);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Purchase return updated successfully.',
            'data' => ['id' => $purchaseReturn->id],
        ]);
    }

    public function destroy(PurchaseReturn $purchaseReturn): JsonResponse
    {
        DB::transaction(function () use ($purchaseReturn): void {
            $purchaseReturn->items()->delete();
            $purchaseReturn->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Purchase return deleted successfully.',
        ]);
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'header' => ['sometimes', 'array'],
            'header.doc_no_prefix' => ['nullable', 'string', 'max:20'],
            'header.source_purchase_voucher_id' => ['required_with:header', 'integer', 'exists:purchase_vouchers,id'],
            'header.vendor_id' => ['required_with:header', 'integer', 'exists:suppliers,id'],
            'header.doc_date' => ['required_with:header', 'date'],
            'header.reason' => ['nullable', 'string'],
            'header.status' => ['nullable', 'in:DRAFT,POSTED,CANCELLED'],

            'doc_no_prefix' => ['nullable', 'string', 'max:20'],
            'source_purchase_voucher_id' => ['required_without:header', 'integer', 'exists:purchase_vouchers,id'],
            'vendor_id' => ['required_without:header', 'integer', 'exists:suppliers,id'],
            'doc_date' => ['required_without:header', 'date'],
            'reason' => ['nullable', 'string'],
            'status' => ['nullable', 'in:DRAFT,POSTED,CANCELLED'],

            'items' => ['required', 'array', 'min:1'],
            'items.*.source_purchase_voucher_item_id' => ['required', 'integer', 'exists:purchase_voucher_items,id'],
            'items.*.product_id' => ['required', 'integer', 'exists:product,product_id'],
            'items.*.returned_quantity' => ['required', 'numeric', 'gt:0'],
            'items.*.unit_price' => ['nullable', 'numeric', 'min:0'],
            'items.*.taxable_amount' => ['nullable', 'numeric'],
            'items.*.sgst' => ['nullable', 'numeric'],
            'items.*.cgst' => ['nullable', 'numeric'],
            'items.*.igst' => ['nullable', 'numeric'],
            'items.*.cess' => ['nullable', 'numeric'],
            'items.*.roff' => ['nullable', 'numeric'],
            'items.*.value' => ['nullable', 'numeric'],
            'items.*.return_reason' => ['nullable', 'string', 'max:255'],
            'items.*.remarks' => ['nullable', 'string', 'max:255'],

            'charges' => ['nullable', 'array'],
            'charges.*.amount' => ['nullable', 'numeric'],
        ]);
    }

    private function extractHeader(array $validated): array
    {
        if (!empty($validated['header']) && is_array($validated['header'])) {
            return $validated['header'];
        }

        return [
            'doc_no_prefix' => $validated['doc_no_prefix'] ?? null,
            'source_purchase_voucher_id' => $validated['source_purchase_voucher_id'] ?? null,
            'vendor_id' => $validated['vendor_id'] ?? null,
            'doc_date' => $validated['doc_date'] ?? null,
            'reason' => $validated['reason'] ?? null,
            'status' => $validated['status'] ?? null,
        ];
    }

    private function resolveDocumentSeries(int $vendorId, ?string $preferredPrefix = null): array
    {
        $prefix = trim((string) ($preferredPrefix ?? ''));
        if ($prefix === '') {
            $year = Carbon::now()->format('y');
            $nextYear = Carbon::now()->addYear()->format('y');
            $prefix = $year . '-' . $nextYear . '/';
        }

        $number = ((int) PurchaseReturn::query()
            ->where('vendor_id', $vendorId)
            ->where('doc_no_prefix', $prefix)
            ->orderByDesc('doc_no_number')
            ->lockForUpdate()
            ->value('doc_no_number')) + 1;

        return [
            'prefix' => $prefix,
            'number' => $number,
            'doc_no' => $prefix . $number,
        ];
    }

    private function computeTotals(array $items, array $charges): array
    {
        $itemsTotal = 0.0;
        foreach ($items as $item) {
            $itemsTotal += (float) ($item['value'] ?? 0);
        }

        $chargesTotal = 0.0;
        foreach ($charges as $charge) {
            $chargesTotal += (float) ($charge['amount'] ?? 0);
        }

        return [
            'items_total' => round($itemsTotal, 2),
            'charges_total' => round($chargesTotal, 2),
            'net_total' => round($itemsTotal + $chargesTotal, 2),
        ];
    }

    private function normalizeAndValidateItems(array $payloadItems, int $sourceVoucherId, ?int $ignoreReturnId): array
    {
        $sourceItems = DB::table('purchase_voucher_items')
            ->where('purchase_voucher_id', $sourceVoucherId)
            ->get()
            ->keyBy('id');

        $normalized = [];
        foreach ($payloadItems as $index => $row) {
            $srcItemId = (int) $row['source_purchase_voucher_item_id'];
            $srcItem = $sourceItems->get($srcItemId);

            if (!$srcItem) {
                throw ValidationException::withMessages([
                    "items.$index.source_purchase_voucher_item_id" => 'Item does not belong to selected source purchase voucher.',
                ]);
            }

            $returnedQty = round((float) ($row['returned_quantity'] ?? 0), 3);
            if ($returnedQty <= 0) {
                throw ValidationException::withMessages([
                    "items.$index.returned_quantity" => 'Returned quantity must be greater than zero.',
                ]);
            }

            $alreadyReturned = $this->getAlreadyReturnedQuantity($srcItemId, $ignoreReturnId);
            $originalQty = round((float) ($srcItem->quantity ?? 0), 3);
            $availableQty = round(max(0.0, $originalQty - $alreadyReturned), 3);

            if ($returnedQty > $availableQty) {
                throw ValidationException::withMessages([
                    "items.$index.returned_quantity" => "Returned quantity {$returnedQty} exceeds available quantity {$availableQty}.",
                ]);
            }

            $unitPrice = (float) ($row['unit_price'] ?? $srcItem->cost_price ?? 0);
            $value = (float) ($row['value'] ?? round($returnedQty * $unitPrice, 2));

            $normalized[] = [
                'source_purchase_voucher_item_id' => $srcItemId,
                'product_id' => (int) $row['product_id'],
                'line_no' => $index + 1,
                'product_name' => $row['product_name'] ?? $srcItem->product_name,
                'product_code' => $row['product_code'] ?? $srcItem->product_code,
                'alias' => $row['alias'] ?? $srcItem->alias,
                'unit' => $row['unit'] ?? $srcItem->unit,
                'original_quantity' => $originalQty,
                'returned_quantity' => $returnedQty,
                'unit_price' => round($unitPrice, 2),
                'taxable_amount' => round((float) ($row['taxable_amount'] ?? $srcItem->taxable_amount ?? 0), 2),
                'sgst' => round((float) ($row['sgst'] ?? 0), 2),
                'cgst' => round((float) ($row['cgst'] ?? 0), 2),
                'igst' => round((float) ($row['igst'] ?? 0), 2),
                'cess' => round((float) ($row['cess'] ?? 0), 2),
                'roff' => round((float) ($row['roff'] ?? 0), 2),
                'value' => round($value, 2),
                'return_reason' => $row['return_reason'] ?? null,
                'remarks' => $row['remarks'] ?? null,
            ];
        }

        return $normalized;
    }

    private function getAlreadyReturnedQuantity(int $sourcePurchaseVoucherItemId, ?int $ignoreReturnId = null): float
    {
        if ($sourcePurchaseVoucherItemId <= 0) {
            return 0.0;
        }

        $query = DB::table('purchase_return_items as pri')
            ->join('purchase_returns as pr', 'pr.id', '=', 'pri.purchase_return_id')
            ->where('pri.source_purchase_voucher_item_id', $sourcePurchaseVoucherItemId)
            ->whereIn('pr.status', ['DRAFT', 'POSTED']);

        if ($ignoreReturnId) {
            $query->where('pr.id', '!=', $ignoreReturnId);
        }

        return (float) ($query->sum('pri.returned_quantity') ?? 0);
    }
}
