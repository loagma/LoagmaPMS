<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    /**
     * Use the legacy `product` table from schema.sql.
     */
    protected $table = 'product';

    /**
     * Primary key column name.
     */
    protected $primaryKey = 'product_id';

    /**
     * The "type" of the primary key ID.
     */
    protected $keyType = 'int';

    /**
     * The primary key is not auto-incrementing in this legacy table.
     */
    public $incrementing = false;

    /**
     * Legacy table does not have Laravel timestamps.
     */
    public $timestamps = false;
}

