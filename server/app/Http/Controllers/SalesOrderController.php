<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\QueryException;

class SalesOrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = DB::table('orders as o')
            ->select([
                'o.order_id',
                'o.buyer_userid',
                'o.short_datetime',
                'o.order_state',
                'o.payment_status',
                'o.payment_method',
                'o.feedback',
                'o.order_total',
                'o.items_count',
            ])
            ->orderByDesc('o.order_id');

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $query->where(function ($q) use ($search): void {
                $q->where('o.order_id', $search)
                    ->orWhere('o.buyer_userid', $search)
                    ->orWhere('o.order_state', 'like', "%{$search}%");
            });
        }

        if ($request->filled('order_state')) {
            $query->where('o.order_state', (string) $request->input('order_state'));
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate((int) $request->input('per_page', 25)),
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $order = DB::table('orders')->where('order_id', $id)->first();
        if (! $order) {
            return response()->json([
                'success' => false,
                'message' => 'Sales order not found',
            ], 404);
        }

        $items = DB::table('orders_item')
            ->where('order_id', $id)
            ->orderBy('item_id')
            ->get()
            ->map(function ($item): array {
                return [
                    'item_id' => (int) $item->item_id,
                    'product_id' => (int) $item->product_id,
                    'vendor_product_id' => $item->vendor_product_id !== null ? (int) $item->vendor_product_id : null,
                    'quantity' => (float) $item->quantity,
                    'qty_loaded' => (float) ($item->qty_loaded ?? 0),
                    'qty_delivered' => (float) ($item->qty_delivered ?? 0),
                    'qty_returned' => (float) ($item->qty_returned ?? 0),
                    'item_price' => (float) $item->item_price,
                    'item_total' => (float) $item->item_total,
                ];
            })
            ->values()
            ->all();

        return response()->json([
            'success' => true,
            'data' => [
                'order_id' => (int) $order->order_id,
                'buyer_userid' => (int) $order->buyer_userid,
                'customer_user_id' => (int) $order->buyer_userid,
                'short_datetime' => (string) $order->short_datetime,
                'order_state' => (string) $order->order_state,
                'payment_status' => (string) $order->payment_status,
                'payment_method' => (string) $order->payment_method,
                'remarks' => (string) ($order->feedback ?? ''),
                'items' => $items,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $attempts = 0;
        $orderId = null;

        while ($attempts < 3 && $orderId === null) {
            $attempts++;

            try {
                $result = DB::transaction(function () use ($validated): array {
                    $orderId = ((int) DB::table('orders')->max('order_id')) + 1;
                    $itemId = ((int) DB::table('orders_item')->max('item_id')) + 1;

                    $buyerUserId = (int) ($validated['buyer_userid'] ?? $validated['customer_user_id'] ?? 0);
                    $orderDate = (string) ($validated['order_date'] ?? now()->format('Y-m-d'));
                    $orderState = (string) ($validated['order_state'] ?? 'registered');
                    $paymentStatus = (string) ($validated['payment_status'] ?? 'not_paid');
                    $paymentMethod = (string) ($validated['payment_method'] ?? 'cod');
                    $remarks = trim((string) ($validated['remarks'] ?? ''));

                    $subtotal = 0.0;
                    foreach ($validated['items'] as $row) {
                        $qty = (int) $row['quantity'];
                        $price = (float) $row['item_price'];
                        $lineTotal = isset($row['item_total']) ? (float) $row['item_total'] : round($qty * $price, 2);
                        $subtotal += $lineTotal;
                    }
                    $subtotal = round($subtotal, 2);

                    DB::table('orders')->insert([
                        'order_id' => $orderId,
                        'bill_number' => null,
                        'master_order_id' => 0,
                        'txn_id' => 'SO-' . $orderId,
                        'buyer_userid' => $buyerUserId,
                        'start_time' => time(),
                        'last_update_time' => time(),
                        'short_datetime' => $orderDate,
                        'order_state' => $orderState,
                        'payment_method' => $paymentMethod,
                        'ctype_id' => 'vegetables_fruits',
                        'items_count' => count($validated['items']),
                        'delivery_charge' => 0,
                        'order_total' => $subtotal,
                        'bill_amount' => null,
                        'delivery_info' => '{}',
                        'area_name' => '',
                        'feedback' => $remarks,
                        'admin_id' => 0,
                        'payment_status' => $paymentStatus,
                        'amountReceivedInfo' => null,
                        'trip_id' => null,
                        'discount' => 0,
                        'before_discount' => $subtotal,
                        'time_slot' => 'Now',
                        'delivered_time' => null,
                        'deli_id' => null,
                    ]);

                    foreach ($validated['items'] as $row) {
                        $qty = (int) $row['quantity'];
                        $price = (float) $row['item_price'];
                        $lineTotal = isset($row['item_total']) ? (float) $row['item_total'] : round($qty * $price, 2);

                        DB::table('orders_item')->insert([
                            'order_id' => $orderId,
                            'item_id' => $itemId++,
                            'product_id' => (int) $row['product_id'],
                            'vendor_product_id' => $row['vendor_product_id'] ?? null,
                            'pinfo' => '',
                            'offers' => null,
                            'quantity' => $qty,
                            'qty_loaded' => (int) ($row['qty_loaded'] ?? 0),
                            'qty_delivered' => (int) ($row['qty_delivered'] ?? 0),
                            'qty_returned' => (int) ($row['qty_returned'] ?? 0),
                            'item_price' => $price,
                            'item_total' => $lineTotal,
                            'op_id' => 0,
                            'commission' => 0,
                        ]);
                    }

                    return ['order_id' => $orderId];
                });

                $orderId = (int) $result['order_id'];
            } catch (QueryException $e) {
                if (! $this->isDuplicateKeyException($e) || $attempts >= 3) {
                    throw $e;
                }
            }
        }

        return $this->show((int) $orderId);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $exists = DB::table('orders')->where('order_id', $id)->exists();
        if (! $exists) {
            return response()->json([
                'success' => false,
                'message' => 'Sales order not found',
            ], 404);
        }

        DB::transaction(function () use ($validated, $id): void {
            $buyerUserId = (int) ($validated['buyer_userid'] ?? $validated['customer_user_id'] ?? 0);
            $orderDate = (string) ($validated['order_date'] ?? now()->format('Y-m-d'));
            $orderState = (string) ($validated['order_state'] ?? 'registered');
            $paymentStatus = (string) ($validated['payment_status'] ?? 'not_paid');
            $paymentMethod = (string) ($validated['payment_method'] ?? 'cod');
            $remarks = trim((string) ($validated['remarks'] ?? ''));

            $subtotal = 0.0;
            foreach ($validated['items'] as $row) {
                $qty = (float) $row['quantity'];
                $price = (float) $row['item_price'];
                $lineTotal = isset($row['item_total']) ? (float) $row['item_total'] : round($qty * $price, 2);
                $subtotal += $lineTotal;
            }
            $subtotal = round($subtotal, 2);

            DB::table('orders')->where('order_id', $id)->update([
                'buyer_userid' => $buyerUserId,
                'short_datetime' => $orderDate,
                'order_state' => $orderState,
                'payment_method' => $paymentMethod,
                'items_count' => count($validated['items']),
                'order_total' => $subtotal,
                'feedback' => $remarks,
                'payment_status' => $paymentStatus,
                'before_discount' => $subtotal,
                'last_update_time' => time(),
            ]);

            $existingItems = DB::table('orders_item')
                ->where('order_id', $id)
                ->get()
                ->keyBy('item_id');

            $retainedItemIds = [];
            $itemId = ((int) DB::table('orders_item')->max('item_id')) + 1;
            foreach ($validated['items'] as $row) {
                $qty = (int) $row['quantity'];
                $price = (float) $row['item_price'];
                $lineTotal = isset($row['item_total']) ? (float) $row['item_total'] : round($qty * $price, 2);

                $requestedItemId = isset($row['item_id']) ? (int) $row['item_id'] : null;
                $targetItemId = ($requestedItemId !== null && $existingItems->has($requestedItemId))
                    ? $requestedItemId
                    : $itemId++;

                $payload = [
                    'order_id' => $id,
                    'item_id' => $targetItemId,
                    'product_id' => (int) $row['product_id'],
                    'vendor_product_id' => $row['vendor_product_id'] ?? null,
                    'pinfo' => '',
                    'offers' => null,
                    'quantity' => $qty,
                    'qty_loaded' => (int) ($row['qty_loaded'] ?? 0),
                    'qty_delivered' => (int) ($row['qty_delivered'] ?? 0),
                    'qty_returned' => (int) ($row['qty_returned'] ?? 0),
                    'item_price' => $price,
                    'item_total' => $lineTotal,
                    'op_id' => 0,
                    'commission' => 0,
                ];

                if ($existingItems->has($targetItemId)) {
                    DB::table('orders_item')
                        ->where('order_id', $id)
                        ->where('item_id', $targetItemId)
                        ->update($payload);
                } else {
                    DB::table('orders_item')->insert($payload);
                }

                $retainedItemIds[] = $targetItemId;
            }

            if (! empty($retainedItemIds)) {
                DB::table('orders_item')
                    ->where('order_id', $id)
                    ->whereNotIn('item_id', $retainedItemIds)
                    ->delete();
            }
        });

        return $this->show($id);
    }

    public function destroy(int $id): JsonResponse
    {
        DB::transaction(function () use ($id): void {
            DB::table('orders_item')->where('order_id', $id)->delete();
            DB::table('orders')->where('order_id', $id)->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Sales order deleted successfully',
        ]);
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'buyer_userid' => ['nullable', 'integer'],
            'customer_user_id' => ['nullable', 'integer'],
            'order_date' => ['nullable', 'date'],
            'order_state' => ['nullable', 'in:registered,dispatched,delivered,cancelled'],
            'payment_status' => ['nullable', 'in:not_paid,pending,partially_paid,paid'],
            'payment_method' => ['nullable', 'in:cod,online,bank'],
            'remarks' => ['nullable', 'string'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.item_id' => ['nullable', 'integer'],
            'items.*.product_id' => ['required', 'integer', 'exists:product,product_id'],
            'items.*.vendor_product_id' => ['nullable', 'integer'],
            'items.*.quantity' => ['required', 'integer', 'gt:0'],
            'items.*.qty_loaded' => ['nullable', 'integer', 'min:0'],
            'items.*.qty_delivered' => ['nullable', 'integer', 'min:0'],
            'items.*.qty_returned' => ['nullable', 'integer', 'min:0'],
            'items.*.item_price' => ['required', 'numeric', 'min:0'],
            'items.*.item_total' => ['nullable', 'numeric', 'min:0'],
        ]);
    }

    private function isDuplicateKeyException(QueryException $exception): bool
    {
        $sqlState = $exception->errorInfo[0] ?? null;
        return $sqlState === '23000';
    }
}
