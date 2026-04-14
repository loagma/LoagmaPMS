<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('purchase_returns', function (Blueprint $table): void {
            $table->dropUnique('purchase_returns_doc_no_prefix_doc_no_number_unique');
            $table->unique(['vendor_id', 'doc_no_prefix', 'doc_no_number']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_returns', function (Blueprint $table): void {
            $table->dropUnique('purchase_returns_vendor_id_doc_no_prefix_doc_no_number_unique');
            $table->unique(['doc_no_prefix', 'doc_no_number']);
        });
    }
};