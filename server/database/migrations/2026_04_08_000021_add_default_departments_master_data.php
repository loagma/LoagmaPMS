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

        $defaults = [
            'PURCHASE' => 'Purchase',
            'SALES' => 'Sales',
            'ACCOUNTS' => 'Accounts',
            'HR' => 'HR',
            'PRODUCTION' => 'Production',
            'STORES' => 'Stores',
            'ADMIN' => 'Admin',
            'QUALITY' => 'Quality',
            'LOGISTICS' => 'Logistics',
        ];

        foreach ($defaults as $preferredId => $name) {
            $existsByName = DB::table($departmentTable)
                ->whereRaw('LOWER(name) = ?', [strtolower($name)])
                ->exists();

            if ($existsByName) {
                continue;
            }

            DB::table($departmentTable)->insert([
                'id' => $this->nextDepartmentId($departmentTable, $preferredId),
                'name' => $name,
            ]);
        }
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

        $names = [
            'purchase',
            'sales',
            'accounts',
            'hr',
            'production',
            'stores',
            'admin',
            'quality',
            'logistics',
        ];

        foreach ($names as $name) {
            DB::table($departmentTable)
                ->whereRaw('LOWER(name) = ?', [$name])
                ->delete();
        }
    }

    private function nextDepartmentId(string $departmentTable, string $preferredId): string
    {
        $preferredId = strtoupper(substr($preferredId, 0, 10));
        if (! DB::table($departmentTable)->where('id', $preferredId)->exists()) {
            return $preferredId;
        }

        $base = strtoupper(substr($preferredId, 0, 8));
        for ($i = 1; $i <= 99; $i++) {
            $candidate = $base . str_pad((string) $i, 2, '0', STR_PAD_LEFT);
            if (! DB::table($departmentTable)->where('id', $candidate)->exists()) {
                return $candidate;
            }
        }

        return substr($base . '99', 0, 10);
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
