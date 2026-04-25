<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SalesInvoiceItem extends Model
{
    protected $table = 'sales_invoice_items';

    protected $fillable = [
        'sales_invoice_id',
        'source_sales_order_id',
        'source_sales_order_item_id',
        'source_so_number',
        'product_id',
        'product_name',
        'product_code',
        'alias',
        'unit',
        'pack_id',
        'pack_label',
        'hsn_code',
        'line_no',
        'quantity',
        'ordered_qty',
        'used_qty',
        'left_qty',
        'overrun_qty',
        'writeoff_qty',
        'is_overrun_approved',
        'is_writeoff',
        'overrun_reason',
        'writeoff_reason',
        'unit_price',
        'taxable_amount',
        'sgst',
        'cgst',
        'igst',
        'cess',
        'roff',
        'value',
        'sale_account_id',
        'gst_applicability',
    ];

    protected $casts = [
        'is_overrun_approved' => 'boolean',
        'is_writeoff'         => 'boolean',
    ];

    public function salesInvoice(): BelongsTo
    {
        return $this->belongsTo(SalesInvoice::class, 'sales_invoice_id');
    }
}
