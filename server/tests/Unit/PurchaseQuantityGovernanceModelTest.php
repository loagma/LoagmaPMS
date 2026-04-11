<?php

namespace Tests\Unit;

use App\Models\PurchaseOrderItem;
use App\Models\PurchaseVoucherItem;
use PHPUnit\Framework\TestCase;

class PurchaseQuantityGovernanceModelTest extends TestCase
{
    public function test_purchase_order_item_used_and_left_accessors(): void
    {
        $item = new PurchaseOrderItem([
            'quantity' => 10,
            'consumed_quantity' => 4,
            'remaining_quantity' => 6,
        ]);

        $this->assertSame(4.0, $item->used_qty);
        $this->assertSame(6.0, $item->left_qty);
    }

    public function test_purchase_voucher_item_supports_overrun_audit_fields(): void
    {
        $item = new PurchaseVoucherItem();

        $this->assertContains('overrun_qty', $item->getFillable());
        $this->assertContains('is_overrun_approved', $item->getFillable());
        $this->assertContains('overrun_reason', $item->getFillable());
        $this->assertContains('overrun_approved_by', $item->getFillable());
        $this->assertContains('overrun_approved_at', $item->getFillable());

        $casts = $item->getCasts();
        $this->assertSame('boolean', $casts['is_overrun_approved']);
        $this->assertSame('integer', $casts['overrun_approved_by']);
        $this->assertSame('datetime', $casts['overrun_approved_at']);
    }
}
