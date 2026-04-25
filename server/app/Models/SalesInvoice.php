<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SalesInvoice extends Model
{
    protected $table = 'sales_invoices';

    protected $fillable = [
        'doc_no_prefix',
        'doc_no_number',
        'doc_no',
        'customer_id',
        'customer_name',
        'doc_date',
        'bill_no',
        'bill_date',
        'narration',
        'do_not_update_inventory',
        'sale_type',
        'status',
        'items_total',
        'charges_total',
        'net_total',
        'charges_json',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'charges_json'             => 'array',
        'do_not_update_inventory'  => 'boolean',
        'doc_date'                 => 'date:Y-m-d',
        'bill_date'                => 'date:Y-m-d',
        'items_total'              => 'decimal:2',
        'charges_total'            => 'decimal:2',
        'net_total'                => 'decimal:2',
    ];

    public function items(): HasMany
    {
        return $this->hasMany(SalesInvoiceItem::class, 'sales_invoice_id')->orderBy('line_no');
    }
}
