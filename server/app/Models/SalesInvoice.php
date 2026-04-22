<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SalesInvoice extends Model
{
    protected $fillable = [
        'invoice_no',
        'order_id',
        'customer_user_id',
        'invoice_date',
        'due_date',
        'invoice_status',
        'payment_status',
        'subtotal',
        'discount_total',
        'delivery_charge',
        'tax_total',
        'grand_total',
        'notes',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'invoice_date' => 'date',
        'due_date' => 'date',
        'subtotal' => 'decimal:2',
        'discount_total' => 'decimal:2',
        'delivery_charge' => 'decimal:2',
        'tax_total' => 'decimal:2',
        'grand_total' => 'decimal:2',
    ];
}
