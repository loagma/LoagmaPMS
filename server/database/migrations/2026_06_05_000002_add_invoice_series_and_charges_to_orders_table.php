<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            // Tracks the sequential invoice number within a prefix — used for lock-based generation
            if (!Schema::connection('mysql')->hasColumn('orders', 'invoice_number')) {
                $table->unsignedInteger('invoice_number')->nullable()->after('bill_no');
            }
            // Stores charges (freight, handling, etc.) as JSON so they survive re-opens
            if (!Schema::connection('mysql')->hasColumn('orders', 'charges_json')) {
                $table->json('charges_json')->nullable()->after('invoice_number');
            }
        });
    }

    public function down(): void
    {
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            $table->dropColumn(['invoice_number', 'charges_json']);
        });
    }
};
