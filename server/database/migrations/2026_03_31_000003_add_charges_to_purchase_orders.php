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
        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->decimal('charges_total', 14, 2)->default(0)->after('total_amount');
            $table->json('charges_json')->nullable()->after('charges_total');
            $table->decimal('total_with_charges', 14, 2)->default(0)->after('charges_json');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->dropColumn(['charges_total', 'charges_json', 'total_with_charges']);
        });
    }
};
