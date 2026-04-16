<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Normalize GST taxes to one canonical SGST/CGST/IGST set
     * and remove duplicate legacy product-tax mappings.
     */
    public function up(): void
    {
        DB::transaction(function (): void {
            $now = now();

            $canonicalTaxes = [
                'SGST' => [
                    'tax_category' => 'GST',
                    'tax_sub_category' => 'State GST',
                    'tax_percent' => 2.50,
                ],
                'CGST' => [
                    'tax_category' => 'GST',
                    'tax_sub_category' => 'Central GST',
                    'tax_percent' => 2.50,
                ],
                'IGST' => [
                    'tax_category' => 'GST',
                    'tax_sub_category' => 'Integrated GST',
                    'tax_percent' => 5.00,
                ],
            ];

            $canonicalTaxIds = [];

            foreach ($canonicalTaxes as $taxName => $meta) {
                $canonicalTaxId = DB::table('taxes')
                    ->where('tax_name', $taxName)
                    ->where('tax_category', $meta['tax_category'])
                    ->where('tax_sub_category', $meta['tax_sub_category'])
                    ->orderBy('id')
                    ->value('id');

                if (!$canonicalTaxId) {
                    $canonicalTaxId = DB::table('taxes')->insertGetId([
                        'tax_category' => $meta['tax_category'],
                        'tax_sub_category' => $meta['tax_sub_category'],
                        'tax_name' => $taxName,
                        'is_active' => true,
                        'created_at' => $now,
                        'updated_at' => $now,
                    ]);
                } else {
                    DB::table('taxes')
                        ->where('id', $canonicalTaxId)
                        ->update([
                            'tax_category' => $meta['tax_category'],
                            'tax_sub_category' => $meta['tax_sub_category'],
                            'tax_name' => $taxName,
                            'is_active' => true,
                            'updated_at' => $now,
                        ]);
                }

                $canonicalTaxIds[$taxName] = (int) $canonicalTaxId;

                // Keep legacy rows for audit/history, but deactivate them.
                DB::table('taxes')
                    ->where('tax_name', $taxName)
                    ->where('id', '<>', $canonicalTaxId)
                    ->update([
                        'is_active' => false,
                        'updated_at' => $now,
                    ]);
            }

            $allSameNameTaxIds = DB::table('taxes')
                ->whereIn('tax_name', array_keys($canonicalTaxes))
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->toArray();

            $redundantTaxIds = array_values(array_diff($allSameNameTaxIds, array_values($canonicalTaxIds)));

            if (!empty($redundantTaxIds)) {
                DB::table('product_taxes')
                    ->whereIn('tax_id', $redundantTaxIds)
                    ->delete();
            }

            foreach ($canonicalTaxes as $taxName => $meta) {
                DB::table('product_taxes')
                    ->where('tax_id', $canonicalTaxIds[$taxName])
                    ->update([
                        'tax_percent' => $meta['tax_percent'],
                    ]);
            }

            $productIds = DB::table('product')
                ->pluck('product_id')
                ->map(fn ($id) => (int) $id)
                ->toArray();

            $productIdChunks = array_chunk($productIds, 1000);
            foreach ($productIdChunks as $productIdChunk) {
                $rowsToUpsert = [];

                foreach ($productIdChunk as $productId) {
                    foreach ($canonicalTaxes as $taxName => $meta) {
                        $rowsToUpsert[] = [
                            'product_id' => $productId,
                            'tax_id' => $canonicalTaxIds[$taxName],
                            'tax_percent' => $meta['tax_percent'],
                        ];
                    }
                }

                if (!empty($rowsToUpsert)) {
                    DB::table('product_taxes')->upsert(
                        $rowsToUpsert,
                        ['product_id', 'tax_id'],
                        ['tax_percent']
                    );
                }
            }
        });
    }

    /**
     * Reverse migration intentionally left as no-op to avoid
     * recreating legacy duplicate taxes.
     */
    public function down(): void
    {
        // no-op
    }
};
