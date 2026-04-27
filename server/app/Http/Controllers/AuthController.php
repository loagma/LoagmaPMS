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
     * Body: { "mobile": "9876543210", "otp": "5555" }
     *
     * Validates the OTP against the master OTP in config/env, then looks up
     * the deli_staff row by mobile number and returns the staff details.
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

        // Validate OTP against master secret (set MASTER_OTP in .env, default 5555)
        $masterOtp = env('MASTER_OTP', '5555');
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
                    'name',
                    'mobile',
                    'is_locked',
                ]);

            if (!$staff) {
                return response()->json([
                    'success' => false,
                    'message' => 'No staff account found for this mobile number',
                ], 404);
            }

            if ($staff->is_locked) {
                return response()->json([
                    'success' => false,
                    'message' => 'This account is locked. Contact your admin.',
                ], 403);
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'deli_id'  => $staff->deli_id,
                    'admin_id' => $staff->admin_id,
                    'role'     => $staff->role,
                    'name'     => $staff->name,
                    'mobile'   => $staff->mobile,
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
}
