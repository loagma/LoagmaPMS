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

    /**
     * GET /api/hsn-codes/{id}
     */
    public function show(int $id)
    {
        $item = DB::table('hsn_codes')
            ->select('id', 'hsn_code', 'is_active')
            ->where('id', $id)
            ->first();

        if (!$item) {
            return response()->json([
                'success' => false,
                'message' => 'HSN code not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $item,
        ]);
    }

    /**
     * PUT /api/hsn-codes/{id}
     * Body: { hsn_code?: string, is_active?: bool }
     */
    public function update(Request $request, int $id)
    {
        $exists = DB::table('hsn_codes')->where('id', $id)->exists();

        if (!$exists) {
            return response()->json([
                'success' => false,
                'message' => 'HSN code not found',
            ], 404);
        }

        $validated = $request->validate([
            'hsn_code' => 'sometimes|required|string|max:50|unique:hsn_codes,hsn_code,' . $id,
            'is_active' => 'sometimes|boolean',
        ]);

        $updates = [];
        if (array_key_exists('hsn_code', $validated)) {
            $updates['hsn_code'] = $validated['hsn_code'];
        }
        if (array_key_exists('is_active', $validated)) {
            $updates['is_active'] = $validated['is_active'];
        }

        if (!empty($updates)) {
            $updates['updated_at'] = now();
            DB::table('hsn_codes')->where('id', $id)->update($updates);
        }

        $item = DB::table('hsn_codes')
            ->select('id', 'hsn_code', 'is_active')
            ->where('id', $id)
            ->first();

        return response()->json([
            'success' => true,
            'data' => $item,
            'message' => 'HSN code updated successfully',
        ]);
    }

    /**
     * DELETE /api/hsn-codes/{id}
     */
    public function destroy(int $id)
    {
        $item = DB::table('hsn_codes')
            ->select('id', 'hsn_code')
            ->where('id', $id)
            ->first();

        if (!$item) {
            return response()->json([
                'success' => false,
                'message' => 'HSN code not found',
            ], 404);
        }

        $impactedProducts = DB::table('product')
            ->where('hsn_code', $item->hsn_code)
            ->where('is_deleted', 0)
            ->count();

        DB::table('hsn_codes')->where('id', $id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'HSN code deleted successfully',
            'impacted_products_count' => $impactedProducts,
        ]);
    }
}

