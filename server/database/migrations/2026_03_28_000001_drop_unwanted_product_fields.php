<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('product')) {
            return;
        }

        $columns = [
            'pack_name_6_char',
            'gst_product_type',
            'gst_itc_eligibility',
            'gst_uqc',
        ];

        foreach ($columns as $column) {
            if (Schema::hasColumn('product', $column)) {
                Schema::table('product', function (Blueprint $table) use ($column) {
                    $table->dropColumn($column);
                });
            }
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('product')) {
            return;
        }

        if (!Schema::hasColumn('product', 'pack_name_6_char')) {
            Schema::table('product', function (Blueprint $table) {
                $table->string('pack_name_6_char', 6)
                    ->nullable()
                    ->after('gross_wt_of_pack');
            });
        }

        if (!Schema::hasColumn('product', 'gst_product_type')) {
            Schema::table('product', function (Blueprint $table) {
                $table->string('gst_product_type', 50)
                    ->nullable()
                    ->after('pack_name_6_char');
            });
        }

        if (!Schema::hasColumn('product', 'gst_itc_eligibility')) {
            Schema::table('product', function (Blueprint $table) {
                $table->string('gst_itc_eligibility', 50)
                    ->nullable()
                    ->after('gst_tax_type');
            });
        }

        if (!Schema::hasColumn('product', 'gst_uqc')) {
            Schema::table('product', function (Blueprint $table) {
                $table->string('gst_uqc', 20)
                    ->nullable()
                    ->after('gst_itc_eligibility');
            });
        }
    }
};
