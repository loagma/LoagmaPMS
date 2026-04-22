<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class SalesReturnController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = DB::table('orders as o')
            ->whereExists(function ($q): void {
                $q->select(DB::raw(1))
                    ->from('orders_item as oi')
                    ->whereColumn('oi.order_id', 'o.order_id')
                    ->where('oi.qty_returned', '>', 0);
            })
            ->orderByDesc('o.order_id');

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $query->where(function ($q) use ($search): void {
                $q->where('o.order_id', $search)
                    ->orWhere('o.feedback', 'like', "%{$search}%");
            });
        }

        $rows = $query->paginate((int) $request->input('per_page', 25));

        $rows->getCollection()->transform(function ($row) {
            $refund = (float) DB::table('orders_item')
                ->where('order_id', $row->order_id)
                ->selectRaw('COALESCE(SUM(COALESCE(qty_returned,0) * item_price), 0) as refund')
                ->value('refund');

            $returnDate = $this->resolveReturnDate($row->last_update_time ?? null, $row->short_datetime ?? null);

            return [
                'id' => (int) $row->order_id,
                'order_id' => (int) $row->order_id,
                'return_date' => $returnDate,
                'return_status' => 'POSTED',
                'reason' => null,
                'total_refund' => round($refund, 2),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $rows,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $order = DB::table('orders')->where('order_id', $id)->first();
        if (! $order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found',
            ], 404);
        }

        $items = DB::table('orders_item')
            ->where('order_id', $id)
            ->where('qty_returned', '>', 0)
            ->orderBy('item_id')
            ->get()
            ->map(function ($item): array {
                $returnQty = (float) ($item->qty_returned ?? 0);
                return [
                    'item_id' => (int) $item->item_id,
                    'product_id' => (int) $item->product_id,
                    'original_qty' => (float) $item->quantity,
                    'return_qty' => $returnQty,
                    'refund_amount' => round($returnQty * (float) $item->item_price, 2),
                    'reason' => null,
                ];
            })
            ->values()
            ->all();

        $totalReturned = array_reduce($items, fn ($sum, $i) => $sum + ((float) $i['return_qty']), 0.0);
        $totalRefund = array_reduce($items, fn ($sum, $i) => $sum + ((float) $i['refund_amount']), 0.0);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => (int) $order->order_id,
                'order_id' => (int) $order->order_id,
                'return_date' => $this->resolveReturnDate($order->last_update_time ?? null, $order->short_datetime ?? null),
                'return_status' => $totalReturned > 0 ? 'POSTED' : 'DRAFT',
                'reason' => null,
                'total_refund' => round($totalRefund, 2),
                'items' => $items,
            ],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $this->applyReturn($validated, (int) $validated['order_id']);

        return $this->show((int) $validated['order_id']);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $orderId = (int) ($validated['order_id'] ?? $id);
        if ($orderId !== $id) {
            return response()->json([
                'success' => false,
                'message' => 'Order ID mismatch in return update',
            ], 422);
        }

        $this->applyReturn($validated, $orderId);

        return $this->show($orderId);
    }

    public function destroy(int $id): JsonResponse
    {
        $exists = DB::table('orders')->where('order_id', $id)->exists();
        if (! $exists) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found',
            ], 404);
        }

        DB::transaction(function () use ($id): void {
            DB::table('orders_item')->where('order_id', $id)->update(['qty_returned' => 0]);
            DB::table('orders')->where('order_id', $id)->update([
                'last_update_time' => time(),
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Sales return reset successfully',
        ]);
    }

    private function validatePayload(Request $request): array
    {
        return $request->validate([
            'order_id' => ['required', 'integer', 'exists:orders,order_id'],
            'return_date' => ['required', 'date'],
            'return_status' => ['nullable', 'in:DRAFT,POSTED,CANCELLED'],
            'reason' => ['nullable', 'string'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.item_id' => ['nullable', 'integer'],
            'items.*.product_id' => ['required', 'integer', 'exists:product,product_id'],
            'items.*.original_qty' => ['required', 'numeric', 'min:0'],
            'items.*.return_qty' => ['required', 'integer', 'min:0'],
            'items.*.refund_amount' => ['nullable', 'numeric', 'min:0'],
            'items.*.reason' => ['nullable', 'string', 'max:255'],
        ]);
    }

    private function applyReturn(array $validated, int $orderId): void
    {
        DB::transaction(function () use ($validated, $orderId): void {
            foreach ($validated['items'] as $line) {
                $productId = (int) $line['product_id'];
                $returnQty = (int) $line['return_qty'];

                $itemId = isset($line['item_id']) ? (int) $line['item_id'] : null;

                if ($itemId !== null) {
                    $item = DB::table('orders_item')
                        ->where('order_id', $orderId)
                        ->where('item_id', $itemId)
                        ->where('product_id', $productId)
                        ->first();
                } else {
                    $matchingItems = DB::table('orders_item')
                        ->where('order_id', $orderId)
                        ->where('product_id', $productId)
                        ->get();

                    if ($matchingItems->count() > 1) {
                        throw ValidationException::withMessages([
                            'items' => ["Multiple order items found for product {$productId}. Pass item_id for this line."],
                        ]);
                    }

                    $item = $matchingItems->first();
                }

                if (! $item) {
                    throw ValidationException::withMessages([
                        'items' => ["Order item not found for product {$productId}"],
                    ]);
                }

                $originalQty = (float) $item->quantity;
                if ($returnQty > $originalQty) {
                    throw ValidationException::withMessages([
                        'items' => ["Return quantity cannot exceed ordered quantity for product {$productId}"],
                    ]);
                }

                DB::table('orders_item')
                    ->where('order_id', $orderId)
                    ->where('item_id', (int) $item->item_id)
                    ->update(['qty_returned' => $returnQty]);
            }

            DB::table('orders')->where('order_id', $orderId)->update([
                'last_update_time' => time(),
            ]);
        });
    }

    private function resolveReturnDate(mixed $lastUpdateTime, mixed $fallbackDate): string
    {
        $timestamp = is_numeric($lastUpdateTime) ? (int) $lastUpdateTime : 0;
        if ($timestamp > 0) {
            return date('Y-m-d', $timestamp);
        }

        if (is_string($fallbackDate) && trim($fallbackDate) !== '') {
            return (string) $fallbackDate;
        }

        return now()->format('Y-m-d');
    }
}
