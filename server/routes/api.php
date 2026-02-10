<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\ProductController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the framework and are all assigned to the "api"
| middleware group. Make something great!
|
*/

Route::get('/health', HealthController::class);

Route::get('/products', [ProductController::class, 'index']);

