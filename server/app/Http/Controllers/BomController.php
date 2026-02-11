<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BomController extends Controller
{
    public function update(Request $request, $id): JsonResponse
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'product_id' => 'required|integer|exists:product,product_id',
                'bom_version' => 'required|string|max:20',
                'status' => 'required|in:DRAFT,APPROVED,LOCKED',
                'remarks' => 'nullable|string',
                'raw_materials' => 'required|array|min:1',
                'raw_materials.*.raw_material_id' => 'required|integer|exists:product,product_id',
                'raw_materials.*.quantity_per_unit' => 'required|numeric|min:0.001',
                'raw_materials.*.unit_type' => 'required|string|max:20',
                'raw_materials.*.wastage_percent' => 'nullable|numeric|min:0|max:100',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            DB::beginTransaction();

            // Check if BOM exists
            $existingBom = DB::table('bom_master')->where('bom_id', $id)->first();

            if (!$existingBom) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'BOM not found'
                ], 404);
            }

            // Check if version conflict (if version changed)
            if ($existingBom->bom_version !== $request->bom_version) {
                $versionExists = DB::table('bom_master')
                    ->where('product_id', $request->product_id)
                    ->where('bom_version', $request->bom_version)
                    ->where('bom_id', '!=', $id)
                    ->exists();

                if ($versionExists) {
                    DB::rollBack();
                    return response()->json([
                        'success' => false,
                        'message' => 'BOM with this version already exists for this product'
                    ], 409);
                }
            }

            // Update BOM master
            DB::table('bom_master')
                ->where('bom_id', $id)
                ->update([
                    'product_id' => $request->product_id,
                    'bom_version' => $request->bom_version,
                    'status' => $request->status,
                    'remarks' => $request->remarks,
                    'updated_at' => now(),
                ]);

            // Delete existing items
            DB::table('bom_items')->where('bom_id', $id)->delete();

            // Insert new BOM items
            $bomItems = [];
            foreach ($request->raw_materials as $material) {
                $bomItems[] = [
                    'bom_id' => $id,
                    'raw_material_id' => $material['raw_material_id'],
                    'quantity_per_unit' => $material['quantity_per_unit'],
                    'unit_type' => $material['unit_type'],
                    'wastage_percent' => $material['wastage_percent'] ?? 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            DB::table('bom_items')->insert($bomItems);

            DB::commit();

            Log::info('BOM updated', [
                'bom_id' => $id,
                'product_id' => $request->product_id,
                'version' => $request->bom_version
            ]);

            return response()->json([
                'success' => true,
                'message' => 'BOM updated successfully',
                'data' => [
                    'bom_id' => $id,
                    'product_id' => $request->product_id,
                    'bom_version' => $request->bom_version,
                    'status' => $request->status,
                ]
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('BOM update failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to update BOM',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'product_id' => 'required|integer|exists:product,product_id',
                'bom_version' => 'required|string|max:20',
                'status' => 'required|in:DRAFT,APPROVED,LOCKED',
                'remarks' => 'nullable|string',
                'raw_materials' => 'required|array|min:1',
                'raw_materials.*.raw_material_id' => 'required|integer|exists:product,product_id',
                'raw_materials.*.quantity_per_unit' => 'required|numeric|min:0.001',
                'raw_materials.*.unit_type' => 'required|string|max:20',
                'raw_materials.*.wastage_percent' => 'nullable|numeric|min:0|max:100',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            DB::beginTransaction();

            // Check if BOM already exists
            $existingBom = DB::table('bom_master')
                ->where('product_id', $request->product_id)
                ->where('bom_version', $request->bom_version)
                ->first();

            if ($existingBom) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'BOM with this version already exists for this product'
                ], 409);
            }

            // Insert BOM master
            $bomId = DB::table('bom_master')->insertGetId([
                'product_id' => $request->product_id,
                'bom_version' => $request->bom_version,
                'status' => $request->status,
                'remarks' => $request->remarks,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Insert BOM items
            $bomItems = [];
            foreach ($request->raw_materials as $material) {
                $bomItems[] = [
                    'bom_id' => $bomId,
                    'raw_material_id' => $material['raw_material_id'],
                    'quantity_per_unit' => $material['quantity_per_unit'],
                    'unit_type' => $material['unit_type'],
                    'wastage_percent' => $material['wastage_percent'] ?? 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }

            DB::table('bom_items')->insert($bomItems);

            DB::commit();

            Log::info('BOM created', [
                'bom_id' => $bomId,
                'product_id' => $request->product_id,
                'version' => $request->bom_version
            ]);

            return response()->json([
                'success' => true,
                'message' => 'BOM saved successfully',
                'data' => [
                    'bom_id' => $bomId,
                    'product_id' => $request->product_id,
                    'bom_version' => $request->bom_version,
                    'status' => $request->status,
                ]
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('BOM creation failed', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to save BOM',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function index(): JsonResponse
    {
        try {
            $boms = DB::table('bom_master as bm')
                ->join('product as p', 'bm.product_id', '=', 'p.product_id')
                ->select(
                    'bm.bom_id',
                    'bm.product_id',
                    'p.name as product_name',
                    'bm.bom_version',
                    'bm.status',
                    'bm.remarks',
                    'bm.created_at',
                    'bm.updated_at'
                )
                ->orderBy('bm.created_at', 'desc')
                ->get();

            return response()->json([
                'success' => true,
                'data' => $boms
            ]);

        } catch (\Exception $e) {
            Log::error('BOM list fetch failed', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch BOMs',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function show($id): JsonResponse
    {
        try {
            $bom = DB::table('bom_master as bm')
                ->join('product as p', 'bm.product_id', '=', 'p.product_id')
                ->where('bm.bom_id', $id)
                ->select(
                    'bm.bom_id',
                    'bm.product_id',
                    'p.name as product_name',
                    'bm.bom_version',
                    'bm.status',
                    'bm.remarks',
                    'bm.created_at',
                    'bm.updated_at'
                )
                ->first();

            if (!$bom) {
                return response()->json([
                    'success' => false,
                    'message' => 'BOM not found'
                ], 404);
            }

            // Get BOM items
            $items = DB::table('bom_items as bi')
                ->join('product as p', 'bi.raw_material_id', '=', 'p.product_id')
                ->where('bi.bom_id', $id)
                ->select(
                    'bi.bom_item_id',
                    'bi.raw_material_id',
                    'p.name as raw_material_name',
                    'bi.quantity_per_unit',
                    'bi.unit_type',
                    'bi.wastage_percent'
                )
                ->get();

            return response()->json([
                'success' => true,
                'data' => [
                    'bom' => $bom,
                    'items' => $items
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('BOM fetch failed', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch BOM',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    public function getUnitTypes(): JsonResponse
    {
        try {
            // Get distinct unit types from product table
            $unitTypes = DB::table('product')
                ->select('inventory_unit_type')
                ->whereNotNull('inventory_unit_type')
                ->where('inventory_unit_type', '!=', '')
                ->distinct()
                ->pluck('inventory_unit_type')
                ->filter()
                ->values();

            // Add common unit types if not present
            $commonUnits = ['KG', 'PCS', 'LTR', 'MTR', 'GM', 'ML'];
            $allUnits = $unitTypes->merge($commonUnits)->unique()->sort()->values();

            return response()->json([
                'success' => true,
                'data' => $allUnits
            ]);

        } catch (\Exception $e) {
            Log::error('Unit types fetch failed', ['error' => $e->getMessage()]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch unit types',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
