<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

/**
 * Module-level access control. Runs after api.auth.
 *
 * Usage: Route::middleware('module:sales')->group(...)
 *
 * Rules:
 *  - admin and legacy roles (driver, salesman, ...) are unrestricted
 *  - subadmin must have the module in their permissions JSON array
 */
class ModuleAccess
{
    public function handle(Request $request, Closure $next, string $module): Response
    {
        $token = $request->attributes->get('api_token');

        if (!$token || empty($token->user_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated',
            ], 401);
        }

        $staff = DB::table('deli_staff')
            ->where('deli_id', $token->user_id)
            ->first(['deli_id', 'admin_id', 'role', 'permissions', 'is_locked']);

        if (!$staff) {
            return response()->json([
                'success' => false,
                'message' => 'Staff account not found',
            ], 403);
        }

        if ((int) $staff->is_locked === 1) {
            return response()->json([
                'success' => false,
                'message' => 'This account is locked. Contact your admin.',
            ], 403);
        }

        $request->attributes->set('staff', $staff);

        if ($staff->role !== 'subadmin') {
            return $next($request);
        }

        $permissions = json_decode((string) ($staff->permissions ?? ''), true);
        if (is_array($permissions) && in_array($module, $permissions, true)) {
            return $next($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'You do not have access to this module',
        ], 403);
    }
}
