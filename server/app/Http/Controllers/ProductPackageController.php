<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProductPackageController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = DB::table('product')
            ->select('product_id', 'packs')
            ->where('is_deleted', 0);

        if ($request->filled('product_id')) {
            $query->where('product_id', (int) $request->input('product_id'));
        }

        $rows = $query->get();
        $items = [];

        foreach ($rows as $row) {
            $packs = $this->decodePacks($row->packs);
            foreach ($packs as $index => $pack) {
                $formatted = $this->formatPackage((int) $row->product_id, $pack, $index);
                if ($formatted !== null) {
                    $items[] = $formatted;
                }
            }
        }

        return response()->json([
            'success' => true,
            'data' => $items,
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $found = $this->findPackageByRouteId($id);

        if ($found === null) {
            return response()->json([
                'success' => false,
                'message' => 'Package not found',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $found['formatted'],
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'product_id' => 'required|integer|exists:product,product_id',
            'pack_size' => 'required|numeric|gt:0',
            'unit' => 'required|string|max:50',
            'price' => 'nullable|numeric|min:0',
        ]);

        $product = DB::table('product')
            ->select('product_id', 'packs')
            ->where('product_id', (int) $validated['product_id'])
            ->where('is_deleted', 0)
            ->first();

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found',
            ], 404);
        }

        $packs = $this->decodePacks($product->packs);

        $newPack = [
            'id' => (string) round(microtime(true) * 1000),
            'description' => trim(((float) $validated['pack_size']) . ' ' . $validated['unit']),
            'size' => (float) $validated['pack_size'],
            'unit' => trim((string) $validated['unit']),
            'market_price' => array_key_exists('price', $validated) ? (float) ($validated['price'] ?? 0) : 0,
            'price' => array_key_exists('price', $validated) ? (float) ($validated['price'] ?? 0) : null,
            'is_active' => true,
        ];

        $packs[] = $newPack;

        DB::table('product')
            ->where('product_id', (int) $validated['product_id'])
            ->update([
                'packs' => json_encode($packs, JSON_UNESCAPED_UNICODE),
            ]);

        $formatted = $this->formatPackage((int) $validated['product_id'], $newPack, count($packs) - 1);

        return response()->json([
            'success' => true,
            'message' => 'Package saved successfully',
            'data' => $formatted,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'pack_size' => 'sometimes|required|numeric|gt:0',
            'unit' => 'sometimes|required|string|max:50',
            'price' => 'nullable|numeric|min:0',
        ]);

        $found = $this->findPackageByRouteId($id);
        if ($found === null) {
            return response()->json([
                'success' => false,
                'message' => 'Package not found',
            ], 404);
        }

        $packs = $found['packs'];
        $index = $found['index'];
        $pack = $packs[$index];

        if (array_key_exists('pack_size', $validated)) {
            $pack['size'] = (float) $validated['pack_size'];
            if (isset($pack['ps'])) {
                $pack['ps'] = (float) $validated['pack_size'];
            }
        }
        if (array_key_exists('unit', $validated)) {
            $pack['unit'] = trim((string) $validated['unit']);
            if (isset($pack['pu'])) {
                $pack['pu'] = trim((string) $validated['unit']);
            }
        }
        if (array_key_exists('price', $validated)) {
            $price = $validated['price'] === null ? null : (float) $validated['price'];
            $pack['price'] = $price;
            $pack['market_price'] = $price ?? 0;
            if (isset($pack['op'])) {
                $pack['op'] = $price ?? 0;
            }
            if (isset($pack['rp'])) {
                $pack['rp'] = $price ?? 0;
            }
        }

        if (isset($pack['size']) && isset($pack['unit'])) {
            $pack['description'] = trim(((float) $pack['size']) . ' ' . (string) $pack['unit']);
        }

        $packs[$index] = $pack;

        DB::table('product')
            ->where('product_id', $found['product_id'])
            ->update([
                'packs' => json_encode($packs, JSON_UNESCAPED_UNICODE),
            ]);

        return response()->json([
            'success' => true,
            'message' => 'Package updated successfully',
            'data' => $this->formatPackage($found['product_id'], $pack, $index),
        ]);
    }

    private function decodePacks($raw): array
    {
        if (!is_string($raw) || trim($raw) === '') {
            return [];
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            return [];
        }

        if (array_is_list($decoded)) {
            return $decoded;
        }

        return array_values($decoded);
    }

    private function formatPackage(int $productId, array $pack, int $index): ?array
    {
        $packSize = $this->firstNumeric($pack, ['pack_size', 'size', 'ps']);
        $unit = $this->firstString($pack, ['unit', 'pu']);
        $price = $this->firstNumeric($pack, ['price', 'market_price', 'op', 'rp']);

        if ($packSize === null || $unit === '') {
            return null;
        }

        return [
            'id' => $this->routeIdForPack($productId, $pack, $index),
            'product_id' => $productId,
            'pack_size' => $packSize,
            'unit' => $unit,
            'price' => $price,
        ];
    }

    private function findPackageByRouteId(int $routeId): ?array
    {
        $rows = DB::table('product')
            ->select('product_id', 'packs')
            ->where('is_deleted', 0)
            ->whereNotNull('packs')
            ->get();

        foreach ($rows as $row) {
            $productId = (int) $row->product_id;
            $packs = $this->decodePacks($row->packs);
            foreach ($packs as $index => $pack) {
                if ($this->routeIdForPack($productId, $pack, $index) === $routeId) {
                    $formatted = $this->formatPackage($productId, $pack, $index);
                    if ($formatted === null) {
                        return null;
                    }

                    return [
                        'product_id' => $productId,
                        'packs' => $packs,
                        'index' => $index,
                        'formatted' => $formatted,
                    ];
                }
            }
        }

        return null;
    }

    private function routeIdForPack(int $productId, array $pack, int $index): int
    {
        $innerId = $this->firstString($pack, ['id', 'pi']);
        if ($innerId === '') {
            $innerId = 'idx:' . $index;
        }

        return (int) sprintf('%u', crc32($productId . '|' . $innerId));
    }

    private function firstString(array $source, array $keys): string
    {
        foreach ($keys as $key) {
            if (array_key_exists($key, $source) && $source[$key] !== null) {
                return trim((string) $source[$key]);
            }
        }

        return '';
    }

    private function firstNumeric(array $source, array $keys): ?float
    {
        foreach ($keys as $key) {
            if (!array_key_exists($key, $source) || $source[$key] === null) {
                continue;
            }

            if (is_numeric($source[$key])) {
                return (float) $source[$key];
            }
        }

        return null;
    }
}
