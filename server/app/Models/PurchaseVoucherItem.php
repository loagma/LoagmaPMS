<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseVoucherItem extends Model
{
    protected $fillable = [
        'purchase_voucher_id',
        'source_purchase_order_id',
        'source_po_number',
        'product_id',
        'line_no',
        'product_name',
        'product_code',
        'alias',
        'unit',
        'quantity',
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
        'line_no' => 'integer',
        'quantity' => 'decimal:3',
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
}
