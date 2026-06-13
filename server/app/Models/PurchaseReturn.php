<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseReturn extends Model
{
    protected $fillable = [
        'doc_no_prefix',
        'doc_no_number',
        'doc_no',
        'source_purchase_voucher_id',
        'supplier_id',
        'doc_date',
        'reason',
        'status',
        'items_total',
        'charges_total',
        'net_total',
        'charges_json',
        'created_by',
        'updated_by',
        'idempotency_key',
    ];

    protected $casts = [
        'doc_no_number' => 'integer',
        'source_purchase_voucher_id' => 'integer',
        'supplier_id' => 'integer',
        'doc_date' => 'date',
        'items_total' => 'decimal:2',
        'charges_total' => 'decimal:2',
        'net_total' => 'decimal:2',
        'charges_json' => 'array',
    ];

    protected $appends = ['vendor_name'];

    public function vendor()
    {
        return $this->belongsTo(Supplier::class, 'supplier_id');
    }

    public function sourcePurchaseVoucher()
    {
        return $this->belongsTo(PurchaseVoucher::class, 'source_purchase_voucher_id');
    }

    public function items()
    {
        return $this->hasMany(PurchaseReturnItem::class)->orderBy('line_no');
    }

    public function getVendorNameAttribute(): string
    {
        return $this->vendor?->supplier_name ?? '';
    }
}
