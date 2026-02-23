<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\BomController;
use App\Http\Controllers\IssueToProductionController;
use App\Http\Controllers\ReceiveFromProductionController;
use App\Http\Controllers\StockVoucherController;
use App\Http\Controllers\StockController;
use App\Http\Controllers\VendorProductController;

Route::get('/health', [HealthController::class, 'index']);
Route::get('/products', [ProductController::class, 'index']);

// Vendor Products routes
Route::get('/vendor-products', [VendorProductController::class, 'index']);
Route::get('/vendor-products/{id}', [VendorProductController::class, 'show']);

// BOM routes
Route::get('/boms', [BomController::class, 'index']);
Route::post('/boms', [BomController::class, 'store']);
Route::get('/boms/{id}', [BomController::class, 'show']);
Route::put('/boms/{id}', [BomController::class, 'update']);
Route::get('/unit-types', [BomController::class, 'getUnitTypes']);

// Issue to Production routes
Route::get('/issues', [IssueToProductionController::class, 'index']);
Route::post('/issues', [IssueToProductionController::class, 'store']);
Route::get('/issues/{id}', [IssueToProductionController::class, 'show']);
Route::put('/issues/{id}', [IssueToProductionController::class, 'update']);
Route::get('/issues/debug/vendor-product-stock', [IssueToProductionController::class, 'debugVendorProductStock']);

// Receive from Production routes
Route::get('/receives', [ReceiveFromProductionController::class, 'index']);
Route::post('/receives', [ReceiveFromProductionController::class, 'store']);
Route::get('/receives/{id}', [ReceiveFromProductionController::class, 'show']);
Route::put('/receives/{id}', [ReceiveFromProductionController::class, 'update']);

// Stock Voucher routes
Route::get('/stock-vouchers', [StockVoucherController::class, 'index']);
Route::post('/stock-vouchers', [StockVoucherController::class, 'store']);
Route::get('/stock-vouchers/{id}', [StockVoucherController::class, 'show']);
Route::put('/stock-vouchers/{id}', [StockVoucherController::class, 'update']);

// Stock Management routes
Route::middleware(['App\Http\Middleware\StockApiErrorHandler'])->group(function () {
    Route::post('/vendor-products/{id}/packs/{packId}/stock', [StockController::class, 'updatePackStock']);
    Route::post('/inventory-transactions', [StockController::class, 'processInventoryTransaction']);
    Route::get('/vendor-products/{id}/stock-consistency', [StockController::class, 'validateStockConsistency']);
});
