<?php

namespace App\Http\Controllers;

use App\Services\InventoryLedgerService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SalesReturnController extends Controller
{
    private const ORDERS_TABLE = 'loagma_new.orders';
    private const ITEMS_TABLE  = 'loagma_new.orders_item';

    // Dynamic FY prefix: SR/25-26/ before April, SR/26-27/ from April onwards
    private function voucherPrefix(): string
    {
        $year  = (int) date('Y');
        $month = (int) date('m');
        $fyStart = $month >= 4 ? $year : $year - 1;
        $fyEnd   = $fyStart + 1;
        return 'SR/' . substr((string) $fyStart, 2) . '-' . substr((string) $fyEnd, 2) . '/';
    }

    // GET /sales-returns/series
    public function series(): JsonResponse
    {
        try {
            $prefix = $this->voucherPrefix();

            $lastNo = DB::table(self::ORDERS_TABLE)
                ->whereNotNull('Sales_Return_VoucherNo')
                ->where('Sales_Return_VoucherNo', 'like', $prefix . '%')
                ->count();

            $nextNum = str_pad((string) ($lastNo + 1), 3, '0', STR_PAD_LEFT);

            return response()->json([
                'success'       => true,
                'doc_no_prefix' => $prefix,
                'next_number'   => $nextNum,
                'full_number'   => $prefix . $nextNum,
                // Nested shape expected by Flutter form controller
                'data' => [
                    'prefix' => $prefix,
                    'number' => $nextNum,
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('SalesReturn series error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to get return series'], 500);
        }
    }

    // GET /sales-returns
    // Lists orders that have a return voucher recorded
    public function index(Request $request): JsonResponse
    {
        try {
            $limit = max(1, min((int) $request->input('limit', 20), 200));
            $page  = max(1, (int) $request->input('page', 1));

            $query = DB::table(self::ORDERS_TABLE . ' as o')
                ->leftJoin('loagma_new.user as u', 'u.userid', '=', 'o.buyer_userid')
                ->whereNotNull('o.Sales_Return_VoucherNo');

            if ($request->filled('customer_id')) {
                $query->where('o.buyer_userid', (int) $request->input('customer_id'));
            }

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('o.Sales_Return_VoucherNo', 'like', "%{$search}%")
                      ->orWhere('u.name', 'like', "%{$search}%")
                      ->orWhere('o.order_id', 'like', "%{$search}%");
                });
            }

            if ($request->filled('from_date')) {
                $query->where('o.Sales_Return_Dt', '>=', $request->input('from_date'));
            }

            if ($request->filled('to_date')) {
                $query->where('o.Sales_Return_Dt', '<=', $request->input('to_date'));
            }

            // Filter by status maps to order_state
            if ($request->filled('status')) {
                $query->where('o.order_state', $request->input('status'));
            }

            $query->orderBy('o.Sales_Return_Dt', 'desc')->orderBy('o.order_id', 'desc');

            $total = $query->count();
            $rows  = $query
                ->select([
                    'o.order_id',
                    'o.buyer_userid',
                    'u.name as buyer_name',
                    'o.Sales_Return_VoucherNo',
                    'o.Sales_Return_Dt',
                    'o.Sales_Return_Reason',
                    'o.order_state',
                ])
                ->offset(($page - 1) * $limit)
                ->limit($limit)
                ->get();

            return response()->json([
                'success' => true,
                'data'    => $rows->map(fn ($row) => $this->normalizeSummary($row))->values(),
                'pagination' => [
                    'total' => $total,
                    'page'  => $page,
                    'limit' => $limit,
                    'pages' => (int) ceil($total / $limit),
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('SalesReturn index error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to fetch sales returns'], 500);
        }
    }

    // GET /sales-returns/{id}  — id is order_id
    public function show(int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE . ' as o')
                ->leftJoin('loagma_new.user as u', 'u.userid', '=', 'o.buyer_userid')
                ->where('o.order_id', $id)
                ->select(['o.*', 'u.name as buyer_name'])
                ->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }

            $items = DB::table(self::ITEMS_TABLE . ' as oi')
                ->leftJoin('product as p', 'p.product_id', '=', 'oi.product_id')
                ->where('oi.order_id', $id)
                ->select([
                    'oi.item_id',
                    'oi.product_id',
                    'oi.pinfo',
                    'oi.quantity',
                    'oi.item_price',
                    'oi.qty_delivered',
                    'oi.qty_returned',
                    'p.name as db_product_name',
                    'p.hsn_code as db_product_code',
                ])
                ->get();

            $header = $this->normalizeHeader($order);
            $header['items'] = $items->map(fn ($item) => $this->normalizeItem($item))->values()->toArray();

            return response()->json(['success' => true, 'data' => $header]);
        } catch (\Throwable $e) {
            Log::error('SalesReturn show error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Sales return not found'], 404);
        }
    }

    // POST /sales-returns
    public function store(Request $request): JsonResponse
    {
        try {
            $sourceOrderId = (int) (
                $request->input('source_order_id')
                ?? $request->input('source_sales_invoice_id')
                ?? 0
            );

            if ($sourceOrderId <= 0) {
                return response()->json(['success' => false, 'message' => 'source_order_id is required'], 422);
            }

            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $sourceOrderId)->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Source order not found'], 404);
            }

            if (!empty($order->Sales_Return_VoucherNo)) {
                return response()->json([
                    'success' => false,
                    'message' => 'A return already exists for this order: ' . $order->Sales_Return_VoucherNo . '. Use PUT to update it.',
                ], 422);
            }

            $items = $request->input('items', []);
            if (empty($items)) {
                return response()->json(['success' => false, 'message' => 'At least one item is required'], 422);
            }

            $docDate  = trim((string) $request->input('doc_date', date('Y-m-d')));
            $reason   = trim((string) $request->input('reason', ''));
            $status   = strtoupper(trim((string) $request->input('status', 'DRAFT')));
            $status   = in_array($status, ['DRAFT', 'POSTED', 'CANCELLED']) ? $status : 'DRAFT';

            $voucherNo = $this->generateVoucherNo();

            DB::transaction(function () use ($sourceOrderId, $voucherNo, $docDate, $reason, $status, $items) {
                DB::table(self::ORDERS_TABLE)->where('order_id', $sourceOrderId)->update([
                    'Sales_Return_VoucherNo' => $voucherNo,
                    'Sales_Return_Dt'        => $docDate,
                    'Sales_Return_Reason'    => $reason ?: null,
                    'order_state'            => $status,
                ]);

                foreach ($items as $item) {
                    $orderItemId = (int) (
                        $item['source_sales_invoice_item_id']
                        ?? $item['order_item_id']
                        ?? $item['item_id']
                        ?? 0
                    );
                    $returnedQty = (float) ($item['returned_quantity'] ?? $item['return_qty'] ?? 0);

                    if ($orderItemId > 0 && $returnedQty > 0) {
                        DB::update(
                            'UPDATE ' . self::ITEMS_TABLE . ' SET qty_returned = COALESCE(qty_returned, 0) + ? WHERE item_id = ? AND order_id = ?',
                            [$returnedQty, $orderItemId, $sourceOrderId]
                        );
                    }
                }
            });

            // Inventory: increase packs stock + CREDIT ledger for each returned item
            $ledger = app(InventoryLedgerService::class);
            foreach ($items as $srItem) {
                try {
                    $orderItemId = (int) ($srItem['source_sales_invoice_item_id'] ?? $srItem['order_item_id'] ?? $srItem['item_id'] ?? 0);
                    $returnedQty = (float) ($srItem['returned_quantity'] ?? $srItem['return_qty'] ?? 0);
                    if ($orderItemId <= 0 || $returnedQty <= 0) continue;

                    $origItem = DB::table(self::ITEMS_TABLE)
                        ->where('item_id', $orderItemId)
                        ->where('order_id', $sourceOrderId)
                        ->first();
                    if (!$origItem) continue;

                    $pinfo   = json_decode((string) ($origItem->pinfo ?? '{}'), true) ?: [];
                    $packId  = (string) ($pinfo['selected_pack']['id'] ?? '');
                    if ($packId === '') Log::warning('SalesReturn store: missing pack_id in pinfo', ['item_id' => $orderItemId]);

                    $vp = $ledger->resolveVendorProduct((int) $origItem->product_id, null);
                    if (!$vp) { Log::warning('SalesReturn store: no vendor_product', ['product_id' => $origItem->product_id, 'order_id' => $sourceOrderId]); continue; }

                    $ledger->updatePacksStock($vp->id, $returnedQty, 'increase');

                    $productName = $pinfo['product_name'] ?? $pinfo['name'] ?? "Product #{$origItem->product_id}";
                    $ledger->recordLedger(
                        vendorProductId: $vp->id,
                        productId:       (int) $origItem->product_id,
                        packId:          $packId,
                        quantity:        $returnedQty,
                        unitType:        (string) ($pinfo['unit'] ?? 'Nos'),
                        amount:          $returnedQty * (float) ($origItem->item_price ?? 0),
                        actionType:      'sale_return',
                        invType:         'CREDIT',
                        source:          'sales_return',
                        note:            "Sales Return Order #{$sourceOrderId} - {$productName}",
                        invDate:         $docDate,
                    );
                } catch (\Throwable $ie) {
                    Log::warning('SalesReturn store: inventory failed', ['item' => $srItem, 'order_id' => $sourceOrderId, 'error' => $ie->getMessage()]);
                }
            }

            return $this->show($sourceOrderId);
        } catch (\Throwable $e) {
            Log::error('SalesReturn store error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to create sales return'], 500);
        }
    }

    // PUT /sales-returns/{id}  — id is order_id
    public function update(Request $request, int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order || empty($order->Sales_Return_VoucherNo)) {
                return response()->json(['success' => false, 'message' => 'Sales return not found'], 404);
            }

            $docDate = trim((string) $request->input('doc_date', $order->Sales_Return_Dt));
            $reason  = trim((string) $request->input('reason', $order->Sales_Return_Reason ?? ''));
            $items   = $request->input('items', []);
            $rawStatus = strtoupper(trim((string) $request->input('status', $order->order_state ?? 'DRAFT')));
            $status  = in_array($rawStatus, ['DRAFT', 'POSTED', 'CANCELLED']) ? $rawStatus : ($order->order_state ?? 'DRAFT');

            // Capture old qty_returned per item_id before transaction resets them
            $oldQtyReturned = DB::table(self::ITEMS_TABLE)
                ->where('order_id', $id)
                ->pluck('qty_returned', 'item_id')
                ->map(fn ($v) => (float) $v)
                ->toArray();

            DB::transaction(function () use ($id, $docDate, $reason, $status, $items) {
                if (!empty($items)) {
                    // Reset all items to 0 then set each to the exact value supplied (PUT semantics)
                    DB::table(self::ITEMS_TABLE)->where('order_id', $id)->update(['qty_returned' => 0]);

                    foreach ($items as $item) {
                        $orderItemId = (int) (
                            $item['source_sales_invoice_item_id']
                            ?? $item['order_item_id']
                            ?? $item['item_id']
                            ?? 0
                        );
                        $returnedQty = (float) ($item['returned_quantity'] ?? $item['return_qty'] ?? 0);

                        if ($orderItemId > 0 && $returnedQty >= 0) {
                            DB::table(self::ITEMS_TABLE)
                                ->where('item_id', $orderItemId)
                                ->where('order_id', $id)
                                ->update(['qty_returned' => $returnedQty]);
                        }
                    }
                }

                DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                    'Sales_Return_Dt'     => $docDate,
                    'Sales_Return_Reason' => $reason ?: null,
                    'order_state'         => $status,
                ]);
            });

            // Inventory: apply delta (new qty − old qty) per item
            if (!empty($items)) {
                $ledger = app(InventoryLedgerService::class);
                foreach ($items as $srItem) {
                    try {
                        $orderItemId = (int) ($srItem['source_sales_invoice_item_id'] ?? $srItem['order_item_id'] ?? $srItem['item_id'] ?? 0);
                        $newQty      = (float) ($srItem['returned_quantity'] ?? $srItem['return_qty'] ?? 0);
                        $oldQty      = $oldQtyReturned[$orderItemId] ?? 0.0;
                        $delta       = $newQty - $oldQty;
                        if (abs($delta) < 0.001) continue;

                        $origItem = DB::table(self::ITEMS_TABLE)
                            ->where('item_id', $orderItemId)
                            ->where('order_id', $id)
                            ->first();
                        if (!$origItem) continue;

                        $pinfo  = json_decode((string) ($origItem->pinfo ?? '{}'), true) ?: [];
                        $packId = (string) ($pinfo['selected_pack']['id'] ?? '');
                        if ($packId === '') Log::warning('SalesReturn update: missing pack_id in pinfo', ['item_id' => $orderItemId]);

                        $vp = $ledger->resolveVendorProduct((int) $origItem->product_id, null);
                        if (!$vp) { Log::warning('SalesReturn update: no vendor_product', ['product_id' => $origItem->product_id, 'order_id' => $id]); continue; }

                        if ($delta > 0) {
                            $ledger->updatePacksStock($vp->id, $delta, 'increase');
                            $productName = $pinfo['product_name'] ?? $pinfo['name'] ?? "Product #{$origItem->product_id}";
                            $ledger->recordLedger(
                                vendorProductId: $vp->id,
                                productId:       (int) $origItem->product_id,
                                packId:          $packId,
                                quantity:        $delta,
                                unitType:        (string) ($pinfo['unit'] ?? 'Nos'),
                                amount:          $delta * (float) ($origItem->item_price ?? 0),
                                actionType:      'sale_return',
                                invType:         'CREDIT',
                                source:          'sales_return',
                                note:            "Sales Return Order #{$id} - {$productName}",
                                invDate:         $docDate,
                            );
                        } else {
                            $ledger->updatePacksStock($vp->id, abs($delta), 'decrease');
                        }
                    } catch (\Throwable $ie) {
                        Log::warning('SalesReturn update: inventory failed', ['item' => $srItem, 'order_id' => $id, 'error' => $ie->getMessage()]);
                    }
                }
            }

            return $this->show($id);
        } catch (\Throwable $e) {
            Log::error('SalesReturn update error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to update sales return'], 500);
        }
    }

    // DELETE /sales-returns/{id}  — id is order_id
    public function destroy(int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order || empty($order->Sales_Return_VoucherNo)) {
                return response()->json(['success' => false, 'message' => 'Sales return not found'], 404);
            }

            DB::transaction(function () use ($id) {
                DB::table(self::ITEMS_TABLE)->where('order_id', $id)->update(['qty_returned' => 0]);

                DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                    'Sales_Return_VoucherNo' => null,
                    'Sales_Return_Dt'        => null,
                    'Sales_Return_Reason'    => null,
                    'order_state'            => 'billed',
                ]);
            });

            return response()->json(['success' => true, 'message' => 'Sales return deleted']);
        } catch (\Throwable $e) {
            Log::error('SalesReturn destroy error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to delete sales return'], 500);
        }
    }

    private function generateVoucherNo(): string
    {
        $prefix  = $this->voucherPrefix();
        $count   = DB::table(self::ORDERS_TABLE)
            ->whereNotNull('Sales_Return_VoucherNo')
            ->where('Sales_Return_VoucherNo', 'like', $prefix . '%')
            ->count();
        $nextNum = str_pad((string) ($count + 1), 3, '0', STR_PAD_LEFT);
        return $prefix . $nextNum;
    }

    private function normalizeSummary(object $row): array
    {
        $total = (float) (DB::table(self::ITEMS_TABLE)
            ->where('order_id', $row->order_id)
            ->selectRaw('SUM(COALESCE(qty_returned, 0) * item_price) as total')
            ->value('total') ?? 0);

        return [
            'id'            => (int) ($row->order_id ?? 0),
            'voucher_no'    => $row->Sales_Return_VoucherNo ?? null,
            'doc_number'    => $row->Sales_Return_VoucherNo ?? null,
            'return_dt'     => $row->Sales_Return_Dt ?? null,
            'doc_date'      => $row->Sales_Return_Dt ?? null,
            'customer_id'   => (int) ($row->buyer_userid ?? 0),
            'customer_name' => $row->buyer_name ?? null,
            'reason'        => $row->Sales_Return_Reason ?? null,
            'status'        => $row->order_state ?? 'DRAFT',
            'total_value'   => $total,
        ];
    }

    private function normalizeHeader(object $order): array
    {
        return [
            'id'                      => (int) ($order->order_id ?? 0),
            'voucher_no'              => $order->Sales_Return_VoucherNo ?? null,
            'doc_number'              => $order->Sales_Return_VoucherNo ?? null,
            'doc_no_prefix'           => $this->voucherPrefix(),
            'doc_no_number'           => $order->Sales_Return_VoucherNo ?? '',
            'return_dt'               => $order->Sales_Return_Dt ?? null,
            'doc_date'                => $order->Sales_Return_Dt ?? null,
            'source_order_id'         => (int) ($order->order_id ?? 0),
            'source_sales_invoice_id' => (int) ($order->order_id ?? 0),
            'source_si_number'        => $order->bill_no ?? ('ORD-' . ($order->order_id ?? 0)),
            'customer_id'             => (int) ($order->buyer_userid ?? 0),
            'customer_name'           => $order->buyer_name ?? null,
            'reason'                  => $order->Sales_Return_Reason ?? null,
            'status'                  => $order->order_state ?? 'DRAFT',
        ];
    }

    private function normalizeItem(object $item): array
    {
        $pinfo        = json_decode($item->pinfo ?? '{}', true) ?: [];
        $qtyDelivered = (float) ($item->qty_delivered ?? 0);
        $qtyReturned  = (float) ($item->qty_returned ?? 0);
        $availableQty = max(0, $qtyDelivered - $qtyReturned);

        // pinfo is the primary source; fall back to products table join
        $productName = $pinfo['product_name'] ?? $pinfo['name'] ?? $item->db_product_name ?? null;
        $productCode = $pinfo['product_code'] ?? $pinfo['code'] ?? $pinfo['hsn_code'] ?? $item->db_product_code ?? null;
        $unit        = $pinfo['unit'] ?? 'Nos';

        return [
            'order_item_id'                => (int) ($item->item_id ?? 0),
            'source_sales_invoice_item_id' => (int) ($item->item_id ?? 0),
            'product_id'                   => (int) ($item->product_id ?? 0),
            'product_name'                 => $productName,
            'product_code'                 => $productCode,
            'unit'                         => $unit,
            'original_quantity'            => (float) ($item->quantity ?? 0),
            'available_quantity'           => $availableQty,
            'returned_qty'                 => $qtyReturned,
            'returned_quantity'            => $qtyReturned,
            'unit_price'                   => (float) ($item->item_price ?? 0),
        ];
    }
}
