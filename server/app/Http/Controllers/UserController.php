<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        try {
            $query = DB::table('users')->select(
                'id',
                'name',
                'email',
                'employeeCode',
                'contactNumber'
            );

            if ($request->filled('role') && Schema::hasTable('roles') && Schema::hasColumn('users', 'roleId')) {
                $role = trim((string) $request->input('role'));
                if ($role !== '') {
                    $query
                        ->join('roles', 'roles.id', '=', 'users.roleId')
                        ->whereRaw('LOWER(roles.name) = ?', [strtolower($role)]);
                }
            }

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', '%' . $search . '%')
                        ->orWhere('email', 'like', '%' . $search . '%')
                        ->orWhere('employeeCode', 'like', '%' . $search . '%')
                        ->orWhere('contactNumber', 'like', '%' . $search . '%');
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
