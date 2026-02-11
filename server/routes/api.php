<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\ProductController;

Route::get('/health', [HealthController::class, 'index']);
Route::get('/products', [ProductController::class, 'index']);

