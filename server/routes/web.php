<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;

// Root URL health check - useful for Render uptime checks
Route::get('/', [HealthController::class, 'index']);
