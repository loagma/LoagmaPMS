<?php

return [
    /*
    | PMS auth settings. Read via config() (NOT env() directly) so they keep working
    | when config is cached in production (php artisan config:cache).
    */

    // Shared OTP accepted at POST /api/auth/login (no per-user SMS yet).
    'master_otp' => env('MASTER_OTP', ''),

    // deli_staff mobile promoted to role=admin by `php artisan staff:make-admin`.
    'admin_mobile' => env('ADMIN_MOBILE', ''),
];
