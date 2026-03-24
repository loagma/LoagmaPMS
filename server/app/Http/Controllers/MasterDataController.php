<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

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
            $query = DB::table('Department')
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
}
