<?php

namespace App\Services;

use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class InvoicePdfService
{
    private const ORDERS_TABLE = 'loagma_new.orders';
    private const ITEMS_TABLE  = 'loagma_new.orders_item';

    /**
     * Generate the invoice PDF for a sales order, persist it to public storage,
     * and return the publicly accessible URL.
     *
     * Returns null if the order is not found, not billed, or admin is not found.
     */
    public function generateAndStore(int $orderId, int $adminId): ?string
    {
        $data = $this->buildData($orderId, $adminId);
        if ($data === null) {
            return null;
        }

        $pdf = Pdf::loadView('pdf.sales-invoice', ['data' => $data])
            ->setPaper('a4', 'portrait');

        $docYear  = $data['doc_year'] ?? 'general';
        $filename = str_replace('/', '_', $data['bill_no']) . '.pdf';
        $path     = "documents/sales-invoices/{$docYear}/{$filename}";
        $dir      = "documents/sales-invoices/{$docYear}";

        if (!Storage::disk('public')->exists($dir)) {
            Storage::disk('public')->makeDirectory($dir);
        }

        Storage::disk('public')->put($path, $pdf->output());

        // asset() builds the URL from APP_URL correctly in all environments.
        // Storage::disk('public')->url() is equivalent but triggers a static-analysis
        // warning because the Filesystem contract does not declare url().
        return asset('storage/' . $path);
    }

    /**
     * Build the complete $data array required by the Blade template.
     */
    private function buildData(int $orderId, int $adminId): ?array
    {
        // ── 1. Fetch order header ────────────────────────────────────────────
        $order = DB::table(self::ORDERS_TABLE . ' as o')
            ->where('o.order_id', $orderId)
            ->leftJoin('loagma_new.LoginUser_crm as sm',
                DB::raw('CONVERT(sm.id USING utf8mb4) COLLATE utf8mb4_unicode_ci'),
                '=',
                DB::raw('CONVERT(o.salesman_id USING utf8mb4) COLLATE utf8mb4_unicode_ci')
            )
            ->select([
                'o.order_id', 'o.buyer_userid', 'o.order_state', 'o.order_total',
                'o.discount', 'o.delivery_charge', 'o.txn_id', 'o.short_datetime',
                'o.bill_no', 'o.invoice_number', 'o.Bill_Dt', 'o.Department',
                'o.Bill_Narration', 'o.Bill_Vehicle', 'o.Bill_Statement',
                'o.bill_roff', 'o.Doc_Year', 'o.salesman_id', 'o.charges_json',
                'sm.name as salesman_name',
            ])
            ->first();

        if (!$order || empty($order->bill_no)) {
            return null;
        }

        // ── 2. Fetch customer ────────────────────────────────────────────────
        $customer = DB::table('loagma_new.user')
            ->where('userid', $order->buyer_userid)
            ->select(['userid', 'name', 'contactno', 'state'])
            ->first();

        // ── 3. Fetch admin / org info ────────────────────────────────────────
        $admin = DB::table('loagma_new.admin')
            ->where('userid', $adminId)
            ->select([
                'userid', 'org_name', 'org_address', 'org_gst', 'fssai_no', 'gst_no',
                'bank_name', 'bank_branch', 'account_number', 'ifsc_code',
            ])
            ->first();

        if (!$admin) {
            return null;
        }

        // ── 4. Fetch line items + product info ───────────────────────────────
        $rawItems = DB::table(self::ITEMS_TABLE)
            ->where('order_id', $orderId)
            ->select(['item_id', 'product_id', 'quantity', 'item_price', 'item_total',
                      'qty_loaded', 'qty_delivered', 'qty_returned', 'pinfo'])
            ->get();

        $productIds = $rawItems->pluck('product_id')->filter()->unique()->values()->toArray();
        $productMap = [];
        if (!empty($productIds)) {
            DB::table('product')
                ->whereIn('product_id', $productIds)
                ->select(['product_id', 'name', 'hsn_code', 'packs', 'default_pack_id'])
                ->get()
                ->each(function ($p) use (&$productMap) {
                    $productMap[(int) $p->product_id] = [
                        'name'            => trim((string) ($p->name ?? '')),
                        'hsn_code'        => trim((string) ($p->hsn_code ?? '')),
                        'packs'           => $p->packs ?? null,
                        'default_pack_id' => $p->default_pack_id ?? null,
                    ];
                });
        }

        // ── 5. Tax split: SGST/CGST for same state, IGST for inter-state ────
        // Company state is derived from the GST number (chars 1-2 are the state code).
        // If GST is unavailable, $companyState stays empty and all tax defaults to IGST.
        $gstNo         = (string) ($admin->org_gst ?? $admin->gst_no ?? '');
        $companyState  = strlen($gstNo) >= 2 ? strtolower(substr($gstNo, 0, 2)) : '';
        $customerState = strtolower(trim((string) ($customer->state ?? '')));
        $sameState     = $companyState !== '' && $customerState !== ''
                         && $companyState === $customerState;

        // ── 6. Build items array ─────────────────────────────────────────────
        $items            = [];
        $subtotalExclTax  = 0.0;
        $taxTotal         = 0.0;

        foreach ($rawItems as $raw) {
            $pinfo = [];
            if (!empty($raw->pinfo)) {
                $decoded = json_decode((string) $raw->pinfo, true);
                if (is_array($decoded)) {
                    $pinfo = $decoded;
                }
            }

            $productId   = (int) $raw->product_id;
            $productInfo = $productMap[$productId] ?? [];

            $qty   = (float) ($raw->quantity ?? 0);
            $price = (float) ($raw->item_price ?? 0);
            // Fallback: derive unit price from item_total when item_price is missing
            if ($price <= 0 && $qty > 0) {
                $price = round((float) ($raw->item_total ?? 0) / $qty, 4);
            }

            $discPct    = (float) ($pinfo['discount_percent'] ?? 0);
            $taxPct     = (float) ($pinfo['tax_percent'] ?? 0);
            $usedQty    = (float) ($raw->qty_loaded ?? 0);

            $taxableAmt = round($qty * $price * (1 - $discPct / 100), 2);
            $lineTax    = round($taxableAmt * $taxPct / 100, 2);
            $lineTotal  = round($taxableAmt + $lineTax, 2);

            $subtotalExclTax += $taxableAmt;
            $taxTotal        += $lineTax;

            // Tax label
            if ($taxPct > 0) {
                if ($sameState) {
                    $half     = $taxPct / 2;
                    $taxLabel = "SGST {$half}%, CGST {$half}%";
                } else {
                    $taxLabel = "IGST {$taxPct}%";
                }
            } else {
                $taxLabel = 'Nil';
            }

            // Pack / unit label
            $packLabel = 'Nos';
            if (!empty($pinfo['selected_pack']) && is_array($pinfo['selected_pack'])) {
                $sp        = $pinfo['selected_pack'];
                $packLabel = (string) ($sp['unit'] ?? $sp['description'] ?? 'Nos');
            } elseif (!empty($pinfo['unit'])) {
                $packLabel = (string) $pinfo['unit'];
            }

            // Product name + HSN (product table is authoritative)
            $productName = $productInfo['name'] ?? trim((string) ($pinfo['name'] ?? $pinfo['product_name'] ?? ''));
            if ($productName === '') {
                $productName = 'Product ' . $productId;
            }
            $hsnCode = $productInfo['hsn_code'] ?? ($pinfo['hsn_code'] ?? null);

            $items[] = [
                'product_name'     => $productName,
                'hsn_code'         => $hsnCode,
                'pack_label'       => $packLabel,
                'quantity'         => $qty,
                'used_qty'         => $usedQty,
                'price'            => $price,
                'discount_percent' => $discPct,
                'tax_label'        => $taxLabel,
                'taxable_amount'   => $taxableAmt,
                'line_total'       => $lineTotal,
            ];
        }

        // ── 7. Charges ───────────────────────────────────────────────────────
        $charges      = [];
        $chargesTotal = 0.0;
        if (!empty($order->charges_json)) {
            $decoded = json_decode((string) $order->charges_json, true);
            if (is_array($decoded)) {
                foreach ($decoded as $c) {
                    $amt           = (float) ($c['amount'] ?? 0);
                    $chargesTotal += $amt;
                    $charges[]     = [
                        'name'    => (string) ($c['name'] ?? ''),
                        'amount'  => $amt,
                        'remarks' => (string) ($c['remarks'] ?? ''),
                    ];
                }
            }
        }

        // ── 8. Grand total ───────────────────────────────────────────────────
        $billRoff   = (float) ($order->bill_roff ?? 0);
        $grandTotal = round($subtotalExclTax + $taxTotal + $chargesTotal + $billRoff, 2);

        // ── 9. Assemble final data array ─────────────────────────────────────
        return [
            // Org / company
            'org_name'       => $admin->org_name ?? '',
            'org_address'    => $admin->org_address ?? '',
            'org_gst'        => $admin->org_gst ?? $admin->gst_no ?? '',
            'fssai_no'       => $admin->fssai_no ?? '',
            'bank_name'      => $admin->bank_name ?? '',
            'bank_branch'    => $admin->bank_branch ?? '',
            'account_number' => $admin->account_number ?? '',
            'ifsc_code'      => $admin->ifsc_code ?? '',

            // Invoice header
            'bill_no'        => $order->bill_no,
            'bill_dt'        => $order->Bill_Dt,
            'doc_year'       => $order->Doc_Year ?? '',
            'so_number'      => 'ORD-' . $order->order_id,
            'doc_date'       => $this->parseDate($order->short_datetime ?? ''),
            'customer_name'  => $customer->name ?? '',
            'customer_phone' => $customer->contactno ?? '',
            'salesman_name'  => $order->salesman_name ?? '',
            'department'     => $order->Department ?? null,
            'bill_vehicle'   => $order->Bill_Vehicle ?? null,
            'narration'      => $order->Bill_Narration ?? null,
            'bill_statement' => $order->Bill_Statement ?? null,

            // Items
            'items' => $items,

            // Charges
            'charges' => $charges,

            // Totals
            'subtotal_excl_tax' => round($subtotalExclTax, 2),
            'tax_total'         => round($taxTotal, 2),
            'charges_total'     => round($chargesTotal, 2),
            'bill_roff'         => $billRoff,
            'grand_total'       => $grandTotal,
        ];
    }

    private function parseDate(string $raw): string
    {
        $raw = trim($raw);
        if ($raw === '') {
            return date('Y-m-d');
        }
        $ts = strtotime($raw);
        return $ts !== false ? date('Y-m-d', $ts) : date('Y-m-d');
    }
}
