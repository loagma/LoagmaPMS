<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<title>Tax Invoice {{ $data['bill_no'] ?? '' }}</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: DejaVu Sans, sans-serif; font-size: 8.5pt; color: #1a1a1a; }

  /* ── Header ── */
  .header { background: #1e293b; color: #fff; padding: 10px 12px; }
  .header-inner { display: flex; justify-content: space-between; align-items: flex-start; }
  .header-left .org-name { font-size: 14pt; font-weight: bold; letter-spacing: 0.5px; }
  .header-left .org-meta { font-size: 7.5pt; color: #cbd5e1; margin-top: 3px; line-height: 1.5; }
  .header-right { text-align: right; }
  .header-right .doc-type { font-size: 13pt; font-weight: bold; letter-spacing: 1px; color: #f8fafc; }
  .header-right .doc-meta { font-size: 8pt; color: #cbd5e1; margin-top: 4px; line-height: 1.6; }

  /* ── Info boxes ── */
  .info-row { display: flex; border-bottom: 1px solid #e2e8f0; }
  .info-box { flex: 1; padding: 8px 10px; border-right: 1px solid #e2e8f0; }
  .info-box:last-child { border-right: none; }
  .info-box .box-title { font-size: 7pt; font-weight: bold; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 5px; }
  .info-box .line { font-size: 8.5pt; line-height: 1.6; color: #1e293b; }
  .info-box .line span { color: #475569; font-size: 7.5pt; }

  /* ── Items table ── */
  .items-section { padding: 0; }
  table.items { width: 100%; border-collapse: collapse; }
  table.items thead tr { background: #334155; color: #fff; }
  table.items thead th { padding: 5px 4px; font-size: 7.5pt; font-weight: bold; text-align: center; border: 1px solid #475569; }
  table.items tbody tr { border-bottom: 1px solid #e2e8f0; }
  table.items tbody tr:nth-child(even) { background: #f8fafc; }
  table.items tbody td { padding: 5px 4px; font-size: 8pt; vertical-align: middle; border: 1px solid #e2e8f0; }
  table.items tfoot tr { background: #f1f5f9; font-weight: bold; }
  table.items tfoot td { padding: 5px 4px; font-size: 8pt; border: 1px solid #cbd5e1; }

  .col-no     { width: 3%;  text-align: center; }
  .col-prod   { width: 22%; }
  .col-hsn    { width: 8%;  text-align: center; }
  .col-pack   { width: 7%;  text-align: center; }
  .col-soqty  { width: 6%;  text-align: center; }
  .col-invqty { width: 6%;  text-align: center; }
  .col-rate   { width: 8%;  text-align: right; }
  .col-disc   { width: 6%;  text-align: center; }
  .col-tax    { width: 14%; text-align: center; }
  .col-taxamt { width: 9%;  text-align: right; }
  .col-total  { width: 11%; text-align: right; }

  .text-right { text-align: right; }
  .text-center { text-align: center; }

  /* ── Charges + Summary ── */
  .bottom-section { display: flex; border-top: 2px solid #334155; }
  .charges-col { width: 45%; padding: 8px 10px; border-right: 1px solid #e2e8f0; }
  .charges-col .section-title { font-size: 7pt; font-weight: bold; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px; }
  .charge-row { display: flex; justify-content: space-between; padding: 2px 0; font-size: 8pt; border-bottom: 1px solid #f1f5f9; }
  .charge-row .remarks { font-size: 7pt; color: #94a3b8; }

  .summary-col { width: 55%; padding: 8px 12px; }
  .summary-row { display: flex; justify-content: space-between; padding: 2.5px 0; font-size: 8.5pt; border-bottom: 1px solid #f1f5f9; }
  .summary-row.grand { font-size: 10pt; font-weight: bold; color: #1e293b; border-top: 2px solid #334155; border-bottom: none; padding-top: 5px; margin-top: 2px; }
  .summary-label { color: #475569; }
  .summary-value { font-weight: 500; }

  /* ── Bank + Terms ── */
  .footer-section { border-top: 1px solid #e2e8f0; padding: 7px 10px; }
  .footer-title { font-size: 7pt; font-weight: bold; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px; }
  .bank-row { font-size: 8pt; color: #1e293b; line-height: 1.7; }
  .terms-text { font-size: 7.5pt; color: #475569; line-height: 1.5; white-space: pre-wrap; }

  .outer-border { border: 1px solid #cbd5e1; }
</style>
</head>
<body>
<div class="outer-border">

  {{-- ── HEADER ── --}}
  <div class="header">
    <div class="header-inner">
      <div class="header-left">
        <div class="org-name">{{ $data['org_name'] ?? '—' }}</div>
        <div class="org-meta">
          {{ $data['org_address'] ?? '' }}<br>
          @if(!empty($data['org_gst']))GST: {{ $data['org_gst'] }}@endif
          @if(!empty($data['fssai_no']))&nbsp;&nbsp;FSSAI: {{ $data['fssai_no'] }}@endif
        </div>
      </div>
      <div class="header-right">
        <div class="doc-type">TAX INVOICE</div>
        <div class="doc-meta">
          Invoice No: {{ $data['bill_no'] ?? '—' }}<br>
          Date: {{ \Carbon\Carbon::parse($data['bill_dt'] ?? now())->format('d M Y') }}<br>
          FY: {{ $data['doc_year'] ?? '—' }}
        </div>
      </div>
    </div>
  </div>

  {{-- ── BILL TO + INVOICE DETAILS ── --}}
  <div class="info-row">
    <div class="info-box" style="width:40%">
      <div class="box-title">Bill To</div>
      @if(!empty($data['customer_name']))
        <div class="line"><strong>{{ $data['customer_name'] }}</strong></div>
      @endif
      @if(!empty($data['customer_phone']))
        <div class="line"><span>Phone:</span> {{ $data['customer_phone'] }}</div>
      @endif
    </div>
    <div class="info-box" style="width:60%">
      <div class="box-title">Invoice Details</div>
      <div style="display:flex; gap:16px;">
        <div style="flex:1">
          <div class="line"><span>Invoice No:</span> {{ $data['bill_no'] ?? '—' }}</div>
          <div class="line"><span>Invoice Date:</span> {{ \Carbon\Carbon::parse($data['bill_dt'] ?? now())->format('d M Y') }}</div>
          @if(!empty($data['doc_date']))
            <div class="line"><span>Order Date:</span> {{ \Carbon\Carbon::parse($data['doc_date'] ?? now())->format('d M Y') }}</div>
          @endif
          @if(!empty($data['so_number']))
            <div class="line"><span>SO#:</span> {{ $data['so_number'] }}</div>
          @endif
        </div>
        <div style="flex:1">
          @if(!empty($data['salesman_name']))
            <div class="line"><span>Salesman:</span> {{ $data['salesman_name'] }}</div>
          @endif
          @if(!empty($data['department']))
            <div class="line"><span>Dept:</span> {{ $data['department'] }}</div>
          @endif
          @if(!empty($data['bill_vehicle']))
            <div class="line"><span>Vehicle:</span> {{ $data['bill_vehicle'] }}</div>
          @endif
          @if(!empty($data['narration']))
            <div class="line"><span>Note:</span> {{ $data['narration'] }}</div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ── ITEMS TABLE ── --}}
  <div class="items-section">
    <table class="items">
      <thead>
        <tr>
          <th class="col-no">#</th>
          <th class="col-prod" style="text-align:left">Product</th>
          <th class="col-hsn">HSN</th>
          <th class="col-pack">Pack/Unit</th>
          <th class="col-soqty">SO Qty</th>
          <th class="col-invqty">Inv Qty</th>
          <th class="col-rate">Rate</th>
          <th class="col-disc">Disc%</th>
          <th class="col-tax">Tax</th>
          <th class="col-taxamt">Taxable Amt</th>
          <th class="col-total">Line Total</th>
        </tr>
      </thead>
      <tbody>
        @foreach($data['items'] ?? [] as $i => $item)
        <tr>
          <td class="col-no">{{ $i + 1 }}</td>
          <td class="col-prod">{{ $item['product_name'] ?? '—' }}</td>
          <td class="col-hsn">{{ $item['hsn_code'] ?? '—' }}</td>
          <td class="col-pack">{{ $item['pack_label'] ?? $item['unit'] ?? '—' }}</td>
          <td class="col-soqty">{{ number_format($item['quantity'] ?? 0, ($item['quantity'] == floor($item['quantity'] ?? 0)) ? 0 : 2) }}</td>
          <td class="col-invqty">{{ number_format($item['used_qty'] ?? 0, ($item['used_qty'] == floor($item['used_qty'] ?? 0)) ? 0 : 2) }}</td>
          <td class="col-rate">{{ number_format($item['price'] ?? 0, 2) }}</td>
          <td class="col-disc">{{ $item['discount_percent'] > 0 ? number_format($item['discount_percent'], 1).'%' : '—' }}</td>
          <td class="col-tax" style="font-size:7.5pt">{{ $item['tax_label'] ?? '—' }}</td>
          <td class="col-taxamt">{{ number_format($item['taxable_amount'] ?? 0, 2) }}</td>
          <td class="col-total"><strong>{{ number_format($item['line_total'] ?? 0, 2) }}</strong></td>
        </tr>
        @endforeach
      </tbody>
      <tfoot>
        <tr>
          <td colspan="9" class="text-right" style="padding-right:6px; color:#475569; font-size:7.5pt">Totals</td>
          <td class="col-taxamt text-right">{{ number_format($data['subtotal_excl_tax'] ?? 0, 2) }}</td>
          <td class="col-total text-right">{{ number_format(($data['subtotal_excl_tax'] ?? 0) + ($data['tax_total'] ?? 0), 2) }}</td>
        </tr>
      </tfoot>
    </table>
  </div>

  {{-- ── CHARGES + SUMMARY ── --}}
  <div class="bottom-section">
    <div class="charges-col">
      @if(!empty($data['charges']))
        <div class="section-title">Charges</div>
        @foreach($data['charges'] as $charge)
          <div class="charge-row">
            <span>{{ $charge['name'] }}</span>
            <span>
              Rs.{{ number_format($charge['amount'] ?? 0, 2) }}
              @if(!empty($charge['remarks']))<span class="remarks"> ({{ $charge['remarks'] }})</span>@endif
            </span>
          </div>
        @endforeach
      @else
        <div style="color:#94a3b8; font-size:7.5pt; padding-top:4px;">No additional charges</div>
      @endif
    </div>
    <div class="summary-col">
      <div class="summary-row">
        <span class="summary-label">Subtotal (excl. tax)</span>
        <span class="summary-value">Rs.{{ number_format($data['subtotal_excl_tax'] ?? 0, 2) }}</span>
      </div>
      <div class="summary-row">
        <span class="summary-label">Tax</span>
        <span class="summary-value">Rs.{{ number_format($data['tax_total'] ?? 0, 2) }}</span>
      </div>
      @if(($data['charges_total'] ?? 0) != 0)
      <div class="summary-row">
        <span class="summary-label">Charges</span>
        <span class="summary-value">Rs.{{ number_format($data['charges_total'], 2) }}</span>
      </div>
      @endif
      @if(($data['bill_roff'] ?? 0) != 0)
      <div class="summary-row">
        <span class="summary-label">Round-off</span>
        <span class="summary-value">{{ $data['bill_roff'] >= 0 ? '+' : '' }}{{ number_format($data['bill_roff'], 2) }}</span>
      </div>
      @endif
      <div class="summary-row grand">
        <span>GRAND TOTAL</span>
        <span>Rs.{{ number_format($data['grand_total'] ?? 0, 2) }}</span>
      </div>
    </div>
  </div>

  {{-- ── BANK DETAILS ── --}}
  @if(!empty($data['bank_name']) || !empty($data['account_number']))
  <div class="footer-section" style="border-top: 1px solid #e2e8f0;">
    <div class="footer-title">Bank Details</div>
    <div class="bank-row">
      @if(!empty($data['bank_name']))<strong>{{ $data['bank_name'] }}</strong>@endif
      @if(!empty($data['bank_branch'])) &nbsp;|&nbsp; Branch: {{ $data['bank_branch'] }}@endif
      @if(!empty($data['account_number'])) &nbsp;|&nbsp; A/C: {{ $data['account_number'] }}@endif
      @if(!empty($data['ifsc_code'])) &nbsp;|&nbsp; IFSC: {{ $data['ifsc_code'] }}@endif
    </div>
  </div>
  @endif

  {{-- ── TERMS & CONDITIONS ── --}}
  @if(!empty($data['bill_statement']))
  <div class="footer-section" style="border-top: 1px solid #e2e8f0;">
    <div class="footer-title">Terms &amp; Conditions</div>
    <div class="terms-text">{{ $data['bill_statement'] }}</div>
  </div>
  @endif

</div>
</body>
</html>
