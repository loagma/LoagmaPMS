<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

/**
 * Serve the OpenAPI specification file.
 *
 * URL: /openapi.yaml
 */
Route::get('/openapi.yaml', function () {
    $path = base_path('docs/openapi.yaml');

    abort_unless(file_exists($path), 404);

    return response()->file($path, [
        'Content-Type' => 'application/yaml',
    ]);
});

/**
 * Simple Swagger UI page that loads the OpenAPI spec.
 *
 * URL: /docs
 */
Route::get('/docs', function () {
    return view('swagger');
});
