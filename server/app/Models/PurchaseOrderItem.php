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
        'hsn_code',
        'quantity',
        'consumed_quantity',
        'written_off_quantity',
        'remaining_quantity',
        'price',
        'discount_percent',
        'tax_percent',
        'line_total',
        'description',
    ];

    protected $casts = [
        'quantity' => 'decimal:3',
        'consumed_quantity' => 'decimal:3',
        'written_off_quantity' => 'decimal:3',
        'remaining_quantity' => 'decimal:3',
        'price' => 'decimal:2',
        'discount_percent' => 'decimal:2',
        'tax_percent' => 'decimal:2',
        'line_total' => 'decimal:2',
    ];

    /** Price is stored as excluding tax. Append computed price incl. tax and line total excl. tax. */
    protected $appends = ['price_incl_tax', 'line_total_excl_tax', 'used_qty', 'writeoff_qty', 'left_qty'];

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

    public function voucherItems()
    {
        return $this->hasMany(PurchaseVoucherItem::class, 'source_purchase_order_item_id');
    }

    public function getUsedQtyAttribute(): float
    {
        return round((float) ($this->attributes['consumed_quantity'] ?? 0), 3);
    }

    public function getWriteoffQtyAttribute(): float
    {
        return round((float) ($this->attributes['written_off_quantity'] ?? 0), 3);
    }

    public function getLeftQtyAttribute(): float
    {
        if (array_key_exists('remaining_quantity', $this->attributes)) {
            return round(max(0, (float) ($this->attributes['remaining_quantity'] ?? 0)), 3);
        }

        return round(max(0, (float) ($this->attributes['quantity'] ?? 0) - (float) ($this->attributes['consumed_quantity'] ?? 0)), 3);
    }
}
