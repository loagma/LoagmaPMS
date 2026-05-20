<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SalesReturnController extends Controller
{
    private const ORDERS_TABLE = 'loagma_new.orders';
    private const ITEMS_TABLE  = 'loagma_new.orders_item';

    private const VOUCHER_PREFIX = 'SR/25-26/';

    // GET /sales-returns/series
    public function series(): JsonResponse
    {
        try {
            // Next number based on existing return vouchers on orders
            $lastNo = DB::table(self::ORDERS_TABLE)
                ->whereNotNull('Sales_Return_VoucherNo')
                ->count();

            $nextNum = str_pad((string) ($lastNo + 1), 3, '0', STR_PAD_LEFT);

            return response()->json([
                'success'       => true,
                'doc_no_prefix' => self::VOUCHER_PREFIX,
                'next_number'   => $nextNum,
                'full_number'   => self::VOUCHER_PREFIX . $nextNum,
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
                ->whereNotNull('o.Sales_Return_VoucherNo');

            if ($request->filled('customer_id')) {
                $query->where('o.buyer_userid', (int) $request->input('customer_id'));
            }

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('o.Sales_Return_VoucherNo', 'like', "%{$search}%")
                      ->orWhere('o.buyer_name', 'like', "%{$search}%")
                      ->orWhere('o.order_id', 'like', "%{$search}%");
                });
            }

            if ($request->filled('from_date')) {
                $query->where('o.Sales_Return_Dt', '>=', $request->input('from_date'));
            }

            if ($request->filled('to_date')) {
                $query->where('o.Sales_Return_Dt', '<=', $request->input('to_date'));
            }

            $query->orderBy('o.Sales_Return_Dt', 'desc')->orderBy('o.order_id', 'desc');

            $total = $query->count();
            $rows  = $query
                ->select([
                    'o.order_id',
                    'o.buyer_userid',
                    'o.buyer_name',
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
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }

            $items = DB::table(self::ITEMS_TABLE . ' as oi')
                ->where('oi.order_id', $id)
                ->select([
                    'oi.item_id',
                    'oi.product_id',
                    'oi.pinfo',
                    'oi.quantity',
                    'oi.item_price',
                    'oi.qty_delivered',
                    'oi.qty_returned',
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

            $items = $request->input('items', []);
            if (empty($items)) {
                return response()->json(['success' => false, 'message' => 'At least one item is required'], 422);
            }

            $docDate  = trim((string) $request->input('doc_date', date('Y-m-d')));
            $reason   = trim((string) $request->input('reason', ''));

            $voucherNo = $this->generateVoucherNo();

            // Write return header onto the order row
            DB::table(self::ORDERS_TABLE)->where('order_id', $sourceOrderId)->update([
                'Sales_Return_VoucherNo' => $voucherNo,
                'Sales_Return_Dt'        => $docDate,
                'Sales_Return_Reason'    => $reason ?: null,
            ]);

            // Update qty_returned per item
            foreach ($items as $item) {
                $orderItemId = (int) (
                    $item['source_sales_invoice_item_id']
                    ?? $item['order_item_id']
                    ?? $item['item_id']
                    ?? 0
                );
                $returnedQty = (float) ($item['returned_quantity'] ?? $item['return_qty'] ?? 0);

                if ($orderItemId > 0 && $returnedQty > 0) {
                    DB::table(self::ITEMS_TABLE)
                        ->where('item_id', $orderItemId)
                        ->where('order_id', $sourceOrderId)
                        ->update([
                            'qty_returned' => DB::raw("COALESCE(qty_returned, 0) + {$returnedQty}"),
                        ]);
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

            if (!empty($items)) {
                // Reverse existing qty_returned for all items of this order
                $oldItems = DB::table(self::ITEMS_TABLE)->where('order_id', $id)->get();
                foreach ($oldItems as $old) {
                    DB::table(self::ITEMS_TABLE)
                        ->where('item_id', $old->item_id)
                        ->update([
                            'qty_returned' => DB::raw("GREATEST(0, COALESCE(qty_returned, 0) - COALESCE({$old->qty_returned}, 0))"),
                        ]);
                }

                // Re-apply from new payload
                foreach ($items as $item) {
                    $orderItemId = (int) (
                        $item['source_sales_invoice_item_id']
                        ?? $item['order_item_id']
                        ?? $item['item_id']
                        ?? 0
                    );
                    $returnedQty = (float) ($item['returned_quantity'] ?? $item['return_qty'] ?? 0);

                    if ($orderItemId > 0 && $returnedQty > 0) {
                        DB::table(self::ITEMS_TABLE)
                            ->where('item_id', $orderItemId)
                            ->where('order_id', $id)
                            ->update([
                                'qty_returned' => DB::raw("COALESCE(qty_returned, 0) + {$returnedQty}"),
                            ]);
                    }
                }
            }

            DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                'Sales_Return_Dt'     => $docDate,
                'Sales_Return_Reason' => $reason ?: null,
            ]);

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

            // Reverse qty_returned for all items
            $orderItems = DB::table(self::ITEMS_TABLE)->where('order_id', $id)->get();
            foreach ($orderItems as $oi) {
                if ($oi->qty_returned > 0) {
                    DB::table(self::ITEMS_TABLE)
                        ->where('item_id', $oi->item_id)
                        ->update(['qty_returned' => 0]);
                }
            }

            // Clear return columns from the order
            DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                'Sales_Return_VoucherNo' => null,
                'Sales_Return_Dt'        => null,
                'Sales_Return_Reason'    => null,
            ]);

            return response()->json(['success' => true, 'message' => 'Sales return deleted']);
        } catch (\Throwable $e) {
            Log::error('SalesReturn destroy error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to delete sales return'], 500);
        }
    }

    private function generateVoucherNo(): string
    {
        $count   = DB::table(self::ORDERS_TABLE)->whereNotNull('Sales_Return_VoucherNo')->count();
        $nextNum = str_pad((string) ($count + 1), 3, '0', STR_PAD_LEFT);
        return self::VOUCHER_PREFIX . $nextNum;
    }

    private function normalizeSummary(object $row): array
    {
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
            'total_value'   => 0,
        ];
    }

    private function normalizeHeader(object $order): array
    {
        return [
            'id'                      => (int) ($order->order_id ?? 0),
            'voucher_no'              => $order->Sales_Return_VoucherNo ?? null,
            'doc_number'              => $order->Sales_Return_VoucherNo ?? null,
            'doc_no_prefix'           => self::VOUCHER_PREFIX,
            'doc_no_number'           => $order->Sales_Return_VoucherNo ?? '',
            'return_dt'               => $order->Sales_Return_Dt ?? null,
            'doc_date'                => $order->Sales_Return_Dt ?? null,
            'source_order_id'         => (int) ($order->order_id ?? 0),
            'source_sales_invoice_id' => (int) ($order->order_id ?? 0),
            'source_si_number'        => $order->bill_number ?? ('ORD-' . ($order->order_id ?? 0)),
            'customer_id'             => (int) ($order->buyer_userid ?? 0),
            'customer_name'           => $order->buyer_name ?? null,
            'reason'                  => $order->Sales_Return_Reason ?? null,
            'status'                  => $order->order_state ?? 'DRAFT',
        ];
    }

    private function normalizeItem(object $item): array
    {
        $pinfo       = json_decode($item->pinfo ?? '{}', true) ?: [];
        $qtyDelivered = (float) ($item->qty_delivered ?? 0);
        $qtyReturned  = (float) ($item->qty_returned ?? 0);
        $availableQty = max(0, $qtyDelivered - $qtyReturned);

        return [
            'order_item_id'                => (int) ($item->item_id ?? 0),
            'source_sales_invoice_item_id' => (int) ($item->item_id ?? 0),
            'product_id'                   => (int) ($item->product_id ?? 0),
            'product_name'                 => $pinfo['product_name'] ?? $pinfo['name'] ?? null,
            'product_code'                 => $pinfo['product_code'] ?? $pinfo['code'] ?? null,
            'unit'                         => $pinfo['unit'] ?? 'Nos',
            'original_quantity'            => (float) ($item->quantity ?? 0),
            'available_quantity'           => $availableQty,
            'returned_qty'                 => $qtyReturned,
            'returned_quantity'            => $qtyReturned,
            'unit_price'                   => (float) ($item->item_price ?? 0),
        ];
    }
}
