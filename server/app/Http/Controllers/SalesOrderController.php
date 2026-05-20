<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SalesOrderController extends Controller
{
    private const ORDERS_TABLE = 'loagma_new.orders';
    private const ITEMS_TABLE  = 'loagma_new.orders_item';

    private static array $CLOSED_STATES = ['cancelled', 'rejected', 'returned'];

    // GET /sales-orders/invoice-series
    public function series(): JsonResponse
    {
        try {
            $count   = DB::table(self::ORDERS_TABLE)->whereNotNull('bill_number')->count();
            $nextNum = str_pad((string) ($count + 1), 3, '0', STR_PAD_LEFT);
            return response()->json([
                'success'     => true,
                'prefix'      => 'INV/25-26/',
                'next_number' => $nextNum,
                'full_number' => 'INV/25-26/' . $nextNum,
            ]);
        } catch (\Throwable $e) {
            Log::error('SalesOrder series error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to get invoice series'], 500);
        }
    }

    public function index(Request $request): JsonResponse
    {
        try {
            $limit = max(1, min((int) $request->input('limit', 20), 200));
            $page  = max(1, (int) $request->input('page', 1));

            $query = DB::table(self::ORDERS_TABLE . ' as o');

            if ($request->filled('customer_id')) {
                $query->where('o.buyer_userid', (int) $request->input('customer_id'));
            }

            if ($request->boolean('exclude_closed')) {
                $query->whereNotIn('o.order_state', self::$CLOSED_STATES);
            }

            if ($request->filled('status')) {
                $query->where('o.order_state', $request->input('status'));
            }

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('o.order_id', 'like', "%{$search}%")
                      ->orWhere('o.txn_id', 'like', "%{$search}%");
                });
            }

            $query->orderBy('o.order_id', 'desc');

            $total = $query->count();
            $rows  = $query
                ->select([
                    'o.order_id',
                    'o.buyer_userid',
                    'o.order_state',
                    'o.order_total',
                    'o.txn_id',
                    'o.short_datetime',
                    'o.discount',
                    'o.delivery_charge',
                    'o.items_count',
                    'o.buyer_name',
                    'o.bill_number',
                    'o.Bill_Dt',
                    'o.Department',
                    'o.Bill_Narration',
                    'o.Bill_Vehicle',
                    'o.Bill_Statement',
                    'o.bill_roff',
                    'o.Doc_Year',
                    'o.Sales_Return_VoucherNo',
                    'o.Sales_Return_Dt',
                ])
                ->offset(($page - 1) * $limit)
                ->limit($limit)
                ->get();

            return response()->json([
                'success' => true,
                'data' => $rows->map(fn ($row) => $this->normalizeHeader($row))->values(),
                'pagination' => [
                    'total' => $total,
                    'page'  => $page,
                    'limit' => $limit,
                    'pages' => (int) ceil($total / $limit),
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('SalesOrder index error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to fetch sales orders'], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            $customerId = (int) $request->input('customer_id', 0);
            if ($customerId <= 0) {
                return response()->json(['success' => false, 'message' => 'customer_id is required'], 422);
            }

            $items = $request->input('items', []);
            if (empty($items)) {
                return response()->json(['success' => false, 'message' => 'At least one item is required'], 422);
            }

            $status    = strtolower(trim((string) $request->input('status', 'pending')));
            $docDate   = trim((string) $request->input('doc_date', date('Y-m-d')));
            $discount  = (float) $request->input('discount', 0);
            $delivery  = (float) $request->input('delivery_charge', 0);
            $narration = trim((string) $request->input('narration', ''));

            // Bill fields (populated when status = 'billed')
            $billDt        = $request->input('bill_dt') ?: null;
            $department    = trim((string) $request->input('department', '')) ?: null;
            $billNarration = trim((string) $request->input('bill_narration', '')) ?: null;
            $billVehicle   = trim((string) $request->input('bill_vehicle', '')) ?: null;
            $billStatement = trim((string) $request->input('bill_statement', '')) ?: null;
            $billRoff      = (float) $request->input('bill_roff', 0);
            $docYear       = trim((string) $request->input('doc_year', '')) ?: null;

            // Return fields
            $salesReturnVoucherNo = trim((string) $request->input('sales_return_voucher_no', '')) ?: null;
            $salesReturnDt        = $request->input('sales_return_dt') ?: null;

            if ($status === 'billed' && empty($billDt)) {
                return response()->json(['success' => false, 'message' => 'bill_dt is required when status is billed'], 422);
            }

            $lineTotal = 0.0;
            foreach ($items as $item) {
                $qty   = (float) ($item['quantity'] ?? 0);
                $price = (float) ($item['price'] ?? 0);
                $lineTotal += round($qty * $price, 2);
            }
            $orderTotal = round($lineTotal - $discount + $delivery, 2);

            $orderId = DB::table(self::ORDERS_TABLE)->insertGetId([
                'buyer_userid'    => $customerId,
                'order_state'     => $status,
                'order_total'     => $orderTotal,
                'discount'        => $discount,
                'delivery_charge' => $delivery,
                'items_count'     => count($items),
                'short_datetime'  => $docDate,
                'txn_id'          => $narration ?: null,
                'Bill_Dt'         => $billDt,
                'Department'      => $department,
                'Bill_Narration'  => $billNarration,
                'Bill_Vehicle'    => $billVehicle,
                'Bill_Statement'  => $billStatement,
                'bill_roff'               => $billRoff,
                'Doc_Year'                => $docYear,
                'Sales_Return_VoucherNo'  => $salesReturnVoucherNo,
                'Sales_Return_Dt'         => $salesReturnDt,
            ], 'order_id');

            foreach ($items as $item) {
                $productId = (int) ($item['product_id'] ?? 0);
                $qty       = (float) ($item['quantity'] ?? 0);
                $price     = (float) ($item['price'] ?? 0);

                $pinfo = [];
                if (!empty($item['hsn_code']))  $pinfo['hsn_code']  = $item['hsn_code'];
                if (!empty($item['unit']))       $pinfo['unit']      = $item['unit'];
                if (!empty($item['pack_id']))    $pinfo['selected_pack'] = ['id' => $item['pack_id'], 'unit' => $item['unit'] ?? 'Nos'];
                if (!empty($item['description'])) $pinfo['description'] = $item['description'];

                DB::table(self::ITEMS_TABLE)->insert([
                    'order_id'    => $orderId,
                    'product_id'  => $productId,
                    'quantity'    => $qty,
                    'item_price'  => $price,
                    'item_total'  => round($qty * $price, 2),
                    'pinfo'       => !empty($pinfo) ? json_encode($pinfo) : null,
                    'qty_delivered' => 0,
                    'qty_returned'  => 0,
                ]);
            }

            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $orderId)->first();
            return response()->json([
                'success' => true,
                'message' => 'Sales order created successfully',
                'data'    => $this->normalizeHeader($order),
            ], 201);
        } catch (\Throwable $e) {
            Log::error('SalesOrder store error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to create sales order'], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }

            $items = $request->input('items', []);
            if (empty($items)) {
                return response()->json(['success' => false, 'message' => 'At least one item is required'], 422);
            }

            $status   = strtolower(trim((string) $request->input('status', $order->order_state ?? 'pending')));
            $docDate  = trim((string) $request->input('doc_date', $order->short_datetime ?? date('Y-m-d')));
            $discount = (float) $request->input('discount', $order->discount ?? 0);
            $delivery = (float) $request->input('delivery_charge', $order->delivery_charge ?? 0);
            $narration = trim((string) $request->input('narration', ''));

            // Bill fields
            $billNumber    = trim((string) $request->input('bill_number', '')) ?: ($order->bill_number ?? null);
            $billDt        = $request->input('bill_dt') ?: null;
            $department    = trim((string) $request->input('department', '')) ?: null;
            $billNarration = trim((string) $request->input('bill_narration', '')) ?: null;
            $billVehicle   = trim((string) $request->input('bill_vehicle', '')) ?: null;
            $billStatement = trim((string) $request->input('bill_statement', '')) ?: null;
            $billRoff      = (float) $request->input('bill_roff', 0);
            $docYear       = trim((string) $request->input('doc_year', '')) ?: null;

            // Return fields
            $salesReturnVoucherNo = trim((string) $request->input('sales_return_voucher_no', '')) ?: null;
            $salesReturnDt        = $request->input('sales_return_dt') ?: null;

            if ($status === 'billed' && empty($billDt)) {
                return response()->json(['success' => false, 'message' => 'bill_dt is required when status is billed'], 422);
            }

            $lineTotal = 0.0;
            foreach ($items as $item) {
                $qty   = (float) ($item['quantity'] ?? 0);
                $price = (float) ($item['price'] ?? 0);
                $lineTotal += round($qty * $price, 2);
            }
            $orderTotal = round($lineTotal - $discount + $delivery, 2);

            DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                'order_state'     => $status,
                'order_total'     => $orderTotal,
                'discount'        => $discount,
                'delivery_charge' => $delivery,
                'items_count'     => count($items),
                'short_datetime'  => $docDate,
                'txn_id'          => $narration ?: null,
                'bill_number'             => $billNumber,
                'Bill_Dt'                 => $billDt,
                'Department'              => $department,
                'Bill_Narration'          => $billNarration,
                'Bill_Vehicle'            => $billVehicle,
                'Bill_Statement'          => $billStatement,
                'bill_roff'               => $billRoff,
                'Doc_Year'                => $docYear,
                'Sales_Return_VoucherNo'  => $salesReturnVoucherNo,
                'Sales_Return_Dt'         => $salesReturnDt,
            ]);

            DB::table(self::ITEMS_TABLE)->where('order_id', $id)->delete();

            foreach ($items as $item) {
                $productId = (int) ($item['product_id'] ?? 0);
                $qty       = (float) ($item['quantity'] ?? 0);
                $price     = (float) ($item['price'] ?? 0);

                $pinfo = [];
                if (!empty($item['hsn_code']))    $pinfo['hsn_code']  = $item['hsn_code'];
                if (!empty($item['unit']))         $pinfo['unit']      = $item['unit'];
                if (!empty($item['pack_id']))      $pinfo['selected_pack'] = ['id' => $item['pack_id'], 'unit' => $item['unit'] ?? 'Nos'];
                if (!empty($item['description'])) $pinfo['description'] = $item['description'];

                DB::table(self::ITEMS_TABLE)->insert([
                    'order_id'      => $id,
                    'product_id'    => $productId,
                    'quantity'      => $qty,
                    'item_price'    => $price,
                    'item_total'    => round($qty * $price, 2),
                    'pinfo'         => !empty($pinfo) ? json_encode($pinfo) : null,
                    'qty_delivered' => (float) ($item['qty_delivered'] ?? 0),
                    'qty_returned'  => 0,
                ]);
            }

            $updated = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            return response()->json([
                'success' => true,
                'message' => 'Sales order updated successfully',
                'data'    => $this->normalizeHeader($updated),
            ]);
        } catch (\Throwable $e) {
            Log::error('SalesOrder update error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to update sales order'], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }
            if (!empty($order->bill_number)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete order: invoice ' . $order->bill_number . ' is linked. Delete the invoice first.',
                ], 422);
            }
            DB::table(self::ITEMS_TABLE)->where('order_id', $id)->delete();
            DB::table(self::ORDERS_TABLE)->where('order_id', $id)->delete();
            return response()->json(['success' => true, 'message' => 'Order deleted']);
        } catch (\Throwable $e) {
            Log::error('SalesOrder destroy error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to delete order'], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE . ' as o')
                ->where('o.order_id', $id)
                ->select([
                    'o.order_id',
                    'o.buyer_userid',
                    'o.order_state',
                    'o.order_total',
                    'o.txn_id',
                    'o.short_datetime',
                    'o.discount',
                    'o.delivery_charge',
                    'o.items_count',
                    'o.bill_number',
                    'o.Bill_Dt',
                    'o.Department',
                    'o.Bill_Narration',
                    'o.Bill_Vehicle',
                    'o.Bill_Statement',
                    'o.bill_roff',
                    'o.Doc_Year',
                    'o.Sales_Return_VoucherNo',
                    'o.Sales_Return_Dt',
                ])
                ->first();

            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }

            $items = DB::table(self::ITEMS_TABLE . ' as oi')
                ->where('oi.order_id', $id)
                ->select([
                    'oi.item_id',
                    'oi.order_id',
                    'oi.product_id',
                    'oi.pinfo',
                    'oi.quantity',
                    'oi.qty_delivered',
                    'oi.qty_returned',
                    'oi.item_price',
                    'oi.item_total',
                ])
                ->get();

            // Batch-fetch product names + hsn_code from the product table
            $productIds = $items->pluck('product_id')->filter()->unique()->values()->toArray();
            $productMap = [];
            if (!empty($productIds)) {
                $products = DB::table('product')
                    ->whereIn('product_id', $productIds)
                    ->select(['product_id', 'name', 'hsn_code', 'packs', 'default_pack_id'])
                    ->get();
                foreach ($products as $p) {
                    $productMap[(int) $p->product_id] = [
                        'name'     => trim((string) ($p->name ?? '')),
                        'hsn_code' => trim((string) ($p->hsn_code ?? '')),
                        'packs'    => $p->packs ?? null,
                        'default_pack_id' => $p->default_pack_id ?? null,
                    ];
                }
            }

            $header = $this->normalizeHeader($order);
            $header['items'] = $items
                ->map(fn ($item) => $this->normalizeItem($item, $productMap))
                ->values()
                ->toArray();

            return response()->json(['success' => true, 'data' => $header]);
        } catch (\Throwable $e) {
            Log::error('SalesOrder show error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Order not found'], 404);
        }
    }

    private function normalizeHeader(object $row): array
    {
        $data = json_decode(json_encode($row), true) ?: [];

        $orderId = (int) ($data['order_id'] ?? 0);
        $total   = (float) ($data['order_total'] ?? 0);
        $discount = (float) ($data['discount'] ?? 0);
        $delivery = (float) ($data['delivery_charge'] ?? 0);

        // Parse doc_date from short_datetime (stored as human-readable string or timestamp)
        $docDate = $this->parseDocDate($data['short_datetime'] ?? '');

        $state = strtolower(trim((string) ($data['order_state'] ?? 'pending')));

        return [
            'id'            => $orderId,
            'so_number'     => 'ORD-' . $orderId,
            'customer_id'   => (int) ($data['buyer_userid'] ?? 0),
            'customer_name' => $data['buyer_name'] ?? null,
            'doc_date'     => $docDate,
            'status'       => strtoupper($state),
            'total_amount' => $total,
            'discount'     => $discount,
            'delivery_charge' => $delivery,
            'total_with_charges' => $total,
            'narration'    => null,
            'txn_id'       => $data['txn_id'] ?? null,
            'bill_number'    => $data['bill_number'] ?? null,
            'bill_dt'        => $data['Bill_Dt'] ?? null,
            'department'     => $data['Department'] ?? null,
            'bill_narration' => $data['Bill_Narration'] ?? null,
            'bill_vehicle'   => $data['Bill_Vehicle'] ?? null,
            'bill_statement' => $data['Bill_Statement'] ?? null,
            'bill_roff'               => (float) ($data['bill_roff'] ?? 0),
            'doc_year'                => $data['Doc_Year'] ?? null,
            'sales_return_voucher_no' => $data['Sales_Return_VoucherNo'] ?? null,
            'sales_return_dt'         => $data['Sales_Return_Dt'] ?? null,
        ];
    }

    private function normalizeItem(object $row, array $productMap = []): array
    {
        $data = json_decode(json_encode($row), true) ?: [];

        $productId = (int) ($data['product_id'] ?? 0);
        $productInfo = $productMap[$productId] ?? [];

        // Parse pinfo JSON (snapshot at order time)
        $pinfo = [];
        if (!empty($data['pinfo'])) {
            $decoded = json_decode((string) $data['pinfo'], true);
            if (is_array($decoded)) {
                $pinfo = $decoded;
            }
        }

        // Product name: prefer product table (authoritative), fall back to pinfo snapshot
        $productName = $productInfo['name'] ?? '';
        if ($productName === '') {
            $productName = trim((string) ($pinfo['name'] ?? $pinfo['product_name'] ?? ''));
        }
        $productCode = trim((string) ($pinfo['product_code'] ?? $pinfo['code'] ?? ''));
        $hsnCode = $productInfo['hsn_code'] ?? $pinfo['hsn_code'] ?? $pinfo['hsn'] ?? null;

        // Extract pack info from pinfo (order-time snapshot) or product table packs
        $unit     = 'Nos';
        $packId   = null;
        $packLabel = null;

        if (!empty($pinfo['selected_pack']) && is_array($pinfo['selected_pack'])) {
            $sp        = $pinfo['selected_pack'];
            $unit      = (string) ($sp['unit'] ?? $sp['description'] ?? 'Nos');
            $packId    = isset($sp['id']) ? (string) $sp['id'] : null;
            $packLabel = (string) ($sp['label'] ?? $sp['description'] ?? $unit);
        } elseif (!empty($pinfo['packs']) && is_array($pinfo['packs'])) {
            // pinfo has packs array — find the selected one or use first
            $packsArr = $pinfo['packs'];
            $defaultPackId = $pinfo['default_pack_id'] ?? null;
            $selectedPack = null;
            if ($defaultPackId !== null) {
                foreach ($packsArr as $p) {
                    if ((string) ($p['id'] ?? '') === (string) $defaultPackId) {
                        $selectedPack = $p;
                        break;
                    }
                }
            }
            $selectedPack = $selectedPack ?? ($packsArr[0] ?? []);
            $unit      = (string) ($selectedPack['unit'] ?? $selectedPack['description'] ?? 'Nos');
            $packId    = isset($selectedPack['id']) ? (string) $selectedPack['id'] : null;
            $packLabel = (string) ($selectedPack['label'] ?? $selectedPack['description'] ?? $unit);
        } elseif (!empty($productInfo['packs'])) {
            // Fall back to product table packs
            $packsJson = json_decode((string) $productInfo['packs'], true);
            if (is_array($packsJson) && !empty($packsJson)) {
                $defaultPackId = $productInfo['default_pack_id'] ?? null;
                $selectedPack = null;
                if ($defaultPackId !== null) {
                    foreach ($packsJson as $p) {
                        if ((string) ($p['id'] ?? '') === (string) $defaultPackId) {
                            $selectedPack = $p;
                            break;
                        }
                    }
                }
                $selectedPack = $selectedPack ?? ($packsJson[0] ?? []);
                $unit      = (string) ($selectedPack['unit'] ?? $selectedPack['description'] ?? 'Nos');
                $packId    = isset($selectedPack['id']) ? (string) $selectedPack['id'] : null;
                $packLabel = (string) ($selectedPack['label'] ?? $selectedPack['description'] ?? $unit);
            }
        }

        $qty          = (float) ($data['quantity'] ?? 0);
        $qtyDelivered = (float) ($data['qty_delivered'] ?? 0);
        $qtyReturned  = (float) ($data['qty_returned'] ?? 0);

        // left_qty = still undelivered (not yet given to customer)
        $leftQty = max(0, $qty - $qtyDelivered);
        // available_to_return = of what was delivered, how much can still be returned
        $availableToReturn = max(0, $qtyDelivered - $qtyReturned);

        // item_price is the unit price in orders_item
        // item_total is qty * unit_price (line total)
        $itemPrice = (float) ($data['item_price'] ?? 0);
        $itemTotal = (float) ($data['item_total'] ?? 0);
        // Derive unit price: if item_price > 0 use it directly, else derive from total / qty
        $price = $itemPrice > 0 ? $itemPrice : ($qty > 0 ? round($itemTotal / $qty, 4) : 0);

        return [
            'id'                 => (int) ($data['item_id'] ?? 0),
            'sales_order_id'     => (int) ($data['order_id'] ?? 0),
            'product_id'         => $productId,
            'product_name'       => $productName ?: ('Product ' . $productId),
            'product_code'       => $productCode,
            'unit'               => $unit,
            'pack_id'            => $packId,
            'pack_label'         => $packLabel,
            'quantity'           => $qty,
            'price'              => $price,
            'used_qty'           => $qtyDelivered,
            'writeoff_qty'       => 0,
            'returned_qty'       => $qtyReturned,
            'left_qty'           => $leftQty,
            'available_quantity' => $availableToReturn,
            'line_total'         => $itemTotal > 0 ? $itemTotal : round($qty * $price, 2),
            'hsn_code'           => $hsnCode,
        ];
    }

    private function parseDocDate(string $raw): string
    {
        $raw = trim($raw);
        if ($raw === '') {
            return date('Y-m-d');
        }

        // Try direct parse first
        $ts = strtotime($raw);
        if ($ts !== false) {
            return date('Y-m-d', $ts);
        }

        // If it looks like a unix timestamp integer string
        if (ctype_digit($raw)) {
            return date('Y-m-d', (int) $raw);
        }

        return date('Y-m-d');
    }
}
