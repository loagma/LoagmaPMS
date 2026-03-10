<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tax extends Model
{
    protected $fillable = [
        'tax_category',
        'tax_sub_category',
        'tax_name',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function products()
    {
        return $this->belongsToMany(Product::class, 'product_taxes')
            ->withPivot('tax_percent')
            ->withTimestamps();
    }

    public function productTaxes()
    {
        return $this->hasMany(ProductTax::class);
    }
}
