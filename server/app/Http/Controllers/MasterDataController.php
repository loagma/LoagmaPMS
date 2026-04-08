<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

class MasterDataController extends Controller
{
    public function businessTypes(Request $request): JsonResponse
    {
        try {
            $query = DB::table('BusinessType')
                ->select('id', 'name', 'createdAt')
                ->orderBy('name');

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where('name', 'like', '%' . $search . '%');
            }

            $items = $query->limit(500)->get();

            return response()->json([
                'success' => true,
                'data' => $items,
            ]);
        } catch (\Exception $e) {
            Log::error('BusinessType fetch error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch business types',
            ], 500);
        }
    }

    public function departments(Request $request): JsonResponse
    {
        try {
            $departmentTable = $this->resolveDepartmentTable();
            if ($departmentTable === null) {
                return response()->json([
                    'success' => true,
                    'data' => [],
                ]);
            }

            $query = DB::table($departmentTable)
                ->select('id', 'name', 'createdAt')
                ->orderBy('name');

            if ($request->filled('search')) {
                $search = trim((string) $request->input('search'));
                $query->where('name', 'like', '%' . $search . '%');
            }

            $items = $query->limit(500)->get();

            return response()->json([
                'success' => true,
                'data' => $items,
            ]);
        } catch (\Exception $e) {
            Log::error('Department fetch error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch departments',
            ], 500);
        }
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
}
