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
use App\Http\Controllers\SupplierController;
use App\Http\Controllers\SupplierProductController;
use App\Http\Controllers\PurchaseOrderController;
use App\Http\Controllers\PurchaseVoucherController;
use App\Http\Controllers\PurchaseReturnController;
use App\Http\Controllers\TaxController;
use App\Http\Controllers\ProductTaxController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\HsnCodeController;
use App\Http\Controllers\ProductPackageController;
use App\Http\Controllers\MasterDataController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\SalesOrderController;
use App\Http\Controllers\SalesInvoiceController;

Route::get('/health', [HealthController::class, 'index']);

// Deli-staff authentication
Route::post('/auth/login', [AuthController::class, 'login']);
Route::get('/products', [ProductController::class, 'index']);
Route::post('/products', [ProductController::class, 'store']);
Route::get('/products/{id}', [ProductController::class, 'show'])->where('id', '[0-9]+');
Route::get('/products/{id}/edit', [ProductController::class, 'show'])->where('id', '[0-9]+');
Route::put('/products/{id}', [ProductController::class, 'update'])->where('id', '[0-9]+');
Route::delete('/products/{id}', [ProductController::class, 'destroy'])->where('id', '[0-9]+');

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

// Supplier routes
Route::get('/suppliers', [SupplierController::class, 'index']);
Route::post('/suppliers', [SupplierController::class, 'store']);
Route::get('/suppliers/{id}', [SupplierController::class, 'show']);
Route::put('/suppliers/{id}', [SupplierController::class, 'update']);
Route::get('/suppliers/{id}/products', [SupplierController::class, 'getSupplierProducts']);

// Master data routes (dropdown values)
Route::get('/business-types', [MasterDataController::class, 'businessTypes']);
Route::get('/departments', [MasterDataController::class, 'departments']);
Route::get('/customers', [CustomerController::class, 'index']);
Route::get('/customers/{id}', [CustomerController::class, 'show'])->where('id', '[0-9]+');
Route::post('/customers', [CustomerController::class, 'store']);
Route::put('/customers/{id}', [CustomerController::class, 'update'])->where('id', '[0-9]+');
Route::get('/users', [UserController::class, 'index']);

// Supplier Product routes (specific 'bulk' must be before {id})
Route::get('/supplier-products', [SupplierProductController::class, 'index']);
Route::post('/supplier-products', [SupplierProductController::class, 'store']);
Route::post('/supplier-products/bulk', [SupplierProductController::class, 'storeBulk']);
Route::get('/supplier-products/{id}', [SupplierProductController::class, 'show'])->where('id', '[0-9]+');
Route::put('/supplier-products/{id}', [SupplierProductController::class, 'update'])->where('id', '[0-9]+');
Route::delete('/supplier-products/{id}', [SupplierProductController::class, 'destroy'])->where('id', '[0-9]+');

// Purchase Order routes
Route::get('/purchase-orders', [PurchaseOrderController::class, 'index']);
Route::post('/purchase-orders', [PurchaseOrderController::class, 'store']);
Route::get('/purchase-orders/{id}', [PurchaseOrderController::class, 'show']);
Route::put('/purchase-orders/{id}', [PurchaseOrderController::class, 'update']);
Route::delete('/purchase-orders/{id}', [PurchaseOrderController::class, 'destroy']);

// Purchase Voucher routes
Route::get('/purchase-vouchers', [PurchaseVoucherController::class, 'index']);
Route::post('/purchase-vouchers', [PurchaseVoucherController::class, 'store']);
Route::get('/purchase-vouchers/{id}', [PurchaseVoucherController::class, 'show']);
Route::put('/purchase-vouchers/{id}', [PurchaseVoucherController::class, 'update']);

// Purchase Return routes
Route::get('/purchase-returns', [PurchaseReturnController::class, 'index']);
Route::get('/purchase-returns/series', [PurchaseReturnController::class, 'series']);
Route::post('/purchase-returns', [PurchaseReturnController::class, 'store']);
Route::get('/purchase-returns/{purchaseReturn}', [PurchaseReturnController::class, 'show']);
Route::put('/purchase-returns/{purchaseReturn}', [PurchaseReturnController::class, 'update']);
Route::delete('/purchase-returns/{purchaseReturn}', [PurchaseReturnController::class, 'destroy']);

// Tax routes
Route::get('/taxes', [TaxController::class, 'index']);
Route::post('/taxes', [TaxController::class, 'store']);
Route::get('/taxes/{id}', [TaxController::class, 'show'])->where('id', '[0-9]+');
Route::put('/taxes/{id}', [TaxController::class, 'update'])->where('id', '[0-9]+');
Route::delete('/taxes/{id}', [TaxController::class, 'destroy'])->where('id', '[0-9]+');

// Product Tax routes
Route::get('/product-taxes', [ProductTaxController::class, 'index']);
Route::post('/product-taxes', [ProductTaxController::class, 'store']);
Route::delete('/product-taxes/{id}', [ProductTaxController::class, 'destroy'])->where('id', '[0-9]+');

// HSN code routes
Route::get('/hsn-codes', [HsnCodeController::class, 'index']);
Route::post('/hsn-codes', [HsnCodeController::class, 'store']);
Route::get('/hsn-codes/{id}', [HsnCodeController::class, 'show'])->where('id', '[0-9]+');
Route::get('/hsn-codes/{id}/edit', [HsnCodeController::class, 'show'])->where('id', '[0-9]+');
Route::put('/hsn-codes/{id}', [HsnCodeController::class, 'update'])->where('id', '[0-9]+');
Route::delete('/hsn-codes/{id}', [HsnCodeController::class, 'destroy'])->where('id', '[0-9]+');

// Product Package routes
Route::get('/product-packages', [ProductPackageController::class, 'index']);
Route::post('/product-packages', [ProductPackageController::class, 'store']);
Route::get('/product-packages/{id}', [ProductPackageController::class, 'show'])->where('id', '[0-9]+');
Route::put('/product-packages/{id}', [ProductPackageController::class, 'update'])->where('id', '[0-9]+');

// Sales Order routes
Route::get('/sales-orders', [SalesOrderController::class, 'index']);
Route::post('/sales-orders', [SalesOrderController::class, 'store']);
Route::get('/sales-orders/{id}', [SalesOrderController::class, 'show'])->where('id', '[0-9]+');
Route::put('/sales-orders/{id}', [SalesOrderController::class, 'update'])->where('id', '[0-9]+');

// Sales Invoice routes
Route::get('/sales-invoices/series', [SalesInvoiceController::class, 'series']);
Route::get('/sales-invoices', [SalesInvoiceController::class, 'index']);
Route::post('/sales-invoices', [SalesInvoiceController::class, 'store']);
Route::get('/sales-invoices/{id}', [SalesInvoiceController::class, 'show'])->where('id', '[0-9]+');
Route::put('/sales-invoices/{id}', [SalesInvoiceController::class, 'update'])->where('id', '[0-9]+');

// Category routes (parent_cat_id=0: category, parent_cat_id>0: subcategory)
Route::get('/categories', [CategoryController::class, 'index']);
Route::post('/categories', [CategoryController::class, 'store']);
Route::get('/categories/{id}', [CategoryController::class, 'show'])->where('id', '[0-9]+');
Route::put('/categories/{id}', [CategoryController::class, 'update'])->where('id', '[0-9]+');
Route::delete('/categories/{id}', [CategoryController::class, 'destroy'])->where('id', '[0-9]+');
