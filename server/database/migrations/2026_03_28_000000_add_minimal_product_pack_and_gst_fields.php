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

        if (!Schema::hasColumn('product', 'product_pack_count')) {
            Schema::table('product', function (Blueprint $table) {
                $table->unsignedInteger('product_pack_count')
                    ->default(0)
                    ->after('buffer_limit');
            });
        }

        if (!Schema::hasColumn('product', 'nop')) {
            Schema::table('product', function (Blueprint $table) {
                $table->unsignedInteger('nop')
                    ->default(0)
                    ->after('product_pack_count');
            });
        }

        if (!Schema::hasColumn('product', 'pack_prd_wt')) {
            Schema::table('product', function (Blueprint $table) {
                $table->decimal('pack_prd_wt', 12, 3)
                    ->nullable()
                    ->after('nop');
            });
        }

        if (!Schema::hasColumn('product', 'gross_wt_of_pack')) {
            Schema::table('product', function (Blueprint $table) {
                $table->decimal('gross_wt_of_pack', 12, 3)
                    ->nullable()
                    ->after('pack_prd_wt');
            });
        }

        if (!Schema::hasColumn('product', 'gst_tax_type')) {
            Schema::table('product', function (Blueprint $table) {
                $table->string('gst_tax_type', 50)
                    ->nullable()
                    ->after('gross_wt_of_pack');
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasTable('product')) {
            return;
        }

        $columns = [
            'gst_tax_type',
            'gross_wt_of_pack',
            'pack_prd_wt',
            'nop',
            'product_pack_count',
        ];

        foreach ($columns as $column) {
            if (Schema::hasColumn('product', $column)) {
                Schema::table('product', function (Blueprint $table) use ($column) {
                    $table->dropColumn($column);
                });
            }
        }
    }
};
