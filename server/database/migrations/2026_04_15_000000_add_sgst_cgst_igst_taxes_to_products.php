<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds three GST taxes (SGST 2.5%, CGST 2.5%, IGST 5%) and assigns them to all existing products.
     */
    public function up(): void
    {
        $now = now();

        $taxes = [
            [
                'tax_category' => 'GST',
                'tax_sub_category' => 'State GST',
                'tax_name' => 'SGST',
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'tax_category' => 'GST',
                'tax_sub_category' => 'Central GST',
                'tax_name' => 'CGST',
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
            [
                'tax_category' => 'GST',
                'tax_sub_category' => 'Integrated GST',
                'tax_name' => 'IGST',
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ],
        ];

        foreach ($taxes as $tax) {
            DB::table('taxes')->updateOrInsert(
                ['tax_name' => $tax['tax_name']],
                $tax
            );
        }

        $taxIds = DB::table('taxes')
            ->whereIn('tax_name', ['SGST', 'CGST', 'IGST'])
            ->pluck('id', 'tax_name')
            ->toArray();

        $taxMap = [
            ['id' => $taxIds['SGST'] ?? null, 'percent' => 2.5],
            ['id' => $taxIds['CGST'] ?? null, 'percent' => 2.5],
            ['id' => $taxIds['IGST'] ?? null, 'percent' => 5.0],
        ];

        $taxMap = array_values(array_filter($taxMap, fn ($tax) => $tax['id'] !== null));

        if (empty($taxMap)) {
            return;
        }

        // Process products in chunks to avoid long-running transactions and connection drops.
        DB::table('product')
            ->select('product_id')
            ->orderBy('product_id')
            ->chunkById(500, function ($products) use ($taxMap, $now) {
                $rows = [];

                foreach ($products as $product) {
                    foreach ($taxMap as $tax) {
                        $rows[] = [
                            'product_id' => $product->product_id,
                            'tax_id' => $tax['id'],
                            'tax_percent' => $tax['percent'],
                            'created_at' => $now,
                            'updated_at' => $now,
                        ];
                    }
                }

                if (!empty($rows)) {
                    DB::table('product_taxes')->upsert(
                        $rows,
                        ['product_id', 'tax_id'],
                        ['tax_percent', 'updated_at']
                    );
                }
            }, 'product_id', 'product_id');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $taxIds = DB::table('taxes')
            ->whereIn('tax_name', ['SGST', 'CGST', 'IGST'])
            ->pluck('id')
            ->toArray();

        if (!empty($taxIds)) {
            DB::table('product_taxes')
                ->whereIn('tax_id', $taxIds)
                ->delete();
        }

        DB::table('taxes')
            ->whereIn('tax_name', ['SGST', 'CGST', 'IGST'])
            ->delete();
    }
};
