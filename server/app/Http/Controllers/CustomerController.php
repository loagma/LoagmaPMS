<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CustomerController extends Controller
{
    private const TABLE = 'loagma_new.user';

    public function index(Request $request): JsonResponse
    {
        try {
            $limit = max(1, min((int) $request->input('limit', 20), 200));
            $page = max(1, (int) $request->input('page', 1));

            $query = DB::table(self::TABLE);
            $this->applySearch($query, (string) $request->input('search', ''));
            $this->applyDefaultOrder($query);

            $total = $query->count();
            $rows = $query
                ->offset(($page - 1) * $limit)
                ->limit($limit)
                ->get();

            return response()->json([
                'success' => true,
                'data' => $rows->map(fn ($row) => $this->normalizeRow($row))->values(),
                'pagination' => [
                    'total' => $total,
                    'page' => $page,
                    'limit' => $limit,
                    'pages' => (int) ceil($total / $limit),
                ],
            ]);
        } catch (\Throwable $e) {
            Log::error('Customers fetch error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch customers',
            ], 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        try {
            $row = DB::table(self::TABLE)->where('userid', $id)->first();

            if (!$row) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer not found',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'data' => $this->normalizeRow($row),
            ]);
        } catch (\Throwable $e) {
            Log::error('Customer show error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Customer not found',
            ], 404);
        }
    }

    public function store(Request $request): JsonResponse
    {
        try {
            $payload = $this->buildPayload($request);
            $payload = $this->filterToExistingColumns($payload, true);

            if (empty($payload['name']) && empty($payload['shop_name'])) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer name is required',
                ], 422);
            }

            $id = DB::table(self::TABLE)->insertGetId($payload, 'userid');

            return response()->json([
                'success' => true,
                'message' => 'Customer created successfully',
                'data' => $this->normalizeRow(
                    DB::table(self::TABLE)->where('userid', $id)->first()
                ),
            ], 201);
        } catch (\Throwable $e) {
            Log::error('Customer store error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to create customer',
            ], 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        try {
            $payload = $this->buildPayload($request, true);
            $payload = $this->filterToExistingColumns($payload, false);

            if (!empty($payload)) {
                DB::table(self::TABLE)->where('userid', $id)->update($payload);
            }

            $row = DB::table(self::TABLE)->where('userid', $id)->first();

            if (!$row) {
                return response()->json([
                    'success' => false,
                    'message' => 'Customer not found',
                ], 404);
            }

            return response()->json([
                'success' => true,
                'message' => 'Customer updated successfully',
                'data' => $this->normalizeRow($row),
            ]);
        } catch (\Throwable $e) {
            Log::error('Customer update error: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'Failed to update customer',
            ], 500);
        }
    }

    private function applySearch($query, string $search): void
    {
        $search = trim($search);
        if ($search === '') {
            return;
        }

        // Columns that hold text — searched with LIKE %term%
        $textCols = $this->existingColumns([
            'name',
            'shop_name',
            'phone',
            'mobile',
            'contact_number',
            'email',
        ]);

        $like = '%' . addcslashes($search, '\\%_') . '%';

        $query->where(function ($q) use ($search, $textCols, $like) {
            // Exact or prefix match on numeric customer ID
            if (is_numeric($search)) {
                $q->orWhere('userid', (int) $search);
                // Also prefix-match so typing "10" finds ID 100, 101 etc.
                $q->orWhereRaw('CAST(userid AS CHAR) LIKE ?', [$search . '%']);
            }

            // Phone number: also try prefix match (user may type first digits)
            foreach ($textCols as $col) {
                if (in_array($col, ['phone', 'mobile', 'contact_number'], true)) {
                    // Prefix match for phone
                    $q->orWhereRaw("LOWER(`$col`) LIKE ?", [strtolower($search) . '%']);
                    // Full substring match
                    $q->orWhereRaw("LOWER(`$col`) LIKE ?", [$like]);
                } else {
                    // Name / shop / email — substring match, case-insensitive
                    $q->orWhereRaw("LOWER(`$col`) LIKE ?", ['%' . strtolower(addcslashes($search, '\\%_')) . '%']);
                }
            }
        });
    }

    private function applyDefaultOrder($query): void
    {
        $ordered = false;
        foreach (['shop_name', 'name', 'userid'] as $column) {
            if (in_array($column, $this->existingColumns([$column]), true)) {
                $query->orderBy($column);
                $ordered = true;
                break;
            }
        }

        if (!$ordered) {
            $query->orderBy('userid', 'desc');
        }
    }

    private function buildPayload(Request $request, bool $isUpdate = false): array
    {
        $payload = [];

        $name = trim((string) $request->input('name', ''));
        if ($name !== '') {
            $payload['name'] = $name;
        }

        $shopName = trim((string) ($request->input('shop_name') ?? $request->input('shopName', '')));
        if ($shopName !== '') {
            $payload['shop_name'] = $shopName;
        }

        $email = trim((string) $request->input('email', ''));
        if ($email !== '') {
            $payload['email'] = $email;
        }

        $phone = trim((string) (
            $request->input('phone')
            ?? $request->input('contactNumber')
            ?? $request->input('contact_number')
            ?? ''
        ));
        if ($phone !== '') {
            $payload['phone'] = $phone;
        }

        $alternatePhone = trim((string) (
            $request->input('alternate_phone')
            ?? $request->input('alternatePhone')
            ?? ''
        ));
        if ($alternatePhone !== '') {
            $payload['alternate_phone'] = $alternatePhone;
        }

        $gstNo = trim((string) ($request->input('gst_no') ?? $request->input('gstNo', '')));
        if ($gstNo !== '') {
            $payload['gst_no'] = $gstNo;
        }

        $panNo = trim((string) ($request->input('pan_no') ?? $request->input('panNo', '')));
        if ($panNo !== '') {
            $payload['pan_no'] = $panNo;
        }

        $addressLine1 = trim((string) (
            $request->input('address_line1')
            ?? $request->input('addressLine1')
            ?? $request->input('address', '')
        ));
        if ($addressLine1 !== '') {
            $payload['address_line1'] = $addressLine1;
        }

        foreach (['city', 'state', 'country', 'pincode', 'notes', 'status', 'latitude', 'longitude', 'dob', 'register_date'] as $field) {
            $value = $request->input($field);
            if ($value !== null && $value !== '') {
                $payload[$field] = $value;
            }
        }

        if (!$isUpdate && array_key_exists('status', $payload) === false) {
            $payload['status'] = 'ACTIVE';
        }

        if (in_array('role', $this->existingColumns(['role']), true)) {
            $payload['role'] = $request->input('role', 'Customer');
        }

        return $payload;
    }

    private function filterToExistingColumns(array $payload, bool $forInsert): array
    {
        $existing = array_flip($this->existingColumns(array_keys($payload)));

        if (empty($existing)) {
            return $payload;
        }

        $filtered = array_intersect_key($payload, $existing);

        if ($forInsert && isset($filtered['status']) && $filtered['status'] === '') {
            $filtered['status'] = 'ACTIVE';
        }

        return $filtered;
    }

    private function normalizeRow(object $row): array
    {
        $data = json_decode(json_encode($row), true) ?: [];

        $id = $data['userid'] ?? $data['id'] ?? null;
        if ($id !== null) {
            $data['id'] = is_numeric($id) ? (int) $id : $id;
            $data['userid'] = $data['id'];
        }

        $data['name'] = trim((string) ($data['name'] ?? $data['shop_name'] ?? ''));
        $data['shop_name'] = trim((string) ($data['shop_name'] ?? ''));
        $data['phone'] = trim((string) ($data['phone'] ?? $data['mobile'] ?? $data['contact_number'] ?? ''));
        $data['email'] = trim((string) ($data['email'] ?? ''));
        $data['alternate_phone'] = trim((string) ($data['alternate_phone'] ?? ''));
        $data['gst_no'] = trim((string) ($data['gst_no'] ?? ''));
        $data['pan_no'] = trim((string) ($data['pan_no'] ?? ''));
        $data['address_line1'] = trim((string) ($data['address_line1'] ?? $data['address'] ?? ''));
        $data['city'] = trim((string) ($data['city'] ?? ''));
        $data['state'] = trim((string) ($data['state'] ?? ''));
        $data['country'] = trim((string) ($data['country'] ?? ''));
        $data['pincode'] = trim((string) ($data['pincode'] ?? ''));
        $data['notes'] = trim((string) ($data['notes'] ?? ''));
        $data['latitude'] = $data['latitude'] ?? null;
        $data['longitude'] = $data['longitude'] ?? null;
        $data['dob'] = $data['dob'] ?? null;
        $data['register_date'] = $data['register_date'] ?? null;
        $data['status'] = strtoupper(trim((string) ($data['status'] ?? 'ACTIVE'))) ?: 'ACTIVE';
        $data['display_name'] = trim(implode(' • ', array_values(array_filter([
            $data['name'] ?: null,
            $data['shop_name'] ?: null,
            $data['phone'] ?: null,
        ]))));

        foreach (['password', 'remember_token', 'otp', 'api_token', 'token'] as $hidden) {
            unset($data[$hidden]);
        }

        return $data;
    }

    private function existingColumns(array $candidates): array
    {
        static $columns = null;

        if ($columns === null) {
            try {
                $rows = DB::select('SHOW COLUMNS FROM `loagma_new`.`user`');
                $columns = array_map(
                    fn ($row) => strtolower((string) ($row->Field ?? '')),
                    $rows
                );
            } catch (\Throwable $e) {
                $columns = [];
            }
        }

        $normalized = array_map('strtolower', $candidates);
        if (empty($columns)) {
            return array_values(array_intersect($normalized, ['userid', 'name']));
        }

        return array_values(array_intersect($normalized, $columns));
    }
}
