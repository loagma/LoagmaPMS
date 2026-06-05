<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_vouchers', function (Blueprint $table): void {
            $table->dropForeign(['vendor_id']);
            $table->dropIndex('purchase_vouchers_vendor_id_index');

            $table->renameColumn('vendor_id', 'supplier_id');
        });

        Schema::table('purchase_vouchers', function (Blueprint $table): void {
            $table->foreign('supplier_id')->references('id')->on('suppliers');
            $table->index('supplier_id');
        });
    }

    public function down(): void
    {
        Schema::table('purchase_vouchers', function (Blueprint $table): void {
            $table->dropForeign(['supplier_id']);
            $table->dropIndex('purchase_vouchers_supplier_id_index');

            $table->renameColumn('supplier_id', 'vendor_id');
        });

        Schema::table('purchase_vouchers', function (Blueprint $table): void {
            $table->foreign('vendor_id')->references('id')->on('suppliers');
            $table->index('vendor_id');
        });
    }
};
