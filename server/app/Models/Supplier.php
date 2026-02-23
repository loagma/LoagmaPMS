<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Supplier extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'supplier_code',
        'supplier_name',
        'short_name',
        'business_type',
        'department',
        'gst_no',
        'pan_no',
        'tan_no',
        'cin_no',
        'vat_no',
        'registration_no',
        'fssai_no',
        'website',
        'email',
        'phone',
        'alternate_phone',
        'contact_person',
        'contact_person_email',
        'contact_person_phone',
        'contact_person_designation',
        'address_line1',
        'city',
        'state',
        'country',
        'pincode',
        'bank_name',
        'bank_branch',
        'bank_account_name',
        'bank_account_number',
        'ifsc_code',
        'swift_code',
        'payment_terms_days',
        'credit_limit',
        'rating',
        'is_preferred',
        'status',
        'notes',
        'metadata',
        'created_by',
        'updated_by',
    ];

    protected $casts = [
        'is_preferred' => 'boolean',
        'metadata' => 'array',
        'credit_limit' => 'decimal:2',
        'rating' => 'decimal:2',
        'payment_terms_days' => 'integer',
    ];

    public function supplierProducts()
    {
        return $this->hasMany(SupplierProduct::class);
    }

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($supplier) {
            if (empty($supplier->supplier_code)) {
                $supplier->supplier_code = static::generateSupplierCode();
            }
        });
    }

    public static function generateSupplierCode(): string
    {
        $lastSupplier = static::withTrashed()
            ->orderBy('id', 'desc')
            ->first();

        if (!$lastSupplier) {
            return 'sup-1';
        }

        // Extract number from code like "sup-1" or "sup-123"
        if (preg_match('/sup-(\d+)/', $lastSupplier->supplier_code, $matches)) {
            $lastNumber = (int) $matches[1];
            return 'sup-' . ($lastNumber + 1);
        }

        // Fallback if pattern doesn't match
        return 'sup-' . ($lastSupplier->id + 1);
    }
}
