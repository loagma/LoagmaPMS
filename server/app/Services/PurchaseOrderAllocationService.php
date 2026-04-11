<?php

namespace App\Services;

use App\Models\PurchaseOrder;
use App\Models\PurchaseOrderItem;
use App\Models\PurchaseVoucherItem;
use Illuminate\Support\Carbon;
use Illuminate\Validation\ValidationException;

class PurchaseOrderAllocationService
{
    /**
     * @param array<int, array<string, mixed>> $items
     * @return array{0: array<int, array<string, mixed>>, 1: array<int, int>}
     */
    public function prepareVoucherItems(
        array $items,
        int $vendorId,
        ?int $currentVoucherId = null,
        ?int $approvedByUserId = null
    ): array {
        $prepared = [];
        $touchedPoIds = [];

        foreach ($items as $index => $row) {
            $prepared[] = $this->prepareSingleItem(
                $row,
                $index,
                $vendorId,
                $currentVoucherId,
                $approvedByUserId,
                $touchedPoIds
            );
        }

        return [$prepared, array_values(array_unique($touchedPoIds))];
    }

    /**
     * @param array<string, mixed> $row
     * @param array<int, int> $touchedPoIds
     * @return array<string, mixed>
     */
    private function prepareSingleItem(
        array $row,
        int $index,
        int $vendorId,
        ?int $currentVoucherId,
        ?int $approvedByUserId,
        array &$touchedPoIds
    ): array {
        $line = $index + 1;

        $sourcePoId = isset($row['source_purchase_order_id'])
            ? (int) $row['source_purchase_order_id']
            : null;
        $sourcePoItemId = isset($row['source_purchase_order_item_id'])
            ? (int) $row['source_purchase_order_item_id']
            : null;

        if ($sourcePoId === null && $sourcePoItemId === null) {
            $row['overrun_qty'] = 0;
            $row['is_overrun_approved'] = false;
            $row['overrun_reason'] = $row['overrun_reason'] ?? null;
            $row['overrun_approved_by'] = null;
            $row['overrun_approved_at'] = null;
            return $row;
        }

        if ($sourcePoId === null || $sourcePoItemId === null) {
            throw ValidationException::withMessages([
                "items.$index.source_purchase_order_item_id" => [
                    "Line $line must include both source_purchase_order_id and source_purchase_order_item_id.",
                ],
            ]);
        }

        $poItem = PurchaseOrderItem::with('purchaseOrder')->find($sourcePoItemId);
        if (!$poItem || !$poItem->purchaseOrder) {
            throw ValidationException::withMessages([
                "items.$index.source_purchase_order_item_id" => ["Line $line has an invalid purchase order item reference."],
            ]);
        }

        if ((int) $poItem->purchase_order_id !== $sourcePoId) {
            throw ValidationException::withMessages([
                "items.$index.source_purchase_order_item_id" => [
                    "Line $line purchase order item does not belong to selected purchase order.",
                ],
            ]);
        }

        $po = $poItem->purchaseOrder;
        if ((int) $po->supplier_id !== $vendorId) {
            throw ValidationException::withMessages([
                "items.$index.source_purchase_order_id" => [
                    "Line $line purchase order supplier does not match voucher vendor.",
                ],
            ]);
        }

        $enteredQty = (float) ($row['quantity'] ?? 0);
        $orderedQty = (float) $poItem->quantity;
        $consumedQty = $this->consumedQtyForPoItem($poItem->id, $currentVoucherId);
        $leftQty = max(0, $orderedQty - $consumedQty);
        $overrunQty = max(0, $enteredQty - $leftQty);

        $isApproved = filter_var($row['is_overrun_approved'] ?? false, FILTER_VALIDATE_BOOL);

        if ($overrunQty > 0.0000001 && !$isApproved) {
            throw ValidationException::withMessages([
                "items.$index.quantity" => [
                    sprintf(
                        'Line %d exceeds linked PO quantity. Ordered %.3f, used %.3f, left %.3f, entered %.3f. Confirm override to continue.',
                        $line,
                        $orderedQty,
                        $consumedQty,
                        $leftQty,
                        $enteredQty
                    ),
                ],
            ]);
        }

        $row['source_purchase_order_id'] = $sourcePoId;
        $row['source_purchase_order_item_id'] = $sourcePoItemId;
        $row['source_po_number'] = $po->po_number;
        $row['overrun_qty'] = round($overrunQty, 3);
        $row['is_overrun_approved'] = $overrunQty > 0 ? $isApproved : false;
        $row['overrun_reason'] = isset($row['overrun_reason'])
            ? trim((string) $row['overrun_reason']) ?: null
            : null;
        $row['overrun_approved_by'] = ($overrunQty > 0 && $isApproved) ? $approvedByUserId : null;
        $row['overrun_approved_at'] = ($overrunQty > 0 && $isApproved)
            ? Carbon::now()->toDateTimeString()
            : null;

        $touchedPoIds[] = (int) $po->id;

        return $row;
    }

    public function consumedQtyForPoItem(int $poItemId, ?int $excludeVoucherId = null): float
    {
        $query = PurchaseVoucherItem::query()
            ->where('source_purchase_order_item_id', $poItemId)
            ->whereHas('purchaseVoucher', function ($q) use ($excludeVoucherId) {
                $q->whereIn('status', ['DRAFT', 'POSTED']);
                if ($excludeVoucherId) {
                    $q->where('id', '!=', $excludeVoucherId);
                }
            });

        return (float) $query->sum('quantity');
    }

    /**
     * @param array<int, int> $poIds
     */
    public function refreshPurchaseOrders(array $poIds): void
    {
        if (empty($poIds)) {
            return;
        }

        PurchaseOrder::with('items')
            ->whereIn('id', $poIds)
            ->get()
            ->each(function (PurchaseOrder $po): void {
                $this->refreshPurchaseOrder($po);
            });
    }

    public function refreshPurchaseOrder(PurchaseOrder $po): void
    {
        $items = $po->items;
        if ($items->isEmpty()) {
            return;
        }

        $fullyConsumed = true;
        $hasAnyConsumed = false;

        /** @var PurchaseOrderItem $item */
        foreach ($items as $item) {
            $consumed = $this->consumedQtyForPoItem((int) $item->id);
            $ordered = (float) $item->quantity;
            $remaining = max(0, $ordered - $consumed);

            $item->consumed_quantity = round($consumed, 3);
            $item->remaining_quantity = round($remaining, 3);
            $item->save();

            if ($consumed > 0.0000001) {
                $hasAnyConsumed = true;
            }
            if ($remaining > 0.0000001) {
                $fullyConsumed = false;
            }
        }

        if ($po->status === 'CANCELLED') {
            return;
        }

        $nextStatus = $po->status;
        if ($fullyConsumed) {
            $nextStatus = 'CLOSED';
        } elseif ($hasAnyConsumed) {
            $nextStatus = 'PARTIALLY_RECEIVED';
        }

        if ($nextStatus !== $po->status) {
            $po->status = $nextStatus;
            $po->save();
        }
    }
}
