<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

/**
 * Admin-only staff management: create/edit/lock subadmin accounts
 * with module-level permissions.
 */
class StaffController extends Controller
{
    /**
     * Modules an admin may grant to a subadmin.
     * Note: 'staff' is never grantable, and 'reports' is intentionally excluded — the Reports
     * screen is a hub of per-module report views, each governed by its own module permission
     * (products, purchase, sales, ...), so there is nothing separate to grant.
     */
    public const GRANTABLE_MODULES = [
        'products',
        'suppliers',
        'purchase',
        'sales',
        'customers',
        'stock',
        'production',
        'bom',
        'inventory',
    ];

    /**
     * Resolve the requesting staff row from the api_token attribute.
     * Returns null when the requester is not an unlocked admin.
     */
    private function requireAdmin(Request $request): ?object
    {
        $token = $request->attributes->get('api_token');
        if (!$token || empty($token->user_id)) {
            return null;
        }

        $staff = DB::table('deli_staff')
            ->where('deli_id', $token->user_id)
            ->first(['deli_id', 'admin_id', 'role', 'is_locked']);

        if (!$staff || $staff->role !== 'admin' || (int) $staff->is_locked === 1) {
            return null;
        }

        return $staff;
    }

    private function forbidden(): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => 'Only admins can manage staff',
        ], 403);
    }

    /**
     * GET /api/staff — list admin + subadmin accounts under this admin.
     */
    public function index(Request $request): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        if (!$admin) {
            return $this->forbidden();
        }

        try {
            $limit = min(max((int) $request->input('limit', 20), 1), 200);
            $page = max(1, (int) $request->input('page', 1));

            $query = DB::table('deli_staff')
                ->where('admin_id', $admin->admin_id)
                ->whereIn('role', ['admin', 'subadmin']);

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', '%' . $search . '%')
                        ->orWhere('mobile', 'like', '%' . $search . '%');
                });
            }

            $total = $query->count();
            $staff = $query
                ->orderBy('deli_id', 'desc')
                ->skip(($page - 1) * $limit)
                ->take($limit)
                ->get(['deli_id', 'name', 'mobile', 'role', 'permissions', 'is_locked']);

            $data = $staff->map(function ($row) {
                $perms = json_decode((string) ($row->permissions ?? ''), true);
                return [
                    'deli_id'     => (int) $row->deli_id,
                    'name'        => $row->name,
                    'mobile'      => $row->mobile,
                    'role'        => $row->role,
                    'permissions' => is_array($perms) ? $perms : [],
                    'is_locked'   => (int) $row->is_locked === 1,
                ];
            });

            return response()->json([
                'success' => true,
                'data'    => $data,
                'meta'    => ['total' => $total, 'page' => $page, 'limit' => $limit],
            ]);
        } catch (\Exception $e) {
            Log::error('Staff list failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch staff',
            ], 500);
        }
    }

    /**
     * POST /api/staff — create a subadmin.
     */
    public function store(Request $request): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        if (!$admin) {
            return $this->forbidden();
        }

        $validator = Validator::make($request->all(), [
            'name'          => 'required|string|max:255',
            'mobile'        => 'required|string|max:20',
            'permissions'   => 'required|array|min:1',
            'permissions.*' => 'string|in:' . implode(',', self::GRANTABLE_MODULES),
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $mobile = trim((string) $request->input('mobile'));

        try {
            $exists = DB::table('deli_staff')->where('mobile', $mobile)->exists();
            if ($exists) {
                return response()->json([
                    'success' => false,
                    'message' => 'A staff account with this mobile number already exists',
                ], 422);
            }

            $permissions = array_values(array_unique($request->input('permissions')));

            $deliId = DB::table('deli_staff')->insertGetId([
                'admin_id'    => $admin->admin_id,
                'role'        => 'subadmin',
                'permissions' => json_encode($permissions),
                'name'        => trim((string) $request->input('name')),
                'mobile'      => $mobile,
                'is_locked'   => 0,
            ], 'deli_id');

            return response()->json([
                'success' => true,
                'message' => 'Subadmin created successfully',
                'data'    => [
                    'deli_id'     => $deliId,
                    'role'        => 'subadmin',
                    'permissions' => $permissions,
                ],
            ], 201);
        } catch (\Exception $e) {
            Log::error('Subadmin creation failed', ['error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to create subadmin',
            ], 500);
        }
    }

    /**
     * PUT /api/staff/{deliId} — update a subadmin's name/permissions/lock state.
     */
    public function update(Request $request, int $deliId): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        if (!$admin) {
            return $this->forbidden();
        }

        $validator = Validator::make($request->all(), [
            'name'          => 'sometimes|string|max:255',
            'permissions'   => 'sometimes|array|min:1',
            'permissions.*' => 'string|in:' . implode(',', self::GRANTABLE_MODULES),
            'is_locked'     => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        try {
            $target = DB::table('deli_staff')
                ->where('deli_id', $deliId)
                ->where('admin_id', $admin->admin_id)
                ->where('role', 'subadmin')
                ->first(['deli_id']);

            if (!$target) {
                return response()->json([
                    'success' => false,
                    'message' => 'Subadmin not found',
                ], 404);
            }

            $updates = [];
            if ($request->has('name')) {
                $updates['name'] = trim((string) $request->input('name'));
            }
            if ($request->has('permissions')) {
                $updates['permissions'] = json_encode(
                    array_values(array_unique($request->input('permissions')))
                );
            }
            if ($request->has('is_locked')) {
                $updates['is_locked'] = $request->boolean('is_locked') ? 1 : 0;
            }

            if (empty($updates)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Nothing to update',
                ], 422);
            }

            DB::table('deli_staff')->where('deli_id', $deliId)->update($updates);

            return response()->json([
                'success' => true,
                'message' => 'Subadmin updated successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Subadmin update failed', ['deli_id' => $deliId, 'error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to update subadmin',
            ], 500);
        }
    }

    /**
     * DELETE /api/staff/{deliId} — soft-disable (lock) a subadmin.
     * Hard delete is avoided because deli_staff rows may be referenced elsewhere.
     */
    public function destroy(Request $request, int $deliId): JsonResponse
    {
        $admin = $this->requireAdmin($request);
        if (!$admin) {
            return $this->forbidden();
        }

        try {
            $updated = DB::table('deli_staff')
                ->where('deli_id', $deliId)
                ->where('admin_id', $admin->admin_id)
                ->where('role', 'subadmin')
                ->update(['is_locked' => 1]);

            if ($updated === 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Subadmin not found',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Subadmin disabled successfully',
            ]);
        } catch (\Exception $e) {
            Log::error('Subadmin disable failed', ['deli_id' => $deliId, 'error' => $e->getMessage()]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to disable subadmin',
            ], 500);
        }
    }
}
