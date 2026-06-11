# Sales Invoice API — LoagmaPMS

**Base URL (production):** `https://loagmapms-hd5u.onrender.com/api`

All endpoints require `Authorization: Bearer <token>` — obtain the token from `POST /api/auth/login`.

---

## Endpoints

### 1. Create Invoice (new order, billed immediately)

**`POST /api/sales-orders`**

Creates a new sales order with `status=billed`. If `admin_id` is provided, the PDF is generated automatically and the URL is returned.

**Request**
```http
POST https://loagmapms-hd5u.onrender.com/api/sales-orders
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "status": "billed",
  "customer_id": 1234,
  "doc_date": "2026-06-05",
  "admin_id": 1,
  "bill_number": "INV/26-27/001",
  "bill_dt": "2026-06-05",
  "doc_year": "26-27",
  "bill_roff": 0.50,
  "department": "Sales",
  "bill_narration": "June batch",
  "bill_vehicle": "GJ01AB1234",
  "bill_statement": "Payment due in 30 days.",
  "supplier_id": "SM001",
  "narration": "Order notes",
  "discount": 0,
  "delivery_charge": 0,
  "charges": [
    { "name": "Freight", "amount": 150.00, "remarks": "Road transport" }
  ],
  "items": [
    {
      "product_id": 42,
      "quantity": 10,
      "qty_loaded": 9,
      "price": 45.00,
      "hsn_code": "10063090",
      "unit": "Kg",
      "discount_percent": 0,
      "tax_percent": 5.0
    }
  ]
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `status` | string | Yes | Must be `"billed"` to generate invoice |
| `customer_id` | int | Yes | FK to user table |
| `doc_date` | date | Yes | `YYYY-MM-DD` |
| `admin_id` | int | No | Pass to auto-generate PDF and persist `pdf_url` |
| `bill_number` | string | No | If omitted, server auto-assigns next number |
| `bill_dt` | date | **Yes if billed** | Invoice date `YYYY-MM-DD` |
| `items` | array | Yes | Min 1 item — see item fields below |
| `charges` | array | No | Extra charges (freight, etc.) |

**Item fields**

| Field | Type | Required | Notes |
|---|---|---|---|
| `product_id` | int | Yes | |
| `quantity` | number | Yes | Ordered quantity |
| `price` | float | Yes | Unit price |
| `qty_loaded` | int | **Yes (for invoice)** | Invoice quantity — what was loaded/dispatched. Stored in `orders_item.qty_loaded`. Shown as "Inv Qty" on the PDF. |
| `hsn_code` | string | No | HSN/SAC code |
| `unit` | string | No | Unit of measure |
| `pack_id` | string | No | Pack ID |
| `discount_percent` | float | No | Line discount % |
| `tax_percent` | float | No | GST % — omit if price is GST-inclusive |

**Response `201`**
```json
{
  "success": true,
  "message": "Sales order created successfully",
  "pdf_url": "https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/26-27/INV_26-27_001.pdf",
  "data": {
    "id": 268100,
    "so_number": "ORD-268100",
    "status": "BILLED",
    "bill_number": "INV/26-27/001",
    "bill_dt": "2026-06-05",
    "customer_id": 1234,
    "customer_name": "Ramesh Traders",
    "total_amount": 450.00,
    "bill_roff": 0.50,
    "grand_total": 623.00,
    "pdf_url": "https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/26-27/INV_26-27_001.pdf",
    "charges": [{ "name": "Freight", "amount": 150.00, "remarks": "Road transport" }]
  }
}
```

> `pdf_url` is `null` if `admin_id` was not sent or PDF generation failed. The order is still saved.

---

### 2. Bulk Create Orders (multiple new orders, atomic)

**`POST /api/sales-orders/bulk`**

Creates multiple brand-new sales orders in a single all-or-nothing transaction. Each order has its own full payload (customer, items, billing fields). Use this when the orders don't exist yet.

**Request**
```http
POST https://loagmapms-hd5u.onrender.com/api/sales-orders/bulk
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "orders": [
    {
      "status": "billed",
      "customer_id": 1234,
      "doc_date": "2026-06-05",
      "bill_dt": "2026-06-05",
      "doc_year": "26-27",
      "bill_roff": 0,
      "items": [
        { "product_id": 42, "quantity": 10, "qty_loaded": 9, "price": 45.00, "tax_percent": 5.0 }
      ]
    },
    {
      "status": "billed",
      "customer_id": 5678,
      "doc_date": "2026-06-05",
      "bill_dt": "2026-06-05",
      "doc_year": "26-27",
      "bill_roff": 0,
      "items": [
        { "product_id": 55, "quantity": 5, "qty_loaded": 5, "price": 120.00, "tax_percent": 12.0 }
      ]
    }
  ]
}
```

Each object in `orders` accepts the same fields as `POST /api/sales-orders` (see endpoint 1). Invoice numbers are auto-assigned sequentially.

**Response `201`** — same shape as endpoint 1, `data` is an array of created orders. `pdf_url` is always `null` — call `GET /{id}/pdf` per order separately.

**Flutter client constant**: `ApiConfig.salesOrdersBulk`

---

### 3. Bulk Invoice Existing Orders (convert by order IDs)

**`POST /api/sales-orders/bulk-invoice`**

Takes existing orders (already saved as pending/dispatched/delivered) and converts them all to `billed` in one atomic transaction. Billing fields are shared across all orders. Items are taken from what's already saved on each order — no items array needed.

Use this for end-of-day invoicing where orders were created earlier in the day and now need to be bulk-billed.

**Request**
```http
POST https://loagmapms-hd5u.onrender.com/api/sales-orders/bulk-invoice
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "order_ids": [268080, 268081, 268082],
  "bill_dt": "2026-06-11",
  "doc_year": "26-27",
  "bill_roff": 0.50,
  "admin_id": 1,
  "department": "Sales",
  "bill_narration": "June batch",
  "bill_vehicle": "GJ01AB1234",
  "bill_statement": "Payment due in 30 days",
  "charges": [
    { "name": "Freight", "amount": 150.00, "remarks": "Road transport" }
  ]
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `order_ids` | int[] | Yes | IDs of existing orders to invoice |
| `bill_dt` | date | Yes | Invoice date `YYYY-MM-DD` applied to all |
| `doc_year` | string | No | e.g. `"26-27"` — defaults to current FY |
| `bill_roff` | float | No | Round-off amount applied to all |
| `admin_id` | int | No | Not used for PDF — call `GET /{id}/pdf` separately |
| `department` | string | No | Applied to all orders |
| `bill_narration` | string | No | Applied to all orders |
| `bill_vehicle` | string | No | Applied to all orders |
| `bill_statement` | string | No | Applied to all orders |
| `charges` | array | No | Extra charges applied to all orders |

**Response `200`**
```json
{
  "success": true,
  "message": "3 order(s) invoiced successfully",
  "data": [
    {
      "id": 268080,
      "so_number": "ORD-268080",
      "status": "BILLED",
      "bill_number": "INV/26-27/005",
      "bill_dt": "2026-06-11",
      "customer_id": 1234,
      "customer_name": "Ramesh Traders",
      "total_amount": 450.00,
      "pdf_url": null
    },
    { "...": "..." }
  ]
}
```

**Error responses**

| Code | Reason |
|---|---|
| `422` | `order_ids` empty, or `bill_dt` missing |
| `404` | One or more order IDs not found |
| `422` | Any order is already `billed` |
| `422` | Any order is in a closed state (`cancelled`, `rejected`, `returned`) |

**Atomicity**: all orders are updated in a single transaction. If any update fails, none are invoiced. Invoice numbers are assigned sequentially inside the transaction using `SELECT ... FOR UPDATE`.

**Flutter client constant**: `ApiConfig.salesOrdersBulkInvoice`

---

### 4. Update / Convert Existing Order to Invoice (single)

**`PUT /api/sales-orders/{id}`**

Converts an existing pending/dispatched/delivered sales order into a billed invoice.

**Request**
```http
PUT https://loagmapms-hd5u.onrender.com/api/sales-orders/268082
Authorization: Bearer <token>
Content-Type: application/json
```

```json
{
  "status": "billed",
  "admin_id": 1,
  "bill_number": "INV/26-27/002",
  "bill_dt": "2026-06-05",
  "doc_year": "26-27",
  "customer_id": 1234,
  "doc_date": "2026-06-01",
  "bill_roff": 0,
  "charges": [],
  "items": [
    {
      "product_id": 42,
      "quantity": 10,
      "qty_loaded": 9,
      "price": 45.00,
      "tax_percent": 5.0
    }
  ]
}
```

**Response `200`**
```json
{
  "success": true,
  "message": "Sales order updated successfully",
  "pdf_url": "https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/26-27/INV_26-27_002.pdf",
  "data": {
    "id": 268082,
    "status": "BILLED",
    "bill_number": "INV/26-27/002",
    "invoice_number": 2,
    "pdf_url": "https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/26-27/INV_26-27_002.pdf"
  }
}
```

**Error responses**
| Code | Reason |
|---|---|
| `404` | Order not found |
| `422` | Order is in a closed state (cancelled/rejected/returned) |
| `422` | `status=billed` but `bill_dt` is missing |

---

### 5. Generate / Re-generate PDF (on demand)

**`GET /api/sales-orders/{id}/pdf?admin_id={admin_id}`**

Regenerates the PDF for any existing billed invoice and saves it to disk. Use this to share the PDF link with a third party at any time — no re-invoicing needed.

**Request**
```http
GET https://loagmapms-hd5u.onrender.com/api/sales-orders/268082/pdf?admin_id=1
Authorization: Bearer <token>
```

| Query param | Type | Required | Notes |
|---|---|---|---|
| `admin_id` | int | Yes | Used to fetch company name, GST, bank details for the PDF header |

**Response `200`**
```json
{
  "success": true,
  "pdf_url": "https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/26-27/INV_26-27_002.pdf"
}
```

**Error responses**
| Code | Reason |
|---|---|
| `422` | `admin_id` not provided |
| `404` | Order not found |
| `422` | Order has no `bill_no` — not invoiced yet |
| `500` | Admin record not found, or PDF render error |

> The PDF file is overwritten each time this endpoint is called, so it always reflects the latest invoice data.

---

### 6. Get Order with PDF URL

**`GET /api/sales-orders/{id}`**

Returns full order detail. Includes `pdf_url` if a PDF has already been generated for this invoice.

**Request**
```http
GET https://loagmapms-hd5u.onrender.com/api/sales-orders/268082
Authorization: Bearer <token>
```

**Response `200`**
```json
{
  "success": true,
  "data": {
    "id": 268082,
    "so_number": "ORD-268082",
    "status": "BILLED",
    "bill_number": "INV/26-27/002",
    "invoice_number": 2,
    "bill_dt": "2026-06-05",
    "customer_name": "Ramesh Traders",
    "total_amount": 450.00,
    "pdf_url": "https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/26-27/INV_26-27_002.pdf",
    "charges": [],
    "items": [
      {
        "id": 8842,
        "product_name": "Basmati Rice",
        "hsn_code": "10063090",
        "unit": "Kg",
        "quantity": 10,
        "qty_loaded": 9,
        "used_qty": 0,
        "returned_qty": 0,
        "left_qty": 10,
        "available_quantity": 0,
        "price": 45.00,
        "line_total": 450.00
      }
    ]
  }
}
```

`pdf_url` is `null` if the PDF has not been generated yet for this invoice.

---

## PDF File Storage

```
server/storage/app/public/
  documents/
    sales-invoices/
      25-26/
        INV_25-26_001.pdf
        INV_25-26_002.pdf
      26-27/
        INV_26-27_001.pdf
```

Files are served publicly at:
```
https://loagmapms-hd5u.onrender.com/storage/documents/sales-invoices/{doc_year}/{filename}.pdf
```

No authentication is required to download the PDF file directly via the URL — share the link freely.

The URL is also stored in `orders.invoice_pdf_url` in the database, so `GET /api/sales-orders/{id}` always returns it in `data.pdf_url` without needing to check disk state.

---

## Item Quantity Fields Reference

Each item in `GET /api/sales-orders/{id}` returns all four quantity tracking columns:

| Response field | DB column | Set by | Meaning |
|---|---|---|---|
| `quantity` | `orders_item.quantity` | Order create/edit | What the customer originally ordered |
| `qty_loaded` | `orders_item.qty_loaded` | Invoice/billing | What was loaded onto the vehicle. **Shown as "Inv Qty" on the PDF.** |
| `used_qty` | `orders_item.qty_delivered` | Delivery confirmation flow | What was physically confirmed delivered — set post-delivery, never by order or invoice forms |
| `returned_qty` | `orders_item.qty_returned` | Sales return flow | What the customer sent back |
| `left_qty` | computed | — | `quantity − qty_delivered` |
| `available_quantity` | computed | — | `qty_delivered − qty_returned` — returnable quantity |

---

## Flutter Usage

```dart
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'controllers/auth_controller.dart';

// Single invoice
final res = await http.post(
  Uri.parse(ApiConfig.salesOrders),
  headers: AuthController.getHeaders,
  body: jsonEncode(orderPayload),
);

// Bulk invoices — all-or-nothing
final res = await http.post(
  Uri.parse(ApiConfig.salesOrdersBulk),
  headers: AuthController.getHeaders,
  body: jsonEncode({'orders': [order1, order2, ...]}),
);
final body = jsonDecode(res.body);
// body['data'] is a List of created orders

// On-demand PDF (after creation)
final pdfRes = await http.get(
  Uri.parse(ApiConfig.salesInvoicePdf(orderId)).replace(
    queryParameters: {'admin_id': '1'},
  ),
  headers: AuthController.getHeaders,
);
final pdfBody = jsonDecode(pdfRes.body);
final pdfUrl = pdfBody['pdf_url']; // open in browser or download
```
