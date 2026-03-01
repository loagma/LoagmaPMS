<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseOrderItem extends Model
{
    protected $fillable = [
        'purchase_order_id',
        'product_id',
        'line_no',
        'unit',
        'quantity',
        'price',
        'discount_percent',
        'tax_percent',
        'line_total',
        'description',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'price' => 'decimal:2',
        'discount_percent' => 'decimal:2',
        'tax_percent' => 'decimal:2',
        'line_total' => 'decimal:2',
    ];

    /** Price is stored as excluding tax. Append computed price incl. tax and line total excl. tax. */
    protected $appends = ['price_incl_tax', 'line_total_excl_tax'];

    public function getPriceInclTaxAttribute(): float
    {
        $price = (float) ($this->attributes['price'] ?? 0);
        $taxPct = (float) ($this->attributes['tax_percent'] ?? 0);
        return round($price * (1 + $taxPct / 100), 2);
    }

    public function getLineTotalExclTaxAttribute(): float
    {
        $qty = (float) ($this->attributes['quantity'] ?? 0);
        $price = (float) ($this->attributes['price'] ?? 0);
        $discountPct = (float) ($this->attributes['discount_percent'] ?? 0);
        return round($qty * $price * (1 - $discountPct / 100), 2);
    }

    public function purchaseOrder()
    {
        return $this->belongsTo(PurchaseOrder::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id', 'product_id');
    }
}
