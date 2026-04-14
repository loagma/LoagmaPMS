<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseReturnItem extends Model
{
    protected $fillable = [
        'purchase_return_id',
        'source_purchase_voucher_item_id',
        'product_id',
        'line_no',
        'product_name',
        'product_code',
        'alias',
        'unit',
        'original_quantity',
        'returned_quantity',
        'unit_price',
        'taxable_amount',
        'sgst',
        'cgst',
        'igst',
        'cess',
        'roff',
        'value',
        'return_reason',
        'remarks',
    ];

    protected $casts = [
        'purchase_return_id' => 'integer',
        'source_purchase_voucher_item_id' => 'integer',
        'product_id' => 'integer',
        'line_no' => 'integer',
        'original_quantity' => 'decimal:3',
        'returned_quantity' => 'decimal:3',
        'unit_price' => 'decimal:2',
        'taxable_amount' => 'decimal:2',
        'sgst' => 'decimal:2',
        'cgst' => 'decimal:2',
        'igst' => 'decimal:2',
        'cess' => 'decimal:2',
        'roff' => 'decimal:2',
        'value' => 'decimal:2',
    ];

    public function purchaseReturn()
    {
        return $this->belongsTo(PurchaseReturn::class);
    }

    public function sourcePurchaseVoucherItem()
    {
        return $this->belongsTo(PurchaseVoucherItem::class, 'source_purchase_voucher_item_id');
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }
}
