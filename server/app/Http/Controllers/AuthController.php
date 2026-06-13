<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AuthController extends Controller
{
    /**
     * POST /api/auth/login
     *
     * Body: { "mobile": "9876543210", "otp": "<master-otp>" }
     */
    public function login(Request $request): JsonResponse
    {
        $mobile = trim((string) $request->input('mobile', ''));
        $otp    = trim((string) $request->input('otp', ''));

        if ($mobile === '' || $otp === '') {
            return response()->json([
                'success' => false,
                'message' => 'mobile and otp are required',
            ], 422);
        }

        $masterOtp = (string) env('MASTER_OTP', '');
        if ($masterOtp === '') {
            Log::error('MASTER_OTP is not configured');
            return response()->json([
                'success' => false,
                'message' => 'Login is not configured. Contact your administrator.',
            ], 500);
        }
        if ($otp !== $masterOtp) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid OTP',
            ], 401);
        }

        try {
            $staff = DB::table('deli_staff')
                ->where('mobile', $mobile)
                ->first([
                    'deli_id',
                    'admin_id',
                    'role',
                    'permissions',
                    'name',
                    'mobile',
                    'is_locked',
                    'state',
                ]);

            if (!$staff) {
                return response()->json([
                    'success' => false,
                    'message' => 'No staff account found for this mobile number',
                ], 404);
            }

            if ((int) $staff->is_locked === 1) {
                return response()->json([
                    'success' => false,
                    'message' => 'This account is locked. Contact your admin.',
                ], 403);
            }

            $rawToken  = bin2hex(random_bytes(32));
            $expiresAt = now()->addHours(24);

            DB::table('api_tokens')->insert([
                'token_hash' => hash('sha256', $rawToken),
                'user_id'    => (string) $staff->deli_id,
                'user_type'  => 'deli_staff',
                'mobile'     => $staff->mobile,
                'expires_at' => $expiresAt,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $permissions = json_decode((string) ($staff->permissions ?? ''), true);

            return response()->json([
                'success'    => true,
                'token'      => $rawToken,
                'expires_at' => $expiresAt->toISOString(),
                'data'       => [
                    'deli_id'     => $staff->deli_id,
                    'admin_id'    => $staff->admin_id,
                    'role'        => $staff->role,
                    'permissions' => is_array($permissions) ? $permissions : [],
                    'name'        => $staff->name,
                    'mobile'      => $staff->mobile,
                    'state'       => $staff->state ?? '',
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('DeliStaff login error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Login failed. Please try again.',
            ], 500);
        }
    }

    /**
     * DELETE /api/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $raw = $request->bearerToken();
        if ($raw) {
            DB::table('api_tokens')->where('token_hash', hash('sha256', $raw))->delete();
        }
        return response()->json(['success' => true, 'message' => 'Logged out']);
    }
}
