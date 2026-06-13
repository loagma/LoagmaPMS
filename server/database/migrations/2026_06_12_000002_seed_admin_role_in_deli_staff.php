<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * One-time migration to promote a deli_staff row to role='admin'.
 *
 * Set the ADMIN_MOBILE env variable to the mobile number of the owner account
 * before running `php artisan migrate`.
 *
 * Safe to run multiple times — only updates when role is not already 'admin'.
 */
return new class extends Migration
{
    public function up(): void
    {
        $mobile = env('ADMIN_MOBILE');

        if (!$mobile) {
            return;
        }

        DB::table('deli_staff')
            ->where('mobile', $mobile)
            ->where('role', '!=', 'admin')
            ->update(['role' => 'admin']);
    }

    public function down(): void
    {
        // Intentionally not reversing — manual change if needed
    }
};
