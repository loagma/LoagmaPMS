<?php

namespace App\Http\Controllers;

use App\Services\InvoicePdfService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class SalesOrderController extends Controller
{
    private const ORDERS_TABLE = 'loagma_new.orders';
    private const ITEMS_TABLE  = 'loagma_new.orders_item';

    private static array $CLOSED_STATES = ['cancelled', 'rejected', 'returned'];

    // GET /sales-orders/invoice-series
    public function series(): JsonResponse
    {
        try {
            $prefix  = $this->invoicePrefix();
            $docYear = $this->currentDocYear();
            $maxNum  = (int) DB::table(self::ORDERS_TABLE)
                ->where('Doc_Year', $docYear)
                ->whereNotNull('Doc_Year')
                ->max('invoice_number');
            $nextNum = str_pad((string) ($maxNum + 1), 3, '0', STR_PAD_LEFT);
            return response()->json([
                'success'     => true,
                'prefix'      => $prefix,
                'next_number' => $nextNum,
                'full_number' => $prefix . $nextNum,
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

            $query = DB::table(self::ORDERS_TABLE . ' as o')
                ->leftJoin('loagma_new.user as u', 'u.userid', '=', 'o.buyer_userid')
                ->leftJoin('loagma_new.LoginUser_crm as sm', DB::raw('CONVERT(sm.id USING utf8mb4) COLLATE utf8mb4_unicode_ci'), '=', DB::raw('CONVERT(o.salesman_id USING utf8mb4) COLLATE utf8mb4_unicode_ci'));

            if ($request->filled('customer_id')) {
                $query->where('o.buyer_userid', (int) $request->input('customer_id'));
            }

            if ($request->boolean('returnable')) {
                // Only show orders where goods were actually delivered to the customer
                $query->whereIn('o.order_state', ['delivered', 'dispatched', 'billed']);
            } elseif ($request->boolean('exclude_closed')) {
                $query->whereNotIn('o.order_state', self::$CLOSED_STATES);
            }

            if ($request->boolean('has_invoice')) {
                $query->whereNotNull('o.bill_no')->where('o.bill_no', '<>', '');
            }

            if ($request->filled('status')) {
                $query->where('o.order_state', $request->input('status'));
            }

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where(function ($q) use ($search) {
                    $q->where('o.order_id', 'like', "%{$search}%")
                      ->orWhere('o.txn_id', 'like', "%{$search}%")
                      ->orWhere('o.bill_no', 'like', "%{$search}%")
                      ->orWhere('u.name', 'like', "%{$search}%");
                });
            }

            if ($request->filled('from_date')) {
                $query->whereDate('o.short_datetime', '>=', $request->input('from_date'));
            }

            if ($request->filled('to_date')) {
                $query->whereDate('o.short_datetime', '<=', $request->input('to_date'));
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
                    'u.name as buyer_name',
                    'o.bill_no',
                    'o.Bill_Dt',
                    'o.Department',
                    'o.bill_roff',
                    'o.Doc_Year',
                    'o.salesman_id',
                    'sm.name as salesman_name',
                    'o.Sales_Return_VoucherNo',
                    'o.charges_json',
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
            return response()->json(['success' => false, 'message' => 'Failed to fetch sales orders: ' . $e->getMessage()], 500);
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
            $requestedBillNo = trim((string) $request->input('bill_number', '')) ?: null;
            $billDt        = $request->input('bill_dt') ?: null;
            $department    = trim((string) $request->input('department', '')) ?: null;
            $billNarration = trim((string) $request->input('bill_narration', '')) ?: null;
            $billVehicle   = trim((string) $request->input('bill_vehicle', '')) ?: null;
            $billStatement = trim((string) $request->input('bill_statement', '')) ?: null;
            $billRoff      = (float) $request->input('bill_roff', 0);
            $docYear       = trim((string) $request->input('doc_year', '')) ?: $this->currentDocYear();
            $chargesJson   = $request->input('charges', null);
            $rawSalesmanIdStore = $request->input('supplier_id');
            $salesmanIdStore    = ($rawSalesmanIdStore !== null && $rawSalesmanIdStore !== '') ? trim((string) $rawSalesmanIdStore) : null;

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

            $orderId = null;
            DB::transaction(function () use (
                $customerId, $status, $orderTotal, $discount, $delivery, $items,
                $docDate, $narration, $requestedBillNo, $billDt, $department, $billNarration,
                $billVehicle, $billStatement, $billRoff, $docYear, $salesmanIdStore,
                $chargesJson, &$orderId
            ) {
                // Issue B: generate invoice number inside the transaction with a lock so
                // concurrent requests cannot get the same number.
                [$billNo, $invoiceNumber] = $status === 'billed'
                    ? $this->resolveInvoiceNumber($requestedBillNo, $docYear)
                    : [$requestedBillNo, null];

                $orderId = $this->nextOrderId();
                DB::table(self::ORDERS_TABLE)->insert([
                    'order_id'        => $orderId,
                    'buyer_userid'    => $customerId,
                    'order_state'     => $status,
                    'order_total'     => $orderTotal,
                    'discount'        => $discount,
                    'delivery_charge' => $delivery,
                    'items_count'     => count($items),
                    'short_datetime'  => $docDate,
                    'txn_id'          => $narration,
                    'delivery_info'   => '{}',
                    'area_name'       => '',
                    'feedback'        => '',
                    'bill_number'     => 0,
                    'bill_no'         => $billNo,
                    'invoice_number'  => $invoiceNumber,
                    'Bill_Dt'         => $billDt,
                    'Department'      => $department,
                    'Bill_Narration'  => $billNarration,
                    'Bill_Vehicle'    => $billVehicle,
                    'Bill_Statement'  => $billStatement,
                    'bill_roff'       => $billRoff,
                    'Doc_Year'        => $docYear,
                    'salesman_id'     => $salesmanIdStore,
                    'charges_json'    => $chargesJson !== null ? json_encode($chargesJson) : null,
                ]);

                $nextId = $this->nextItemId();
                foreach ($items as $item) {
                    $productId = (int) ($item['product_id'] ?? 0);
                    $qty       = (int) round((float) ($item['quantity'] ?? 0));
                    $price     = (float) ($item['price'] ?? 0);

                    $pinfo = [];
                    if (!empty($item['hsn_code']))        $pinfo['hsn_code']         = $item['hsn_code'];
                    if (!empty($item['unit']))             $pinfo['unit']             = $item['unit'];
                    if (!empty($item['pack_id']))          $pinfo['selected_pack']    = ['id' => $item['pack_id'], 'unit' => $item['unit'] ?? 'Nos'];
                    if (!empty($item['description']))      $pinfo['description']      = $item['description'];
                    if (isset($item['discount_percent']))  $pinfo['discount_percent'] = (float) $item['discount_percent'];
                    if (isset($item['tax_percent']))       $pinfo['tax_percent']      = (float) $item['tax_percent'];

                    DB::table(self::ITEMS_TABLE)->insert([
                        'item_id'       => $nextId++,
                        'order_id'      => $orderId,
                        'product_id'    => $productId,
                        'quantity'      => $qty,
                        'item_price'    => $price,
                        'item_total'    => round($qty * $price, 2),
                        'pinfo'         => json_encode(!empty($pinfo) ? $pinfo : new \stdClass()),
                        'commission'    => 0,
                        'qty_delivered' => (int) round((float) ($item['qty_delivered'] ?? 0)),
                        'qty_returned'  => 0,
                    ]);
                }
            });

            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $orderId)->first();

            $pdfUrl = null;
            if ($status === 'billed') {
                $adminId = (int) $request->input('admin_id', 0);
                if ($adminId > 0) {
                    try {
                        $pdfUrl = app(InvoicePdfService::class)->generateAndStore($orderId, $adminId);
                    } catch (\Throwable $pdfErr) {
                        Log::warning('Invoice PDF generation failed after store: ' . $pdfErr->getMessage());
                    }
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Sales order created successfully',
                'data'    => $this->normalizeHeader($order),
                'pdf_url' => $pdfUrl,
            ], 201);
        } catch (\Throwable $e) {
            Log::error('SalesOrder store error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to create sales order: ' . $e->getMessage()], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }

            if ($request->boolean('cancel_invoice')) {
                DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                    'bill_no'        => null,
                    'invoice_number' => null,
                    'Bill_Dt'        => null,
                    'order_state'    => 'pending',
                ]);
                return response()->json(['success' => true, 'message' => 'Invoice cancelled, order reverted to Pending']);
            }

            $currentState = strtolower(trim((string) ($order->order_state ?? '')));
            if (in_array($currentState, self::$CLOSED_STATES, true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot edit order in state: ' . strtoupper($currentState),
                ], 422);
            }

            $items = $request->input('items', []);
            if (empty($items)) {
                return response()->json(['success' => false, 'message' => 'At least one item is required'], 422);
            }

            $status   = strtolower(trim((string) $request->input('status', $order->order_state ?? 'pending')));
            $docDate  = trim((string) $request->input('doc_date', $order->short_datetime ?? date('Y-m-d')));
            $discount = (float) $request->input('discount', is_numeric($order->discount ?? '') ? $order->discount : 0);
            $delivery = (float) $request->input('delivery_charge', is_numeric($order->delivery_charge ?? '') ? $order->delivery_charge : 0);
            $narration = trim((string) $request->input('narration', ''));

            // Bill fields — bill_no (varchar) stores the invoice number string; bill_number is a legacy INT column we don't touch
            $requestedBillNo = trim((string) $request->input('bill_number', '')) ?: ($order->bill_no ?? null);
            $billDt        = $request->input('bill_dt') ?: null;
            $department    = trim((string) $request->input('department', '')) ?: null;
            $billNarration = trim((string) $request->input('bill_narration', '')) ?: null;
            $billVehicle   = trim((string) $request->input('bill_vehicle', '')) ?: null;
            $billStatement = trim((string) $request->input('bill_statement', '')) ?: null;
            $billRoff      = (float) $request->input('bill_roff', 0);
            $docYear       = trim((string) $request->input('doc_year', '')) ?: ($order->Doc_Year ?? $this->currentDocYear());
            $chargesJson   = $request->input('charges', null);
            $rawSalesmanId = $request->input('supplier_id');
            $salesmanId    = ($rawSalesmanId !== null && $rawSalesmanId !== '') ? trim((string) $rawSalesmanId) : null;

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

            DB::transaction(function () use ($id, $order, $status, $orderTotal, $discount, $delivery, $items, $narration, $requestedBillNo, $billDt, $department, $billNarration, $billVehicle, $billStatement, $billRoff, $docYear, $salesmanId, $chargesJson) {
                // Issue B: generate the authoritative invoice number inside the transaction
                // with a SELECT ... FOR UPDATE lock so concurrent saves get different numbers.
                [$billNo, $invoiceNumber] = $status === 'billed'
                    ? $this->resolveInvoiceNumber($requestedBillNo, $docYear, $id)
                    : [$requestedBillNo, $order->invoice_number ?? null];

                DB::table(self::ORDERS_TABLE)->where('order_id', $id)->update([
                    'order_state'     => $status,
                    'order_total'     => $orderTotal,
                    'discount'        => $discount,
                    'delivery_charge' => $delivery,
                    'items_count'     => count($items),
                    'txn_id'          => $narration,
                    'bill_no'         => $billNo,
                    'invoice_number'  => $invoiceNumber,
                    'Bill_Dt'         => $billDt,
                    'Department'      => $department,
                    'Bill_Narration'  => $billNarration,
                    'Bill_Vehicle'    => $billVehicle,
                    'Bill_Statement'  => $billStatement,
                    'bill_roff'       => $billRoff,
                    'Doc_Year'        => $docYear,
                    'salesman_id'     => $salesmanId,
                    'charges_json'    => $chargesJson !== null ? json_encode($chargesJson) : null,
                ]);

                // Issue D: snapshot existing qty_returned per product_id before deleting,
                // so we can restore them in the fresh inserts.
                $returnedMap = DB::table(self::ITEMS_TABLE)
                    ->where('order_id', $id)
                    ->pluck('qty_returned', 'product_id')
                    ->map(fn ($v) => (int) $v)
                    ->toArray();

                DB::table(self::ITEMS_TABLE)->where('order_id', $id)->delete();

                $nextId = $this->nextItemId();
                foreach ($items as $item) {
                    $productId = (int) ($item['product_id'] ?? 0);
                    $qty       = (int) round((float) ($item['quantity'] ?? 0));
                    $price     = (float) ($item['price'] ?? 0);

                    $pinfo = [];
                    if (!empty($item['hsn_code']))       $pinfo['hsn_code']        = $item['hsn_code'];
                    if (!empty($item['unit']))            $pinfo['unit']            = $item['unit'];
                    if (!empty($item['pack_id']))         $pinfo['selected_pack']   = ['id' => $item['pack_id'], 'unit' => $item['unit'] ?? 'Nos'];
                    if (!empty($item['description']))     $pinfo['description']     = $item['description'];
                    if (isset($item['discount_percent'])) $pinfo['discount_percent'] = (float) $item['discount_percent'];
                    if (isset($item['tax_percent']))      $pinfo['tax_percent']     = (float) $item['tax_percent'];

                    DB::table(self::ITEMS_TABLE)->insert([
                        'item_id'       => $nextId++,
                        'order_id'      => $id,
                        'product_id'    => $productId,
                        'quantity'      => $qty,
                        'item_price'    => $price,
                        'item_total'    => round($qty * $price, 2),
                        'pinfo'         => json_encode(!empty($pinfo) ? $pinfo : new \stdClass()),
                        'commission'    => 0,
                        'qty_delivered' => (int) round((float) ($item['qty_delivered'] ?? 0)),
                        // Issue D: restore any previously recorded return qty for this product
                        'qty_returned'  => $returnedMap[$productId] ?? 0,
                    ]);
                }
            });

            $updated = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();

            $pdfUrl = null;
            if ($status === 'billed') {
                $adminId = (int) $request->input('admin_id', 0);
                if ($adminId > 0) {
                    try {
                        $pdfUrl = app(InvoicePdfService::class)->generateAndStore($id, $adminId);
                    } catch (\Throwable $pdfErr) {
                        Log::warning('Invoice PDF generation failed after update: ' . $pdfErr->getMessage());
                    }
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Sales order updated successfully',
                'data'    => $this->normalizeHeader($updated),
                'pdf_url' => $pdfUrl,
            ]);
        } catch (\Throwable $e) {
            Log::error('SalesOrder update error: ' . $e->getMessage() . ' ' . $e->getTraceAsString());
            return response()->json(['success' => false, 'message' => 'Failed to update sales order: ' . $e->getMessage()], 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        try {
            $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
            if (!$order) {
                return response()->json(['success' => false, 'message' => 'Order not found'], 404);
            }
            if (!empty($order->bill_no)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Cannot delete order: invoice ' . $order->bill_no . ' is linked. Delete the invoice first.',
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
                ->leftJoin('loagma_new.user as u', 'u.userid', '=', 'o.buyer_userid')
                ->leftJoin('loagma_new.LoginUser_crm as sm', DB::raw('CONVERT(sm.id USING utf8mb4) COLLATE utf8mb4_unicode_ci'), '=', DB::raw('CONVERT(o.salesman_id USING utf8mb4) COLLATE utf8mb4_unicode_ci'))
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
                    'u.name as buyer_name',
                    'u.email as buyer_email',
                    'u.contactno as buyer_phone',
                    'o.bill_no',
                    'o.Bill_Dt',
                    'o.Department',
                    'o.Bill_Narration',
                    'o.Bill_Vehicle',
                    'o.Bill_Statement',
                    'o.bill_roff',
                    'o.Doc_Year',
                    'o.salesman_id',
                    'sm.name as salesman_name',
                    'o.Sales_Return_VoucherNo',
                    'o.charges_json',
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

    // GET /sales-orders/{id}/pdf?admin_id=1
    public function generatePdf(Request $request, int $id): JsonResponse
    {
        $adminId = (int) $request->input('admin_id', 0);
        if ($adminId <= 0) {
            return response()->json(['success' => false, 'message' => 'admin_id is required'], 422);
        }

        $order = DB::table(self::ORDERS_TABLE)->where('order_id', $id)->first();
        if (!$order) {
            return response()->json(['success' => false, 'message' => 'Order not found'], 404);
        }
        if (empty($order->bill_no)) {
            return response()->json(['success' => false, 'message' => 'Order is not invoiced yet — bill_no is empty'], 422);
        }

        try {
            $url = app(InvoicePdfService::class)->generateAndStore($id, $adminId);
            if ($url === null) {
                return response()->json(['success' => false, 'message' => 'Failed to generate PDF — admin not found or order data incomplete'], 500);
            }
            return response()->json(['success' => true, 'pdf_url' => $url]);
        } catch (\Throwable $e) {
            Log::error('SalesOrder generatePdf error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'PDF generation failed: ' . $e->getMessage()], 500);
        }
    }

    // ── Invoice series helpers ────────────────────────────────────────────────

    private function invoicePrefix(): string
    {
        $now     = Carbon::now();
        $fyStart = $now->month >= 4 ? $now->year : $now->year - 1;
        return 'INV/' . substr((string) $fyStart, 2) . '-' . substr((string) ($fyStart + 1), 2) . '/';
    }

    private function currentDocYear(): string
    {
        $now     = Carbon::now();
        $fyStart = $now->month >= 4 ? $now->year : $now->year - 1;
        return substr((string) $fyStart, 2) . '-' . substr((string) ($fyStart + 1), 2);
    }

    /**
     * Issue B fix: resolve the definitive invoice number inside a transaction.
     *
     * If the caller already supplied a non-empty bill_no string AND it does not
     * match the auto-generated prefix pattern (i.e. a manual override), we trust
     * it as-is and return null for the numeric sequence column.
     *
     * Otherwise we lock the MAX(invoice_number) row for the current doc year and
     * increment it — preventing two concurrent requests from getting the same number.
     *
     * @param  string|null  $requestedBillNo  value from the request (may be null or empty)
     * @param  string       $docYear          e.g. '25-26'
     * @param  int|null     $excludeOrderId   when editing, exclude this order's own number
     * @return array{0: string, 1: int}       [bill_no string, invoice_number int]
     */
    private function resolveInvoiceNumber(?string $requestedBillNo, string $docYear, ?int $excludeOrderId = null): array
    {
        $prefix = $this->invoicePrefix();

        // Re-editing an already-billed order: if the bill_no being submitted is the
        // same one already on the order (i.e. the user did not change it), preserve
        // the existing number — do NOT burn a new sequence slot.
        if ($excludeOrderId !== null && $requestedBillNo !== null && $requestedBillNo !== '') {
            $existing = DB::table(self::ORDERS_TABLE)
                ->where('order_id', $excludeOrderId)
                ->value('invoice_number');

            if ($existing !== null) {
                // Order already owns a sequence number — keep bill_no and number unchanged.
                return [$requestedBillNo, (int) $existing];
            }
        }

        // If the request sends a manually typed bill_no that does not match the
        // auto-generated prefix, honour it as-is without consuming a sequence slot.
        if ($requestedBillNo !== null && $requestedBillNo !== '' && !str_starts_with($requestedBillNo, $prefix)) {
            return [$requestedBillNo, null];
        }

        // Lock ALL rows for this doc year so concurrent requests queue here and
        // each reads a fresh max after the previous transaction commits.
        // whereNotNull('Doc_Year') excludes legacy rows that predate the column.
        $query = DB::table(self::ORDERS_TABLE)
            ->where('Doc_Year', $docYear)
            ->whereNotNull('Doc_Year')
            ->lockForUpdate();

        if ($excludeOrderId !== null) {
            $query->where('order_id', '<>', $excludeOrderId);
        }

        $maxNum  = (int) $query->max('invoice_number');
        $nextNum = $maxNum + 1;
        $billNo  = $prefix . str_pad((string) $nextNum, 3, '0', STR_PAD_LEFT);

        return [$billNo, $nextNum];
    }

    private function nextOrderId(): int
    {
        $max = DB::table(self::ORDERS_TABLE)->max('order_id') ?? 0;
        return (int) $max + 1;
    }

    private function nextItemId(): int
    {
        $max = DB::table(self::ITEMS_TABLE)->max('item_id') ?? 0;
        return (int) $max + 1;
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
            'id'               => $orderId,
            'so_number'        => 'ORD-' . $orderId,
            'customer_id'      => (int) ($data['buyer_userid'] ?? 0),
            'customer_name'    => $data['buyer_name'] ?? null,
            'customer_email'   => $data['buyer_email'] ?? null,
            'customer_phone'   => $data['buyer_phone'] ?? null,
            'doc_date'         => $docDate,
            'status'           => strtoupper($state),
            'total_amount'     => $total,
            'discount'         => $discount,
            'delivery_charge'  => $delivery,
            'total_with_charges' => round($total - $discount + $delivery, 2),
            'narration'        => $data['txn_id'] ?? null,
            'bill_number'      => $data['bill_no'] ?? null,
            'invoice_number'   => isset($data['invoice_number']) ? (int) $data['invoice_number'] : null,
            'bill_dt'          => $data['Bill_Dt'] ?? null,
            'department'       => $data['Department'] ?? null,
            'bill_narration'   => $data['Bill_Narration'] ?? null,
            'bill_vehicle'     => $data['Bill_Vehicle'] ?? null,
            'bill_statement'   => $data['Bill_Statement'] ?? null,
            'bill_roff'        => (float) ($data['bill_roff'] ?? 0),
            'doc_year'         => $data['Doc_Year'] ?? null,
            'supplier_id'                => $data['salesman_id'] ?? null,
            'salesman_name'              => $data['salesman_name'] ?? null,
            'items_count'                => (int) ($data['items_count'] ?? 0),
            'sales_return_voucher_no'    => $data['Sales_Return_VoucherNo'] ?? null,
            'charges'                    => isset($data['charges_json'])
                ? (json_decode((string) $data['charges_json'], true) ?? [])
                : [],
            'pdf_url'                    => $this->existingPdfUrl(
                $data['bill_no'] ?? null,
                $data['Doc_Year'] ?? null
            ),
        ];
    }

    private function existingPdfUrl(?string $billNo, ?string $docYear): ?string
    {
        if (empty($billNo)) {
            return null;
        }
        $filename = str_replace('/', '_', $billNo) . '.pdf';
        $path     = 'documents/sales-invoices/' . ($docYear ?? 'general') . '/' . $filename;
        return Storage::disk('public')->exists($path)
            ? Storage::disk('public')->url($path)
            : null;
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
        // pinfo['pu'] = unit from legacy delivery-app orders (fallback)
        $unit     = !empty($pinfo['pu']) ? (string) $pinfo['pu'] : 'Nos';
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
