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
            'description' => 'nullable|string|max:255',
            'pack_size' => 'required|numeric|gt:0',
            'unit' => 'required|string|max:50',
            'price' => 'nullable|numeric|min:0',
            'market_price' => 'nullable|numeric|min:0',
            'retail_prices' => 'nullable|string|max:255',
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

        $marketPrice = null;
        if (array_key_exists('market_price', $validated)) {
            $marketPrice = $validated['market_price'] === null ? null : (float) $validated['market_price'];
        } elseif (array_key_exists('price', $validated)) {
            $marketPrice = $validated['price'] === null ? null : (float) $validated['price'];
        }

        $retailPrices = $this->parseRetailPrices($validated['retail_prices'] ?? null);

        $newPack = [
            'id' => (string) round(microtime(true) * 1000),
            'description' => trim((string) ($validated['description'] ?? '')) !== ''
                ? trim((string) $validated['description'])
                : trim(((float) $validated['pack_size']) . ' ' . $validated['unit']),
            'size' => (float) $validated['pack_size'],
            'ps' => (float) $validated['pack_size'],
            'unit' => trim((string) $validated['unit']),
            'pu' => trim((string) $validated['unit']),
            'market_price' => $marketPrice,
            'price' => $marketPrice,
            'op' => $marketPrice,
            'rp' => $retailPrices['regular'] ?? $marketPrice,
            'prices' => $retailPrices,
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
            'description' => 'sometimes|nullable|string|max:255',
            'pack_size' => 'sometimes|required|numeric|gt:0',
            'unit' => 'sometimes|required|string|max:50',
            'price' => 'nullable|numeric|min:0',
            'market_price' => 'nullable|numeric|min:0',
            'retail_prices' => 'sometimes|nullable|string|max:255',
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

        if (array_key_exists('description', $validated)) {
            $description = trim((string) ($validated['description'] ?? ''));
            if ($description !== '') {
                $pack['description'] = $description;
            }
        }

        if (array_key_exists('pack_size', $validated)) {
            $pack['size'] = (float) $validated['pack_size'];
            $pack['ps'] = (float) $validated['pack_size'];
        }
        if (array_key_exists('unit', $validated)) {
            $pack['unit'] = trim((string) $validated['unit']);
            $pack['pu'] = trim((string) $validated['unit']);
        }

        if (array_key_exists('market_price', $validated) || array_key_exists('price', $validated)) {
            $marketPrice = array_key_exists('market_price', $validated)
                ? ($validated['market_price'] === null ? null : (float) $validated['market_price'])
                : ($validated['price'] === null ? null : (float) $validated['price']);

            $pack['price'] = $marketPrice;
            $pack['market_price'] = $marketPrice;
            $pack['op'] = $marketPrice;
        }

        if (array_key_exists('retail_prices', $validated)) {
            $retailPrices = $this->parseRetailPrices($validated['retail_prices']);
            if ($retailPrices !== null) {
                $pack['prices'] = $retailPrices;
                $pack['rp'] = $retailPrices['regular'] ?? ($pack['market_price'] ?? null);
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
            'description' => $this->firstString($pack, ['description']),
            'pack_size' => $packSize,
            'unit' => $unit,
            'price' => $price,
            'market_price' => $this->firstNumeric($pack, ['market_price', 'price', 'op']),
            'retail_prices' => $this->retailPricesToRaw($pack['prices'] ?? null),
        ];
    }

    private function parseRetailPrices(?string $raw): ?array
    {
        if ($raw === null) {
            return null;
        }

        $parts = array_map('trim', explode(',', $raw));
        if (count($parts) !== 3) {
            return null;
        }

        if (!is_numeric($parts[0]) || !is_numeric($parts[1]) || !is_numeric($parts[2])) {
            return null;
        }

        return [
            'new' => (float) $parts[0],
            'regular' => (float) $parts[1],
            'home' => (float) $parts[2],
        ];
    }

    private function retailPricesToRaw($prices): ?string
    {
        if (!is_array($prices)) {
            return null;
        }

        if (!array_key_exists('new', $prices) || !array_key_exists('regular', $prices) || !array_key_exists('home', $prices)) {
            return null;
        }

        return $prices['new'] . ',' . $prices['regular'] . ',' . $prices['home'];
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
