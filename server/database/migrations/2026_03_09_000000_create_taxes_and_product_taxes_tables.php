<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Creates taxes master table and product_taxes pivot table.
 * taxes: tax categories (e.g. GST, SGST, CGST, IGST, Cess).
 * product_taxes: links products to taxes with percentage (many-to-many).
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('taxes', function (Blueprint $table) {
            $table->id();
            $table->string('tax_category', 100);
            $table->string('tax_sub_category', 100);
            $table->string('tax_name', 150);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['tax_category', 'tax_sub_category']);
        });

        Schema::create('product_taxes', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('product_id');
            $table->unsignedBigInteger('tax_id');
            $table->decimal('tax_percent', 5, 2);

            $table->timestamps();

            $table->foreign('product_id')
                ->references('product_id')
                ->on('product')
                ->onDelete('cascade');

            $table->foreign('tax_id')
                ->references('id')
                ->on('taxes')
                ->onDelete('cascade');

            $table->unique(['product_id', 'tax_id']);
            $table->index('product_id');
            $table->index('tax_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('product_taxes');
        Schema::dropIfExists('taxes');
    }
};
