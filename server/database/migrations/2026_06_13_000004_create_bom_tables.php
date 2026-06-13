<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Bill of Materials tables (bom_master, bom_items) used by BomController. They previously
 * existed only in docs/changes.sql, so a fresh `php artisan migrate` left them missing and
 * every BOM endpoint failed. Mirrors the changes.sql definition.
 *
 * The FK on bom_items.raw_material_id → product(product_id) from changes.sql is intentionally
 * omitted: `product` is a legacy CRM table whose column type/engine may not match, and the
 * app does not rely on a DB-level constraint there. Guarded so it is a no-op where the tables
 * already exist (e.g. applied earlier from changes.sql).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('bom_master')) {
            Schema::create('bom_master', function (Blueprint $table) {
                $table->bigIncrements('bom_id');
                $table->unsignedBigInteger('product_id');
                $table->string('bom_version', 20);
                $table->enum('status', ['DRAFT', 'APPROVED', 'LOCKED'])->default('DRAFT');
                $table->text('remarks')->nullable();
                $table->bigInteger('created_by')->nullable();
                $table->bigInteger('approved_by')->nullable();
                $table->timestamp('created_at')->useCurrent();
                $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
                $table->unique(['product_id', 'bom_version'], 'uk_product_version');
            });
        }

        if (!Schema::hasTable('bom_items')) {
            Schema::create('bom_items', function (Blueprint $table) {
                $table->bigIncrements('bom_item_id');
                $table->unsignedBigInteger('bom_id');
                $table->unsignedBigInteger('raw_material_id');
                $table->decimal('quantity_per_unit', 10, 3);
                $table->string('unit_type', 20);
                $table->decimal('wastage_percent', 5, 2)->default(0);
                $table->timestamp('created_at')->useCurrent();
                $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();
                $table->foreign('bom_id')->references('bom_id')->on('bom_master');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('bom_items');
        Schema::dropIfExists('bom_master');
    }
};
