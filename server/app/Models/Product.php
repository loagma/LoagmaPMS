<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     *
     * We map to the existing `product` table in the
     * `loagma_new` database (not the Laravel-created `products` table).
     */
    protected $table = 'product';

    /**
     * The primary key associated with the table.
     */
    protected $primaryKey = 'product_id';

    /**
     * Indicates if the IDs are auto-incrementing.
     *
     * The legacy `product` table uses externally-managed IDs.
     */
    public $incrementing = false;

    /**
     * The "type" of the primary key ID.
     */
    protected $keyType = 'int';

    /**
     * The model's default values for attributes.
     *
     * We don't manage timestamps on this legacy table.
     */
    public $timestamps = false;
}

