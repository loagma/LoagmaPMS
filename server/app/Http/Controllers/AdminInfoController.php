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
            $deliId  = $request->input('deli_id');
            $adminId = $request->input('admin_id');

            // Resolve admin_id from deli_staff if deli_id provided
            if ($deliId !== null) {
                $staff = DB::table('loagma_new.deli_staff')
                    ->where('deli_id', (int) $deliId)
                    ->value('admin_id');
                if ($staff !== null) {
                    $adminId = $staff;
                }
            }

            if ($adminId === null) {
                return response()->json(['success' => false, 'message' => 'admin_id or deli_id required'], 422);
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
