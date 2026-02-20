<?php

namespace App\Http\Middleware;

use App\Exceptions\VendorProductNotFoundException;
use App\Exceptions\JsonParseException;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class StockApiErrorHandler
{
    /**
     * Handle an incoming request and catch exceptions
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        try {
            return $next($request);
        } catch (VendorProductNotFoundException $e) {
            Log::warning('Vendor product not found', [
                'path' => $request->path(),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Vendor product not found',
                'error' => $e->getMessage(),
            ], 404);

        } catch (JsonParseException $e) {
            Log::error('JSON parse error', [
                'path' => $request->path(),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Invalid pack data format',
                'error' => $e->getMessage(),
            ], 500);

        } catch (ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $e->errors(),
            ], 400);

        } catch (\Exception $e) {
            Log::error('Unexpected error in stock API', [
                'path' => $request->path(),
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Internal server error',
                'error' => config('app.debug') ? $e->getMessage() : 'An unexpected error occurred',
            ], 500);
        }
    }
}
