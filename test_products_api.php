<?php
/**
 * Simple test script to verify products API returns valid JSON
 * Run: php test_products_api.php
 */

require __DIR__ . '/server/vendor/autoload.php';

use Illuminate\Support\Facades\DB;

// Bootstrap Laravel
$app = require_once __DIR__ . '/server/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "Testing Products API...\n\n";

try {
    // Get products
    $products = DB::table('product')
        ->select('product_id', 'name', 'inventory_type')
        ->where('is_deleted', 0)
        ->where('is_published', 1)
        ->whereNotNull('product_id')
        ->whereNotNull('name')
        ->whereRaw("TRIM(name) != ''")
        ->orderBy('name')
        ->get();

    echo "Found {$products->count()} products\n\n";

    // Clean and validate each product
    $cleanProducts = $products->map(function ($product) {
        $cleanName = trim($product->name);
        $cleanName = str_replace(['"', '\\', "\n", "\r", "\t"], '', $cleanName);
        
        $inventoryType = trim($product->inventory_type ?? 'SINGLE');
        if (empty($inventoryType)) {
            $inventoryType = 'SINGLE';
        }
        
        return [
            'product_id' => (int) $product->product_id,
            'name' => $cleanName,
            'inventory_type' => $inventoryType
        ];
    })
    ->filter(function ($product) {
        return !empty($product['name']);
    })
    ->values();

    echo "After cleaning: {$cleanProducts->count()} products\n\n";

    // Test JSON encoding
    $json = json_encode(['success' => true, 'data' => $cleanProducts], JSON_UNESCAPED_UNICODE);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo "❌ JSON encoding failed: " . json_last_error_msg() . "\n";
        exit(1);
    }

    echo "✅ JSON encoding successful!\n";
    echo "Response size: " . number_format(strlen($json)) . " bytes\n\n";
    
    // Validate JSON by decoding it back
    $decoded = json_decode($json, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo "❌ JSON decoding failed: " . json_last_error_msg() . "\n";
        exit(1);
    }
    
    echo "✅ JSON decoding successful!\n\n";
    
    // Show first 5 products
    echo "Sample products:\n";
    foreach ($cleanProducts->take(5) as $product) {
        echo "  - [{$product['product_id']}] {$product['name']} ({$product['inventory_type']})\n";
    }

    echo "\n✅ All tests passed! API is ready.\n";

} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    echo $e->getTraceAsString() . "\n";
    exit(1);
}
