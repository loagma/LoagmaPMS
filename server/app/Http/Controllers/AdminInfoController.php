<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AdminInfoController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        try {
            // Always resolve the org from the authenticated caller's own account — never from
            // request params. Otherwise any staff could read another org's bank details (IDOR).
            $token = $request->attributes->get('api_token');
            if (!$token || empty($token->user_id)) {
                return response()->json(['success' => false, 'message' => 'Unauthenticated'], 401);
            }

            $adminId = DB::table('loagma_new.deli_staff')
                ->where('deli_id', (int) $token->user_id)
                ->value('admin_id');

            if ($adminId === null) {
                return response()->json(['success' => false, 'message' => 'No organisation linked to this account'], 404);
            }

            $admin = DB::table('loagma_new.admin')
                ->where('userid', (int) $adminId)
                ->select([
                    'userid',
                    'org_name',
                    'org_email',
                    'org_contact_no',
                    'org_gst',
                    'org_address',
                    'fssai_no',
                    'gst_no',
                    'bank_name',
                    'bank_branch',
                    'account_number',
                    'ifsc_code',
                    'account_type',
                    'phonepe_no',
                    'gpay_no',
                ])
                ->first();

            if (!$admin) {
                return response()->json(['success' => false, 'message' => 'Admin not found'], 404);
            }

            return response()->json(['success' => true, 'data' => $admin]);
        } catch (\Throwable $e) {
            Log::error('AdminInfo fetch error: ' . $e->getMessage());
            return response()->json(['success' => false, 'message' => 'Failed to fetch admin info'], 500);
        }
    }
}
