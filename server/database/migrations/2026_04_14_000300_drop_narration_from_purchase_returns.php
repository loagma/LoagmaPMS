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
            if (Schema::hasColumn('purchase_returns', 'narration')) {
                $table->dropColumn('narration');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_returns', function (Blueprint $table): void {
            if (! Schema::hasColumn('purchase_returns', 'narration')) {
                $table->text('narration')->nullable()->after('reason');
            }
        });
    }
};