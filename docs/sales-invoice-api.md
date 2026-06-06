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

### 2. Update / Convert Existing Order to Invoice

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

### 3. Generate / Re-generate PDF (on demand)

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

### 4. Get Order with PDF URL

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

// On-demand PDF
final response = await http.get(
  Uri.parse(ApiConfig.salesInvoicePdf(orderId)).replace(
    queryParameters: {'admin_id': '1'},
  ),
  headers: AuthController.getHeaders,
);
final body = jsonDecode(response.body);
final pdfUrl = body['pdf_url']; // open in browser or download
```
