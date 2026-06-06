<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            if (!Schema::connection('mysql')->hasColumn('orders', 'invoice_pdf_url')) {
                $table->string('invoice_pdf_url', 500)->nullable()->after('charges_json');
            }
        });
    }

    public function down(): void
    {
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            if (Schema::connection('mysql')->hasColumn('orders', 'invoice_pdf_url')) {
                $table->dropColumn('invoice_pdf_url');
            }
        });
    }
};
