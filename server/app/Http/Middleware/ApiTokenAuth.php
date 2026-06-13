<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Auth\GenericUser;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
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

        // Populate Laravel's auth guard so auth()->user()/auth()->id() resolve to the
        // acting staff member. The token's user_id is the deli_staff.deli_id (see ModuleAccess),
        // so created_by/updated_by columns are stamped with the correct actor.
        if (!empty($token->user_id)) {
            Auth::setUser(new GenericUser([
                'id'        => (int) $token->user_id,
                'user_type' => $token->user_type ?? 'deli_staff',
                'mobile'    => $token->mobile ?? null,
            ]));
        }

        $request->attributes->set('api_token', $token);

        return $next($request);
    }
}
