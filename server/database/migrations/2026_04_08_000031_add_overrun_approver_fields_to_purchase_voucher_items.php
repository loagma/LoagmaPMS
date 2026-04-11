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
        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->unsignedBigInteger('overrun_approved_by')->nullable()->after('overrun_reason');
            $table->timestamp('overrun_approved_at')->nullable()->after('overrun_approved_by');
            $table->index('overrun_approved_by');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->dropIndex(['overrun_approved_by']);
            $table->dropColumn(['overrun_approved_by', 'overrun_approved_at']);
        });
    }
};
