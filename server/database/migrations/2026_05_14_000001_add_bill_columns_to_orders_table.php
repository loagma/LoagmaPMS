<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'Bill_Dt')) {
                $table->date('Bill_Dt')->nullable()->after('bill_number');
            }
            if (!Schema::hasColumn('orders', 'Department')) {
                $table->string('Department', 100)->nullable()->after('Bill_Dt');
            }
            if (!Schema::hasColumn('orders', 'Bill_Narration')) {
                $table->text('Bill_Narration')->nullable()->after('Department');
            }
            if (!Schema::hasColumn('orders', 'Bill_Vehicle')) {
                $table->string('Bill_Vehicle', 100)->nullable()->after('Bill_Narration');
            }
            if (!Schema::hasColumn('orders', 'Bill_Statement')) {
                $table->string('Bill_Statement', 100)->nullable()->after('Bill_Vehicle');
            }
            if (!Schema::hasColumn('orders', 'bill_roff')) {
                $table->decimal('bill_roff', 10, 2)->default(0)->after('Bill_Statement');
            }
            if (!Schema::hasColumn('orders', 'Doc_Year')) {
                $table->string('Doc_Year', 20)->nullable()->after('bill_roff');
            }
            if (!Schema::hasColumn('orders', 'Sales_Return_VoucherNo')) {
                $table->string('Sales_Return_VoucherNo', 100)->nullable()->after('Doc_Year');
            }
            if (!Schema::hasColumn('orders', 'Sales_Return_Dt')) {
                $table->date('Sales_Return_Dt')->nullable()->after('Sales_Return_VoucherNo');
            }
            if (!Schema::hasColumn('orders', 'Sales_Return_Reason')) {
                $table->text('Sales_Return_Reason')->nullable()->after('Sales_Return_Dt');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'Bill_Dt',
                'Department',
                'Bill_Narration',
                'Bill_Vehicle',
                'Bill_Statement',
                'bill_roff',
                'Doc_Year',
                'Sales_Return_VoucherNo',
                'Sales_Return_Dt',
                'Sales_Return_Reason',
            ]);
        });
    }
};
