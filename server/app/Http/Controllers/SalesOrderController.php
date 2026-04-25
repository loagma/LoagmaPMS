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
                    'oi.vendor_product_id',
                    'oi.pinfo',
                    'oi.quantity',
                    'oi.qty_delivered',
                    'oi.qty_returned',
                    'oi.item_price',
                    'oi.item_total',
                ])
                ->get();

            $header = $this->normalizeHeader($order);
            $header['items'] = $items->map(fn ($item) => $this->normalizeItem($item))->values()->toArray();

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
            'id'           => $orderId,
            'so_number'    => 'ORD-' . $orderId,
            'customer_id'  => (int) ($data['buyer_userid'] ?? 0),
            'doc_date'     => $docDate,
            'status'       => strtoupper($state),
            'total_amount' => $total,
            'discount'     => $discount,
            'delivery_charge' => $delivery,
            'total_with_charges' => $total,
            'narration'    => null,
            'txn_id'       => $data['txn_id'] ?? null,
        ];
    }

    private function normalizeItem(object $row): array
    {
        $data = json_decode(json_encode($row), true) ?: [];

        $pinfo = [];
        if (!empty($data['pinfo'])) {
            $decoded = json_decode((string) $data['pinfo'], true);
            if (is_array($decoded)) {
                $pinfo = $decoded;
            }
        }

        $productName = trim((string) ($pinfo['name'] ?? $pinfo['product_name'] ?? ''));
        $productCode = trim((string) ($pinfo['product_code'] ?? $pinfo['code'] ?? ''));

        // Extract pack info – pinfo may have a 'packs' array or 'selected_pack'
        $unit     = 'Nos';
        $packId   = null;
        $packLabel = null;

        if (!empty($pinfo['selected_pack']) && is_array($pinfo['selected_pack'])) {
            $sp        = $pinfo['selected_pack'];
            $unit      = (string) ($sp['unit'] ?? $sp['description'] ?? 'Nos');
            $packId    = isset($sp['id']) ? (string) $sp['id'] : null;
            $packLabel = (string) ($sp['label'] ?? $sp['description'] ?? $unit);
        } elseif (!empty($pinfo['packs']) && is_array($pinfo['packs'])) {
            $firstPack = $pinfo['packs'][0] ?? [];
            $unit      = (string) ($firstPack['unit'] ?? $firstPack['description'] ?? 'Nos');
            $packId    = isset($firstPack['id']) ? (string) $firstPack['id'] : null;
            $packLabel = (string) ($firstPack['label'] ?? $firstPack['description'] ?? $unit);
        } elseif (!empty($pinfo['unit'])) {
            $unit = (string) $pinfo['unit'];
        }

        $qty         = (float) ($data['quantity'] ?? 0);
        $qtyDelivered = (float) ($data['qty_delivered'] ?? 0);
        $qtyReturned  = (float) ($data['qty_returned'] ?? 0);
        $usedQty      = $qtyDelivered;
        $writeoffQty  = $qtyReturned;
        $leftQty      = max(0, $qty - $usedQty - $writeoffQty);
        $price        = (float) ($data['item_price'] ?? 0);

        return [
            'id'           => (int) ($data['item_id'] ?? 0),
            'sales_order_id' => (int) ($data['order_id'] ?? 0),
            'product_id'   => (int) ($data['product_id'] ?? 0),
            'product_name' => $productName ?: ('Product ' . ($data['product_id'] ?? '?')),
            'product_code' => $productCode,
            'unit'         => $unit,
            'pack_id'      => $packId,
            'pack_label'   => $packLabel,
            'quantity'     => $qty,
            'price'        => $price,
            'used_qty'     => $usedQty,
            'writeoff_qty' => $writeoffQty,
            'left_qty'     => $leftQty,
            'line_total'   => (float) ($data['item_total'] ?? ($qty * $price)),
            'hsn_code'     => $pinfo['hsn_code'] ?? $pinfo['hsn'] ?? null,
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
