<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseVoucherItem extends Model
{
    protected $fillable = [
        'purchase_voucher_id',
        'source_purchase_order_id',
        'source_purchase_order_item_id',
        'source_po_number',
        'product_id',
        'line_no',
        'product_name',
        'product_code',
        'hsn_code',
        'alias',
        'unit',
        'quantity',
        'overrun_qty',
        'writeoff_qty',
        'is_overrun_approved',
        'is_writeoff',
        'overrun_reason',
        'writeoff_reason',
        'overrun_approved_by',
        'overrun_approved_at',
        'unit_price',
        'taxable_amount',
        'sgst',
        'cgst',
        'igst',
        'cess',
        'roff',
        'value',
        'purchase_account',
        'gst_itc_eligibility',
    ];

    protected $casts = [
        'source_purchase_order_id' => 'integer',
        'source_purchase_order_item_id' => 'integer',
        'line_no' => 'integer',
        'quantity' => 'decimal:3',
        'overrun_qty' => 'decimal:3',
        'writeoff_qty' => 'decimal:3',
        'is_overrun_approved' => 'boolean',
        'is_writeoff' => 'boolean',
        'overrun_approved_by' => 'integer',
        'overrun_approved_at' => 'datetime',
        'unit_price' => 'decimal:2',
        'taxable_amount' => 'decimal:2',
        'sgst' => 'decimal:2',
        'cgst' => 'decimal:2',
        'igst' => 'decimal:2',
        'cess' => 'decimal:2',
        'roff' => 'decimal:2',
        'value' => 'decimal:2',
    ];

    public function purchaseVoucher()
    {
        return $this->belongsTo(PurchaseVoucher::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }

    public function purchaseOrderItem()
    {
        return $this->belongsTo(PurchaseOrderItem::class, 'source_purchase_order_item_id');
    }
}
