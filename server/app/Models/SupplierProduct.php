<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SupplierProduct extends Model
{
    protected $fillable = [
        'supplier_id',
        'product_id',
        'supplier_sku',
        'supplier_product_name',
        'description',
        'pack_size',
        'pack_unit',
        'min_order_qty',
        'price',
        'currency',
        'tax_percent',
        'discount_percent',
        'lead_time_days',
        'last_purchase_price',
        'last_purchase_date',
        'is_preferred',
        'is_active',
        'notes',
        'metadata',
    ];

    protected $casts = [
        'is_preferred' => 'boolean',
        'is_active' => 'boolean',
        'metadata' => 'array',
        'pack_size' => 'decimal:3',
        'min_order_qty' => 'decimal:3',
        'price' => 'decimal:2',
        'tax_percent' => 'decimal:2',
        'discount_percent' => 'decimal:2',
        'last_purchase_price' => 'decimal:2',
        'last_purchase_date' => 'date',
        'lead_time_days' => 'integer',
    ];

    public function supplier()
    {
        return $this->belongsTo(Supplier::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }
}
