<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class HsnCodeController extends Controller
{
    /**
     * GET /api/hsn-codes
     * Optional query params:
     *  - search: partial HSN code match
     *  - only_active=1: filter to active codes
     */
    public function index(Request $request)
    {
        $query = DB::table('hsn_codes')
            ->select('id', 'hsn_code', 'is_active')
            ->orderBy('hsn_code');

        $search = trim((string) $request->query('search', ''));
        if ($search !== '') {
            $query->where('hsn_code', 'like', "%{$search}%");
        }

        if ($request->boolean('only_active', false)) {
            $query->where('is_active', true);
        }

        $items = $query->limit(500)->get();

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    /**
     * POST /api/hsn-codes
     * Body: { hsn_code: string, is_active?: bool }
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'hsn_code' => 'required|string|max:50|unique:hsn_codes,hsn_code',
            'is_active' => 'sometimes|boolean',
        ]);

        $now = now();
        $id = DB::table('hsn_codes')->insertGetId([
            'hsn_code' => $validated['hsn_code'],
            'is_active' => $validated['is_active'] ?? true,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $id,
                'hsn_code' => $validated['hsn_code'],
                'is_active' => $validated['is_active'] ?? true,
            ],
            'message' => 'HSN code saved successfully',
        ], 201);
    }
}

