<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('purchase_returns', function (Blueprint $table): void {
            $table->dropForeign(['vendor_id']);
            $table->dropIndex('purchase_returns_vendor_id_index');
            $table->dropUnique('purchase_returns_vendor_id_doc_no_prefix_doc_no_number_unique');

            $table->renameColumn('vendor_id', 'supplier_id');
        });

        Schema::table('purchase_returns', function (Blueprint $table): void {
            $table->foreign('supplier_id')->references('id')->on('suppliers');
            $table->index('supplier_id');
            $table->unique(['supplier_id', 'doc_no_prefix', 'doc_no_number']);
        });
    }

    public function down(): void
    {
        Schema::table('purchase_returns', function (Blueprint $table): void {
            $table->dropForeign(['supplier_id']);
            $table->dropIndex('purchase_returns_supplier_id_index');
            $table->dropUnique('purchase_returns_supplier_id_doc_no_prefix_doc_no_number_unique');

            $table->renameColumn('supplier_id', 'vendor_id');
        });

        Schema::table('purchase_returns', function (Blueprint $table): void {
            $table->foreign('vendor_id')->references('id')->on('suppliers');
            $table->index('vendor_id');
            $table->unique(['vendor_id', 'doc_no_prefix', 'doc_no_number']);
        });
    }
};
