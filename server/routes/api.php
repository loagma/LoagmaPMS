<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\BomController;
use App\Http\Controllers\IssueToProductionController;

Route::get('/health', [HealthController::class, 'index']);
Route::get('/products', [ProductController::class, 'index']);

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
