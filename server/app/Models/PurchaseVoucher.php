<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseVoucher extends Model
{
    protected $fillable = [
        'doc_no_prefix',
        'doc_no_number',
        'doc_no',
        'vendor_id',
        'purchase_order_id',
        'doc_date',
        'bill_no',
        'bill_date',
        'narration',
        'do_not_update_inventory',
        'purchase_type',
        'gst_reverse_charge',
        'purchase_agent_id',
        'status',
        'items_total',
        'charges_total',
        'net_total',
        'charges_json',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'doc_no_number' => 'integer',
        'doc_date' => 'date',
        'bill_date' => 'date',
        'do_not_update_inventory' => 'boolean',
        'items_total' => 'decimal:2',
        'charges_total' => 'decimal:2',
        'net_total' => 'decimal:2',
        'charges_json' => 'array',
    ];

    protected $appends = ['supplier_name', 'vendor_name'];

    public function vendor()
    {
        return $this->belongsTo(Supplier::class, 'vendor_id');
    }

    public function items()
    {
        return $this->hasMany(PurchaseVoucherItem::class)->orderBy('line_no');
    }

    public function purchaseOrder()
    {
        return $this->belongsTo(PurchaseOrder::class);
    }

    public function getSupplierNameAttribute(): string
    {
        return $this->vendor?->supplier_name ?? '';
    }

    public function getVendorNameAttribute(): string
    {
        return $this->vendor?->supplier_name ?? '';
    }
}
