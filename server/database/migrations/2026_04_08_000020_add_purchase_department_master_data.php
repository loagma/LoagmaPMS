<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $departmentTable = $this->resolveDepartmentTable();
        if ($departmentTable === null) {
            return;
        }

        $hasPurchase = DB::table($departmentTable)
            ->whereRaw('LOWER(name) = ?', ['purchase'])
            ->exists();

        if ($hasPurchase) {
            return;
        }

        DB::table($departmentTable)->insert([
            'id' => $this->nextPurchaseDepartmentId(),
            'name' => 'Purchase',
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $departmentTable = $this->resolveDepartmentTable();
        if ($departmentTable === null) {
            return;
        }

        $generatedIds = ['PURCHASE', 'PURCH9999'];
        for ($i = 1; $i <= 99; $i++) {
            $generatedIds[] = sprintf('PURCH%02d', $i);
        }

        DB::table($departmentTable)
            ->whereIn('id', $generatedIds)
            ->where('name', 'Purchase')
            ->delete();
    }

    private function nextPurchaseDepartmentId(): string
    {
        $departmentTable = $this->resolveDepartmentTable();
        if ($departmentTable === null) {
            return 'PURCHASE';
        }

        $baseId = 'PURCHASE';
        if (! DB::table($departmentTable)->where('id', $baseId)->exists()) {
            return $baseId;
        }

        for ($i = 1; $i <= 99; $i++) {
            $candidate = sprintf('PURCH%02d', $i);
            if (! DB::table($departmentTable)->where('id', $candidate)->exists()) {
                return $candidate;
            }
        }

        return 'PURCH9999';
    }

    private function resolveDepartmentTable(): ?string
    {
        if (Schema::hasTable('department_crm')) {
            return 'department_crm';
        }

        if (Schema::hasTable('Department')) {
            return 'Department';
        }

        if (Schema::hasTable('departments')) {
            return 'departments';
        }

        return null;
    }
};
