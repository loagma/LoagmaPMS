<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PurchaseOrder extends Model
{
    protected $fillable = [
        'po_number',
        'financial_year',
        'supplier_id',
        'doc_date',
        'expected_date',
        'status',
        'narration',
        'total_amount',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'doc_date' => 'date',
        'expected_date' => 'date',
        'total_amount' => 'decimal:2',
    ];

    public function supplier()
    {
        return $this->belongsTo(Supplier::class);
    }

    public function items()
    {
        return $this->hasMany(PurchaseOrderItem::class)->orderBy('line_no');
    }
}
