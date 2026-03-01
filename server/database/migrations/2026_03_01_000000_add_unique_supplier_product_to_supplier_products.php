<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Enforce at DB level: one product can be assigned only once per supplier.
 * One supplier can still have multiple products (many rows per supplier_id).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('supplier_products', function (Blueprint $table) {
            $table->dropIndex(['supplier_id', 'product_id']);
        });
        Schema::table('supplier_products', function (Blueprint $table) {
            $table->unique(['supplier_id', 'product_id']);
        });
    }

    public function down(): void
    {
        Schema::table('supplier_products', function (Blueprint $table) {
            $table->dropUnique(['supplier_id', 'product_id']);
        });
        Schema::table('supplier_products', function (Blueprint $table) {
            $table->index(['supplier_id', 'product_id']);
        });
    }
};
