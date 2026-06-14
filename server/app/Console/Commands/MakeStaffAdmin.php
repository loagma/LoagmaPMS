<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Promotes a deli_staff row to role='admin'. Idempotent and re-runnable — run it once per
 * deploy (release step) or on demand. Do NOT wire this into the app start/boot command:
 * restarts are frequent and a per-boot DB write invites races and boot failures.
 *
 *   php artisan staff:make-admin 9876543210
 *   php artisan staff:make-admin            # falls back to ADMIN_MOBILE from .env
 */
class MakeStaffAdmin extends Command
{
    protected $signature = 'staff:make-admin {mobile? : Mobile number of the staff to promote (defaults to ADMIN_MOBILE env)}';

    protected $description = 'Promote a deli_staff member to admin role (idempotent)';

    public function handle(): int
    {
        $mobile = trim((string) ($this->argument('mobile') ?? config('pms.admin_mobile', '')));

        if ($mobile === '') {
            $this->error('No mobile provided. Pass it as an argument or set ADMIN_MOBILE in .env.');
            return self::FAILURE;
        }

        $staff = DB::table('deli_staff')->where('mobile', $mobile)->first(['deli_id', 'name', 'role']);

        if (!$staff) {
            $this->error("No deli_staff row found for mobile {$mobile}. The account must exist first (it comes from the CRM).");
            return self::FAILURE;
        }

        if ($staff->role === 'admin') {
            $this->info("{$staff->name} ({$mobile}) is already admin — nothing to do.");
            return self::SUCCESS;
        }

        DB::table('deli_staff')->where('deli_id', $staff->deli_id)->update(['role' => 'admin']);

        $this->info("Promoted {$staff->name} ({$mobile}) from '{$staff->role}' to 'admin'.");
        return self::SUCCESS;
    }
}
