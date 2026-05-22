<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $table = DB::getSchemaBuilder()->hasTable('users') ? 'users' : 'LoginUser_crm';
            $query = DB::table($table)->select(
                'id',
                'name',
                'email',
                'employeeCode',
                'contactNumber'
            );

            if ($request->filled('role')) {
                $role = strtolower(trim((string) $request->input('role')));
                if ($role !== '') {
                    $query->where(function ($q) use ($role, $table) {
                        // roleId stores the role name directly (e.g. "salesman")
                        $q->whereRaw('LOWER(`' . $table . '`.`roleId`) = ?', [$role]);
                        // Also check JSON roles array column (e.g. ["salesman"])
                        $q->orWhereRaw('JSON_CONTAINS(LOWER(`' . $table . '`.`roles`), ?)', [json_encode($role)]);
                    });
                }
            }

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', '%' . $search . '%')
                        ->orWhere('email', 'like', '%' . $search . '%')
                        ->orWhere('employeeCode', 'like', '%' . $search . '%')
                        ->orWhere('contactNumber', 'like', '%' . $search . '%')
                        ->orWhere('id', 'like', '%' . $search . '%');
                });
            }

            $limit = (int) $request->input('limit', 500);
            $items = $query->orderBy('name')->limit($limit)->get();

            return response()->json([
                'success' => true,
                'data' => $items,
            ]);
        } catch (\Exception $e) {
            Log::error('Users fetch error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch users',
            ], 500);
        }
    }
}
