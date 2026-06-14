<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

/**
 * Module-level access control. Runs after api.auth.
 *
 * Usage:
 *   Route::middleware('module:sales')->group(...)         // requires 'sales'
 *   Route::middleware('module:sales,purchase')->group(...) // requires 'sales' OR 'purchase'
 *
 * Rules (default-deny):
 *  - admin is unrestricted
 *  - subadmin must have at least one of the listed modules in their permissions JSON
 *  - any other role (legacy CRM roles, NULL, unknown) is denied — only admin/subadmin
 *    are authorized to use the PMS
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

        // admin is unrestricted.
        if ($staff->role === 'admin') {
            return $next($request);
        }

        // subadmin must hold at least one of the listed modules (comma-separated = OR).
        if ($staff->role === 'subadmin') {
            $required    = array_map('trim', explode(',', $module));
            $permissions = json_decode((string) ($staff->permissions ?? ''), true);
            if (is_array($permissions) && count(array_intersect($required, $permissions)) > 0) {
                return $next($request);
            }

            return response()->json([
                'success' => false,
                'message' => 'You do not have access to this module',
            ], 403);
        }

        // Default-deny: any other role (legacy CRM roles, NULL, unknown) is not authorized.
        return response()->json([
            'success' => false,
            'message' => 'This account is not authorized to use the PMS',
        ], 403);
    }
}
