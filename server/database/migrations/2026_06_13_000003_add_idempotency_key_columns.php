<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Idempotency keys let the server detect client retries (dropped responses, network timeouts)
 * and avoid creating a second voucher / double-deducting stock. The client sends one UUID per
 * intended submission; the unique index is the last-ditch race guard.
 *
 * stock_voucher / purchase_vouchers / purchase_returns live on the default connection;
 * orders lives in loagma_new (the 'mysql' connection here).
 */
return new class extends Migration
{
    public function up(): void
    {
        foreach (['stock_voucher', 'purchase_vouchers', 'purchase_returns'] as $table) {
            if (Schema::hasTable($table) && !Schema::hasColumn($table, 'idempotency_key')) {
                Schema::table($table, function (Blueprint $t) {
                    $t->string('idempotency_key', 64)->nullable()->unique();
                });
            }
        }

        if (!Schema::connection('mysql')->hasColumn('orders', 'idempotency_key')) {
            Schema::connection('mysql')->table('orders', function (Blueprint $t) {
                $t->string('idempotency_key', 64)->nullable()->unique();
            });
        }
    }

    public function down(): void
    {
        foreach (['stock_voucher', 'purchase_vouchers', 'purchase_returns'] as $table) {
            if (Schema::hasTable($table) && Schema::hasColumn($table, 'idempotency_key')) {
                Schema::table($table, function (Blueprint $t) {
                    $t->dropUnique($t->getTable() . '_idempotency_key_unique');
                    $t->dropColumn('idempotency_key');
                });
            }
        }

        if (Schema::connection('mysql')->hasColumn('orders', 'idempotency_key')) {
            Schema::connection('mysql')->table('orders', function (Blueprint $t) {
                $t->dropUnique('orders_idempotency_key_unique');
                $t->dropColumn('idempotency_key');
            });
        }
    }
};
