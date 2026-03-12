<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds HSN codes master table and per-product order/buffer limits.
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('hsn_codes')) {
            Schema::create('hsn_codes', function (Blueprint $table) {
                $table->id();
                $table->string('hsn_code', 50);
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }

        if (Schema::hasTable('product')) {
            if (! Schema::hasColumn('product', 'order_limit')) {
                Schema::table('product', function (Blueprint $table) {
                    $table->unsignedInteger('order_limit')
                        ->default(0)
                        ->after('stock_ut_id');
                });
            }

            if (! Schema::hasColumn('product', 'buffer_limit')) {
                Schema::table('product', function (Blueprint $table) {
                    $table->unsignedInteger('buffer_limit')
                        ->default(0)
                        ->after('order_limit');
                });
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('product')) {
            if (Schema::hasColumn('product', 'buffer_limit')) {
                Schema::table('product', function (Blueprint $table) {
                    $table->dropColumn('buffer_limit');
                });
            }

            if (Schema::hasColumn('product', 'order_limit')) {
                Schema::table('product', function (Blueprint $table) {
                    $table->dropColumn('order_limit');
                });
            }
        }

        Schema::dropIfExists('hsn_codes');
    }
};

