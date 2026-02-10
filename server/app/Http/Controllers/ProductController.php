<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\JsonResponse;

class ProductController extends Controller
{
    /**
     * Display a listing of the products from the existing `product` table.
     *
     * The response shape matches the Flutter `Product` model:
     * - product_id
     * - product_name
     * - product_code
     * - product_type  (FINISHED or RAW, derived from inventory_type)
     * - default_unit  (derived from inventory_unit_type)
     */
    public function index(): JsonResponse
    {
        $products = Product::query()
            ->select([
                'product_id',
                'name',
                'hsn_code',
                'inventory_type',
                'inventory_unit_type',
            ])
            ->orderBy('name')
            ->get()
            ->map(static function (Product $product): array {
                return [
                    'product_id' => (int) $product->product_id,
                    'product_name' => $product->name,
                    'product_code' => $product->hsn_code,
                    'product_type' => $product->inventory_type === 'PACK_WISE' ? 'FINISHED' : 'RAW',
                    'default_unit' => $product->inventory_unit_type,
                ];
            });

        return response()->json([
            'data' => $products,
        ]);
    }
}

