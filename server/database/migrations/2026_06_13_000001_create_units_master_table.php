<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * units_master powers every unit-type dropdown (BOM, stock vouchers, purchase orders, ...).
 * It previously existed only in docs/changes.sql, so a fresh `php artisan migrate` left the
 * table missing and all unit dropdowns empty. This migration recreates it from migrations and
 * seeds the canonical base units. Read as `loagma_new.units_master` (default connection DB).
 *
 * Guarded so it is a no-op on environments that already have the table/rows (e.g. applied
 * earlier from changes.sql or grown dynamically through the app).
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('units_master')) {
            Schema::create('units_master', function (Blueprint $table) {
                $table->increments('unit_id');
                $table->string('unit_name', 100);
                $table->integer('serial_no')->nullable();
                $table->decimal('conversion_rate', 10, 4);
                $table->timestamp('created_at')->useCurrent();
            });
        }

        // Seed only when empty so re-running (or running after changes.sql / on a DB that
        // already has user-created units) never duplicates or overwrites existing rows.
        if (DB::table('units_master')->count() === 0) {
            DB::table('units_master')->insert([
                ['unit_name' => 'KG',    'serial_no' => 1,  'conversion_rate' => 1.0000],
                ['unit_name' => 'GM',    'serial_no' => 2,  'conversion_rate' => 0.0010],
                ['unit_name' => 'LTR',   'serial_no' => 3,  'conversion_rate' => 1.0000],
                ['unit_name' => 'ML',    'serial_no' => 4,  'conversion_rate' => 0.0010],
                ['unit_name' => 'NOS',   'serial_no' => 5,  'conversion_rate' => 1.0000],
                ['unit_name' => 'PCS',   'serial_no' => 6,  'conversion_rate' => 1.0000],
                ['unit_name' => 'BOX',   'serial_no' => 7,  'conversion_rate' => 1.0000],
                ['unit_name' => 'PKT',   'serial_no' => 8,  'conversion_rate' => 1.0000],
                ['unit_name' => 'BAG',   'serial_no' => 9,  'conversion_rate' => 1.0000],
                ['unit_name' => 'DOZEN', 'serial_no' => 10, 'conversion_rate' => 12.0000],
                ['unit_name' => 'BUNCH', 'serial_no' => 11, 'conversion_rate' => 1.0000],
                ['unit_name' => 'MTR',   'serial_no' => 12, 'conversion_rate' => 1.0000],
                ['unit_name' => 'CM',    'serial_no' => 13, 'conversion_rate' => 0.0100],
                ['unit_name' => 'TIN',   'serial_no' => 14, 'conversion_rate' => 1.0000],
                ['unit_name' => 'JAR',   'serial_no' => 15, 'conversion_rate' => 1.0000],
                ['unit_name' => 'BTL',   'serial_no' => 16, 'conversion_rate' => 1.0000],
                ['unit_name' => 'POUCH', 'serial_no' => 17, 'conversion_rate' => 1.0000],
                ['unit_name' => 'STRIP', 'serial_no' => 18, 'conversion_rate' => 1.0000],
                ['unit_name' => 'ROLL',  'serial_no' => 19, 'conversion_rate' => 1.0000],
                ['unit_name' => 'SET',   'serial_no' => 20, 'conversion_rate' => 1.0000],
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('units_master');
    }
};
