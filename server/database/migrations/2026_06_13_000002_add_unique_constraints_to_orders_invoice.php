<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Sales invoice numbers had no DB-level uniqueness — a race between two concurrent
 * MAX()+1 generators (or any bug) could write duplicate invoice/bill numbers, which is
 * illegal under GST. invoice_number is sequential per financial year (Doc_Year) and the
 * prefix is computed, not stored, so the natural key is (Doc_Year, invoice_number).
 *
 * NULLs are allowed to repeat in MySQL, so un-numbered (DRAFT) orders are unaffected.
 */
return new class extends Migration
{
    public function up(): void
    {
        $this->assertNoDuplicates();

        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            $table->unique(['Doc_Year', 'invoice_number'], 'orders_docyear_invoice_unique');
            $table->unique('bill_no', 'orders_bill_no_unique');
        });
    }

    public function down(): void
    {
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            $table->dropUnique('orders_docyear_invoice_unique');
            $table->dropUnique('orders_bill_no_unique');
        });
    }

    /**
     * Fail early with an actionable message if existing data would violate the new
     * constraints, instead of a cryptic SQLSTATE[23000] from the index creation.
     */
    private function assertNoDuplicates(): void
    {
        $conn = DB::connection('mysql');

        $dupInvoice = $conn->table('orders')
            ->select('Doc_Year', 'invoice_number', DB::raw('COUNT(*) as c'))
            ->whereNotNull('invoice_number')
            ->groupBy('Doc_Year', 'invoice_number')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        $dupBill = $conn->table('orders')
            ->select('bill_no', DB::raw('COUNT(*) as c'))
            ->whereNotNull('bill_no')
            ->groupBy('bill_no')
            ->havingRaw('COUNT(*) > 1')
            ->get();

        if ($dupInvoice->isNotEmpty() || $dupBill->isNotEmpty()) {
            $msg = "Cannot add unique constraints to orders — resolve duplicates first.\n";
            foreach ($dupInvoice as $d) {
                $msg .= "  duplicate (Doc_Year={$d->Doc_Year}, invoice_number={$d->invoice_number}) x{$d->c}\n";
            }
            foreach ($dupBill as $d) {
                $msg .= "  duplicate (bill_no={$d->bill_no}) x{$d->c}\n";
            }
            throw new \RuntimeException($msg);
        }
    }
};
