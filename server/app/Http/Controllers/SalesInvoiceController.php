<?php

namespace App\Http\Controllers;

use App\Models\SalesInvoice;
use App\Models\SalesInvoiceItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SalesInvoiceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = SalesInvoice::query();

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where(function ($q) use ($search) {
                    $q->where('doc_no', 'like', "%{$search}%")
                      ->orWhere('doc_no_number', 'like', "%{$search}%")
                      ->orWhere('bill_no', 'like', "%{$search}%")
                      ->orWhere('customer_name', 'like', "%{$search}%");
                });
            }

            if ($request->filled('customer_id')) {
                $query->where('customer_id', (int) $request->input('customer_id'));
            }

            if ($request->filled('status')) {
                $query->where('status', strtoupper((string) $request->input('status')));
            }

            if ($request->filled('from_date')) {
                $query->whereDate('doc_date', '>=', $request->input('from_date'));
            }

            if ($request->filled('to_date')) {
                $query->whereDate('doc_date', '<=', $request->input('to_date'));
            }

            $sortField = $request->input('sort', 'created_at');
            $sortOrder = strtolower((string) $request->input('order', 'desc')) === 'asc' ? 'asc' : 'desc';
            if (!in_array($sortField, ['created_at', 'doc_date', 'doc_no_number', 'id'], true)) {
                $sortField = 'created_at';
            }
            $query->orderBy($sortField, $sortOrder);

            $limit = max(1, (int) $request->input('limit', 20));
            $page  = max(1, (int) $request->input('page', 1));
            $total = $query->count();
            $list  = $query->skip(($page - 1) * $limit)->take($limit)->get();

            $data = $list->map(fn (SalesInvoice $inv) => [
                'id'             => $inv->id,
                'doc_no_prefix'  => $inv->doc_no_prefix,
                'doc_no_number'  => (string) $inv->doc_no_number,
                'doc_no'         => $inv->doc_no,
                'customer_id'    => $inv->customer_id,
                'customer_name'  => $inv->customer_name,
                'doc_date'       => optional($inv->doc_date)->format('Y-m-d'),
                'bill_no'        => $inv->bill_no,
                'status'         => $inv->status,
                'net_total'      => (float) $inv->net_total,
                'created_at'     => optional($inv->created_at)->toDateTimeString(),
            ]);

            return response()->json([
                'success'    => true,
                'data'       => $data,
                'pagination' => [
                    'total' => $total,
                    'page'  => $page,
                    'limit' => $limit,
                    'pages' => (int) ceil($total / $limit),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('SalesInvoice index error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to fetch sales invoices'], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $inv = SalesInvoice::with('items')->findOrFail($id);

            return response()->json([
                'success' => true,
                'data' => [
                    'id'                       => $inv->id,
                    'doc_no_prefix'            => $inv->doc_no_prefix,
                    'doc_no_number'            => (string) $inv->doc_no_number,
                    'doc_no'                   => $inv->doc_no,
                    'customer_id'              => $inv->customer_id,
                    'customer_name'            => $inv->customer_name,
                    'doc_date'                 => optional($inv->doc_date)->format('Y-m-d'),
                    'bill_no'                  => $inv->bill_no,
                    'bill_date'                => optional($inv->bill_date)->format('Y-m-d'),
                    'narration'                => $inv->narration,
                    'do_not_update_inventory'  => (bool) $inv->do_not_update_inventory,
                    'sale_type'                => $inv->sale_type,
                    'status'                   => $inv->status,
                    'items_total'              => (float) $inv->items_total,
                    'charges_total'            => (float) $inv->charges_total,
                    'net_total'                => (float) $inv->net_total,
                    'charges_json'             => $inv->charges_json ?? [],
                    'items' => $inv->items->map(fn (SalesInvoiceItem $item) => [
                        'id'                          => $item->id,
                        'source_sales_order_id'       => $item->source_sales_order_id,
                        'source_sales_order_item_id'  => $item->source_sales_order_item_id,
                        'source_so_number'            => $item->source_so_number,
                        'product_id'                  => $item->product_id,
                        'product_name'                => $item->product_name,
                        'product_code'                => $item->product_code,
                        'alias'                       => $item->alias,
                        'unit'                        => $item->unit,
                        'pack_id'                     => $item->pack_id,
                        'pack_label'                  => $item->pack_label,
                        'hsn_code'                    => $item->hsn_code,
                        'line_no'                     => $item->line_no,
                        'quantity'                    => (float) $item->quantity,
                        'ordered_qty'                 => $item->ordered_qty !== null ? (float) $item->ordered_qty : null,
                        'used_qty'                    => $item->used_qty !== null ? (float) $item->used_qty : null,
                        'left_qty'                    => $item->left_qty !== null ? (float) $item->left_qty : null,
                        'overrun_qty'                 => (float) ($item->overrun_qty ?? 0),
                        'writeoff_qty'                => (float) ($item->writeoff_qty ?? 0),
                        'is_overrun_approved'         => (bool) $item->is_overrun_approved,
                        'is_writeoff'                 => (bool) $item->is_writeoff,
                        'overrun_reason'              => $item->overrun_reason,
                        'writeoff_reason'             => $item->writeoff_reason,
                        'unit_price'                  => (float) $item->unit_price,
                        'taxable_amount'              => (float) $item->taxable_amount,
                        'sgst'                        => (float) $item->sgst,
                        'cgst'                        => (float) $item->cgst,
                        'igst'                        => (float) $item->igst,
                        'cess'                        => (float) $item->cess,
                        'roff'                        => (float) $item->roff,
                        'value'                       => (float) $item->value,
                        'sale_account_id'             => $item->sale_account_id,
                        'gst_applicability'           => $item->gst_applicability,
                    ])->values(),
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('SalesInvoice show error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Sales invoice not found'], 404);
        }
    }

    public function series(Request $request): JsonResponse
    {
        try {
            $prefix = (string) $request->input('prefix', '25-26/');
            $max = SalesInvoice::where('doc_no_prefix', $prefix)->max('doc_no_number');
            $next = ($max === null) ? 1 : (int) $max + 1;

            return response()->json([
                'success' => true,
                'data' => [
                    'doc_no_prefix' => $prefix,
                    'doc_no_number' => $next,
                    'doc_no'        => $prefix . $next,
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('SalesInvoice series error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to get series'], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        try {
            DB::beginTransaction();

            $prefix      = (string) ($validated['doc_no_prefix'] ?? '25-26/');
            $docNoNumber = $this->resolveDocNoNumber($validated['doc_no_number'] ?? null, $prefix);
            $docNo       = $prefix . $docNoNumber;

            $chargesData = $validated['charges_json'] ?? $validated['charges'] ?? [];
            [$itemsTotal, $chargesTotal, $netTotal] = $this->computeTotals(
                $validated['items'] ?? [],
                $chargesData
            );

            $inv = SalesInvoice::create([
                'doc_no_prefix'           => $prefix,
                'doc_no_number'           => $docNoNumber,
                'doc_no'                  => $docNo,
                'customer_id'             => $validated['customer_id'] ?? null,
                'customer_name'           => $validated['customer_name'] ?? null,
                'doc_date'                => $validated['doc_date'],
                'bill_no'                 => $validated['bill_no'] ?? null,
                'bill_date'               => $validated['bill_date'] ?? null,
                'narration'               => $validated['narration'] ?? null,
                'do_not_update_inventory' => (bool) ($validated['do_not_update_inventory'] ?? false),
                'sale_type'               => $validated['sale_type'] ?? null,
                'status'                  => strtoupper((string) ($validated['status'] ?? 'DRAFT')),
                'items_total'             => $itemsTotal,
                'charges_total'           => $chargesTotal,
                'net_total'               => $netTotal,
                'charges_json'            => $chargesData,
            ]);

            $this->replaceItems($inv, $validated['items'] ?? []);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Sales invoice created successfully',
                'data'    => ['id' => $inv->id, 'doc_no' => $inv->doc_no, 'status' => $inv->status],
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('SalesInvoice store error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to create sales invoice: ' . $e->getMessage()], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $this->validatePayload($request, true);

        try {
            $inv = SalesInvoice::findOrFail($id);

            DB::beginTransaction();

            $chargesData = $validated['charges_json'] ?? $validated['charges'] ?? $inv->charges_json ?? [];
            [$itemsTotal, $chargesTotal, $netTotal] = $this->computeTotals(
                $validated['items'] ?? [],
                $chargesData
            );

            $inv->update([
                'customer_id'             => $validated['customer_id'] ?? $inv->customer_id,
                'customer_name'           => $validated['customer_name'] ?? $inv->customer_name,
                'doc_date'                => $validated['doc_date'] ?? $inv->doc_date,
                'bill_no'                 => $validated['bill_no'] ?? $inv->bill_no,
                'bill_date'               => $validated['bill_date'] ?? $inv->bill_date,
                'narration'               => $validated['narration'] ?? $inv->narration,
                'do_not_update_inventory' => isset($validated['do_not_update_inventory'])
                    ? (bool) $validated['do_not_update_inventory']
                    : $inv->do_not_update_inventory,
                'sale_type'               => $validated['sale_type'] ?? $inv->sale_type,
                'status'                  => isset($validated['status'])
                    ? strtoupper((string) $validated['status'])
                    : $inv->status,
                'items_total'             => $itemsTotal,
                'charges_total'           => $chargesTotal,
                'net_total'               => $netTotal,
                'charges_json'            => $chargesData,
            ]);

            $this->replaceItems($inv, $validated['items'] ?? []);

            DB::commit();

            return response()->json([
                'success' => true,
                'message' => 'Sales invoice updated successfully',
                'data'    => ['id' => $inv->id, 'doc_no' => $inv->doc_no, 'status' => $inv->status],
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('SalesInvoice update error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to update sales invoice: ' . $e->getMessage()], 500);
        }
    }

    private function validatePayload(Request $request, bool $isUpdate = false): array
    {
        $rules = [
            'customer_id'              => 'nullable|integer',
            'customer_name'            => 'nullable|string|max:255',
            'doc_date'                 => ($isUpdate ? 'nullable' : 'required') . '|date',
            'bill_no'                  => 'nullable|string|max:100',
            'bill_date'                => 'nullable|date',
            'narration'                => 'nullable|string',
            'do_not_update_inventory'  => 'nullable|boolean',
            'sale_type'                => 'nullable|string|max:50',
            'status'                   => 'nullable|string|in:DRAFT,POSTED,CANCELLED',
            'doc_no_prefix'            => 'nullable|string|max:20',
            'doc_no_number'            => 'nullable|integer|min:1',
            'charges_json'             => 'nullable|array',
            'charges_json.*.name'      => 'nullable|string|max:255',
            'charges_json.*.amount'    => 'nullable|numeric',
            'charges'                  => 'nullable|array',
            'charges.*.name'           => 'nullable|string|max:255',
            'charges.*.amount'         => 'nullable|numeric',
            'items'                    => 'nullable|array',
            'items.*.product_id'       => 'nullable|integer',
            'items.*.product_name'     => 'nullable|string|max:255',
            'items.*.quantity'         => 'nullable|numeric|min:0',
            'items.*.unit_price'       => 'nullable|numeric|min:0',
        ];

        return $request->validate($rules);
    }

    private function resolveDocNoNumber(?int $requested, string $prefix = '25-26/'): int
    {
        if ($requested !== null && $requested > 0) {
            $conflict = SalesInvoice::where('doc_no_prefix', $prefix)
                ->where('doc_no_number', $requested)
                ->exists();
            if (!$conflict) {
                return $requested;
            }
        }

        $max = SalesInvoice::where('doc_no_prefix', $prefix)->max('doc_no_number');
        return ($max === null) ? 1 : (int) $max + 1;
    }

    private function replaceItems(SalesInvoice $inv, array $items): void
    {
        $inv->items()->delete();

        $lineNo = 1;
        foreach ($items as $item) {
            if (empty($item['product_id']) && empty($item['product_name'])) {
                continue;
            }

            $qty         = (float) ($item['quantity'] ?? 0);
            $unitPrice   = (float) ($item['unit_price'] ?? 0);
            $taxable     = (float) ($item['taxable_amount'] ?? ($qty * $unitPrice));
            $sgst        = (float) ($item['sgst'] ?? 0);
            $cgst        = (float) ($item['cgst'] ?? 0);
            $igst        = (float) ($item['igst'] ?? 0);
            $cess        = (float) ($item['cess'] ?? 0);
            $roff        = (float) ($item['roff'] ?? 0);
            $value       = (float) ($item['value'] ?? ($taxable + $sgst + $cgst + $igst + $cess + $roff));

            SalesInvoiceItem::create([
                'sales_invoice_id'            => $inv->id,
                'source_sales_order_id'       => $item['source_sales_order_id'] ?? null,
                'source_sales_order_item_id'  => $item['source_sales_order_item_id'] ?? null,
                'source_so_number'            => $item['source_so_number'] ?? null,
                'product_id'                  => $item['product_id'] ?? null,
                'product_name'                => $item['product_name'] ?? null,
                'product_code'                => $item['product_code'] ?? null,
                'alias'                       => $item['alias'] ?? null,
                'unit'                        => $item['unit'] ?? null,
                'pack_id'                     => $item['pack_id'] ?? null,
                'pack_label'                  => $item['pack_label'] ?? null,
                'hsn_code'                    => $item['hsn_code'] ?? null,
                'line_no'                     => $lineNo++,
                'quantity'                    => $qty,
                'ordered_qty'                 => $item['ordered_qty'] ?? null,
                'used_qty'                    => $item['used_qty'] ?? null,
                'left_qty'                    => $item['left_qty'] ?? null,
                'overrun_qty'                 => (float) ($item['overrun_qty'] ?? 0),
                'writeoff_qty'                => (float) ($item['writeoff_qty'] ?? 0),
                'is_overrun_approved'         => (bool) ($item['is_overrun_approved'] ?? false),
                'is_writeoff'                 => (bool) ($item['is_writeoff'] ?? false),
                'overrun_reason'              => $item['overrun_reason'] ?? null,
                'writeoff_reason'             => $item['writeoff_reason'] ?? null,
                'unit_price'                  => $unitPrice,
                'taxable_amount'              => $taxable,
                'sgst'                        => $sgst,
                'cgst'                        => $cgst,
                'igst'                        => $igst,
                'cess'                        => $cess,
                'roff'                        => $roff,
                'value'                       => $value,
                'sale_account_id'             => $item['sale_account_id'] ?? null,
                'gst_applicability'           => $item['gst_applicability'] ?? null,
            ]);
        }
    }

    private function computeTotals(array $items, array $charges): array
    {
        $itemsTotal = 0.0;
        foreach ($items as $item) {
            $itemsTotal += (float) ($item['value'] ?? 0);
        }

        $chargesTotal = 0.0;
        foreach ($charges as $charge) {
            $amt  = (float) ($charge['amount'] ?? $charge['calculated_amount'] ?? 0);
            $name = strtolower((string) ($charge['name'] ?? ''));
            $chargesTotal += str_contains($name, 'discount') ? -$amt : $amt;
        }

        return [round($itemsTotal, 2), round($chargesTotal, 2), round($itemsTotal + $chargesTotal, 2)];
    }
}
