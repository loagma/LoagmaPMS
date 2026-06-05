<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ApiTokenAuth
{
    public function handle(Request $request, Closure $next): mixed
    {
        $raw = $request->bearerToken();

        if (!$raw) {
            return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
        }

        $token = DB::table('api_tokens')
            ->where('token_hash', hash('sha256', $raw))
            ->where(function ($q) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', now());
            })
            ->first();

        if (!$token) {
            return response()->json(['success' => false, 'message' => 'Invalid or expired token'], 401);
        }

        DB::table('api_tokens')->where('id', $token->id)->update(['last_used_at' => now()]);
        $request->attributes->set('api_token', $token);

        return $next($request);
    }
}
