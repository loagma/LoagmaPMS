<?php

namespace App\Http\Controllers;

use App\Models\SalesInvoice;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SalesInvoiceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = SalesInvoice::query()->orderByDesc('id');

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $query->where(function ($q) use ($search): void {
                $q->where('invoice_no', 'like', "%{$search}%")
                    ->orWhere('id', $search);
            });
        }

        return response()->json([
            'success' => true,
            'data' => $query->paginate((int) $request->input('per_page', 25)),
        ]);
    }

    public function show(int $id): JsonResponse
    {
        $invoice = SalesInvoice::query()->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $invoice,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $invoice = DB::transaction(function () use ($validated): SalesInvoice {
            return SalesInvoice::query()->create([
                'invoice_no' => trim((string) $validated['invoice_no']),
                'order_id' => (int) $validated['order_id'],
                'customer_user_id' => $validated['customer_user_id'] ?? null,
                'invoice_date' => $validated['invoice_date'],
                'due_date' => $validated['due_date'] ?? null,
                'invoice_status' => $validated['invoice_status'] ?? 'DRAFT',
                'payment_status' => $validated['payment_status'] ?? 'PENDING',
                'subtotal' => (float) ($validated['subtotal'] ?? 0),
                'discount_total' => (float) ($validated['discount_total'] ?? 0),
                'delivery_charge' => (float) ($validated['delivery_charge'] ?? 0),
                'tax_total' => (float) ($validated['tax_total'] ?? 0),
                'grand_total' => (float) ($validated['grand_total'] ?? 0),
                'notes' => $validated['notes'] ?? null,
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Sales invoice created successfully',
            'data' => $invoice,
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $this->validatePayload($request, $id);

        $invoice = DB::transaction(function () use ($validated, $id): SalesInvoice {
            $invoice = SalesInvoice::query()->findOrFail($id);

            $invoice->update([
                'invoice_no' => trim((string) $validated['invoice_no']),
                'order_id' => (int) $validated['order_id'],
                'customer_user_id' => $validated['customer_user_id'] ?? null,
                'invoice_date' => $validated['invoice_date'],
                'due_date' => $validated['due_date'] ?? null,
                'invoice_status' => $validated['invoice_status'] ?? 'DRAFT',
                'payment_status' => $validated['payment_status'] ?? 'PENDING',
                'subtotal' => (float) ($validated['subtotal'] ?? 0),
                'discount_total' => (float) ($validated['discount_total'] ?? 0),
                'delivery_charge' => (float) ($validated['delivery_charge'] ?? 0),
                'tax_total' => (float) ($validated['tax_total'] ?? 0),
                'grand_total' => (float) ($validated['grand_total'] ?? 0),
                'notes' => array_key_exists('notes', $validated) ? $validated['notes'] : $invoice->notes,
            ]);

            return $invoice->fresh();
        });

        return response()->json([
            'success' => true,
            'message' => 'Sales invoice updated successfully',
            'data' => $invoice,
        ]);
    }

    public function destroy(int $id): JsonResponse
    {
        SalesInvoice::query()->findOrFail($id)->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sales invoice deleted successfully',
        ]);
    }

    private function validatePayload(Request $request, ?int $ignoreId = null): array
    {
        $invoiceUnique = 'unique:sales_invoices,invoice_no';
        if ($ignoreId !== null) {
            $invoiceUnique .= ',' . $ignoreId;
        }

        return $request->validate([
            'invoice_no' => ['required', 'string', 'max:50', $invoiceUnique],
            'order_id' => ['required', 'integer', 'exists:orders,order_id'],
            'customer_user_id' => ['nullable', 'integer'],
            'invoice_date' => ['required', 'date'],
            'due_date' => ['nullable', 'date'],
            'invoice_status' => ['nullable', 'in:DRAFT,ISSUED,CANCELLED'],
            'payment_status' => ['nullable', 'in:PENDING,PARTIAL,PAID'],
            'subtotal' => ['nullable', 'numeric', 'min:0'],
            'discount_total' => ['nullable', 'numeric', 'min:0'],
            'delivery_charge' => ['nullable', 'numeric', 'min:0'],
            'tax_total' => ['nullable', 'numeric', 'min:0'],
            'grand_total' => ['nullable', 'numeric', 'min:0'],
            'notes' => ['nullable', 'string'],
        ]);
    }
}
