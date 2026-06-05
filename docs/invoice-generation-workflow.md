# Invoice Generation Workflow — LoagmaPMS

**Stack:** Flutter (GetX) + Laravel 11 + MySQL (legacy `loagma_new` schema)
**Purpose:** Complete reference for how a sales invoice is created, edited, and cancelled — every database column, state transition, and data flow explained.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Database Schema — All Affected Columns](#2-database-schema--all-affected-columns)
3. [Order State Machine](#3-order-state-machine)
4. [Step-by-Step Workflow](#4-step-by-step-workflow)
5. [Editing an Invoice — What Actually Happens to Each Column](#5-editing-an-invoice--what-actually-happens-to-each-column)
6. [Cancel Invoice Flow](#6-cancel-invoice-flow)

---

## 1. Overview

An "invoice" in LoagmaPMS is **not a separate record** — it is a sales order that has been formally billed. There is no `invoices` table. A sales order becomes an invoice by:

1. Setting `orders.order_state = 'billed'`
2. Writing an invoice number string (e.g. `INV/25-26/001`) into `orders.bill_no`
3. Writing billing metadata (`Bill_Dt`, `Department`, `Bill_Narration`, etc.) into the same `orders` row

Everything lives in **one row** of `loagma_new.orders`. Line items live in `loagma_new.orders_item`.

**Two creation paths:**
- **Path A** — Convert an existing sales order to billed: `PUT /api/sales-orders/{id}` with `status=billed`
- **Path B** — Create a brand-new order that is immediately billed: `POST /api/sales-orders` with `status=billed`

Both paths execute identical DB writes. The only difference is INSERT vs UPDATE on the `orders` row.

---

## 2. Database Schema — All Affected Columns

### `loagma_new.orders` — one row per sales order / invoice

> This is a legacy table not created by Laravel migrations. Migrations only ADD columns to it.

#### Core order columns (pre-existing in legacy table)

| Column | Type | Description |
|---|---|---|
| `order_id` | INT PK | Primary key, auto-increment |
| `buyer_userid` | INT | Customer FK → `loagma_new.user.userid` |
| `order_state` | VARCHAR | Current lifecycle state — see state machine |
| `order_total` | DECIMAL | Server-computed: `Σ(qty × price) − discount + delivery_charge` |
| `discount` | DECIMAL | Order-level flat discount amount |
| `delivery_charge` | DECIMAL | Delivery fee added to total |
| `items_count` | INT | Count of line items in `orders_item` |
| `txn_id` | VARCHAR | Narration / internal notes |
| `short_datetime` | DATETIME | Order creation timestamp — never updated after create |
| `bill_number` | INT | Legacy integer field — not used for the invoice string, kept for old app compatibility |
| `salesman_id` | VARCHAR(191) | Salesman assigned to this order, FK → `LoginUser_crm.id` |

#### Invoice columns (added by Laravel migrations)

| Column | Type | Description | NULL means |
|---|---|---|---|
| `bill_no` | VARCHAR(100) | Invoice number string e.g. `INV/25-26/001` | Not yet invoiced |
| `invoice_number` | INT UNSIGNED | Sequential integer used for race-safe number generation (e.g. `1`, `2`, `3`) | Not yet invoiced or manual override |
| `Bill_Dt` | DATE | Date the invoice was raised | Not yet invoiced |
| `Department` | VARCHAR(100) | Department that raised the invoice | Not filled |
| `Bill_Narration` | TEXT | Free-text narration printed on invoice | Not filled |
| `Bill_Vehicle` | VARCHAR(100) | Vehicle / transport number for delivery | Not filled |
| `Bill_Statement` | VARCHAR(100) | Statement or challan reference | Not filled |
| `bill_roff` | DECIMAL(10,2) | Round-off paise adjustment (e.g. `+0.50`), default `0` | Always written |
| `Doc_Year` | VARCHAR(20) | Financial year label e.g. `'25-26'` — auto-derived from system date if not sent | Not filled |
| `charges_json` | JSON | Charges array (freight, handling, etc.) persisted so they reload on re-open | NULL = no charges |

#### Sales return columns (same `orders` row — populated later, not during invoicing)

| Column | Type | Description |
|---|---|---|
| `Sales_Return_VoucherNo` | VARCHAR(100) | Set when a sales return is created against this invoice |
| `Sales_Return_Dt` | DATE | Date of the return |
| `Sales_Return_Reason` | TEXT | Reason text for the return |

---

### `loagma_new.orders_item` — one row per line item

> **On every invoice save — creation or edit — all existing `orders_item` rows for that `order_id` are deleted first, then all items from the request are inserted fresh.** There is no diff or merge. However, `qty_returned` is snapshotted before the delete and restored in the re-insert (see below).

| Column | Type | Source | Description |
|---|---|---|---|
| `item_id` | INT PK | Server assigns `MAX(item_id) + 1` | Reassigned on every save — old IDs are permanently gone |
| `order_id` | INT FK | From the URL `{id}` | Links back to `orders.order_id` |
| `product_id` | INT | `items[].product_id` from request | Product reference |
| `quantity` | INT | `items[].quantity` rounded to integer | **Ordered quantity** — what was requested by the customer |
| `item_price` | FLOAT | `items[].price` | Unit price at time of invoice |
| `item_total` | FLOAT | Server-computed: `quantity × item_price` | Line total before tax/discount |
| `pinfo` | JSON | Built server-side from item fields | Stores HSN, unit, pack, discount %, tax % — see pinfo structure below |
| `commission` | INT | Always `0` | Unused, reserved |
| `qty_delivered` | INT | `items[].qty_delivered` from request | **Delivered quantity** — how many physically reached the customer |
| `qty_returned` | INT | Snapshotted from previous row before delete, restored in re-insert | **Returned quantity** — preserved across invoice edits; only written by the sales return flow |

#### How `quantity`, `qty_delivered`, and `qty_returned` relate

```
quantity       = what the customer ordered          (set at invoice time, editable)
qty_delivered  = what was physically delivered      (set at invoice time, editable)
qty_returned   = what the customer sent back        (preserved from previous save; written by sales return flow)

Net outstanding  = quantity − qty_delivered
Net with return  = quantity − qty_delivered − qty_returned
```

`qty_returned` is no longer wiped on invoice edits. Before the delete, the server reads `product_id → qty_returned` for all existing items and writes those values back in the fresh inserts. A newly added product (no prior row) gets `qty_returned = 0` as expected.

#### `pinfo` JSON structure

All secondary item attributes are packed into a single JSON column rather than separate columns. This is a legacy design decision.

```json
{
  "hsn_code": "10063090",
  "unit": "Kg",
  "selected_pack": { "id": "P001", "unit": "Nos" },
  "description": "Optional free-text description",
  "discount_percent": 5.0,
  "tax_percent": 18.0
}
```

All `pinfo` fields are optional. If none are provided the column stores `{}`. On the Flutter side these are parsed back out of `pinfo` when displaying or editing the invoice.

---

## 3. Order State Machine

```
           ┌──────────────────────────────────────────────┐
           │            cancel_invoice = true             │
           │   (sets bill_no=NULL, Bill_Dt=NULL,          │
           │    order_state='pending')                    │
           ▼                                              │
         DRAFT ──► PENDING ───────────────────────────► BILLED
                     │                                    │
                     ├──► DISPATCHED                      │
                     │                                    │
                     └──► DELIVERED                       │
                                                          │
                             CANCELLED ◄──────────────────┤
                             REJECTED  ◄──────────────────┤
                             RETURNED  ◄──────────────────┘
```

**Rules enforced by the server:**

- `CANCELLED`, `REJECTED`, `RETURNED` are **closed states** — any attempt to edit returns HTTP 422 and nothing is written.
- `cancel_invoice=true` is the **only** way to revert a billed order. It resets `bill_no`, `Bill_Dt`, and `order_state` to `pending`. It does not work on closed states.
- `bill_no IS NULL` → order not yet invoiced. `bill_no IS NOT NULL` → invoiced. The UI uses this to decide whether to pre-fill the form or show a blank.
- `bill_dt` is **mandatory** when `status = 'billed'`. Missing it returns HTTP 422.

---

## 4. Step-by-Step Workflow

### Step 1 — Fetch Next Invoice Number (preview only)

When the invoice form opens, the client calls `GET /api/sales-orders/invoice-series` to get a suggested number to pre-fill the form.

Server logic (`SalesOrderController::series()`):

```php
// Prefix is derived dynamically from the current date — rolls over automatically in April
$prefix  = $this->invoicePrefix();   // e.g. 'INV/25-26/' in FY 2025-26, 'INV/26-27/' after April 2026

// Uses MAX(invoice_number) for the current doc year — unaffected by deletions
$maxNum  = DB::table('loagma_new.orders')
    ->where('Doc_Year', $this->currentDocYear())
    ->max('invoice_number');          // e.g. 2 if two invoices exist this year
$nextNum = str_pad($maxNum + 1, 3, '0', STR_PAD_LEFT);  // → "003"
```

Response:
```json
{ "prefix": "INV/25-26/", "next_number": "003", "full_number": "INV/25-26/003" }
```

> **This number is a suggestion only.** The authoritative invoice number is assigned at save time inside the transaction (Step 5). The user can override the pre-filled value before saving.

---

### Step 2 — User Fills the Invoice Form

The form collects two categories of data.

**Header / billing fields** (map directly to `orders` columns):

| UI field | Request field | `orders` column |
|---|---|---|
| Invoice number | `bill_number` | `bill_no` + `invoice_number` |
| Invoice date | `bill_dt` | `Bill_Dt` |
| Department | `department` | `Department` |
| Narration | `bill_narration` | `Bill_Narration` |
| Vehicle number | `bill_vehicle` | `Bill_Vehicle` |
| Statement ref | `bill_statement` | `Bill_Statement` |
| Round-off | `bill_roff` | `bill_roff` |
| Doc year | `doc_year` | `Doc_Year` |
| Salesman | `supplier_id` | `salesman_id` |
| Customer | `customer_id` | `buyer_userid` |
| Order date | `doc_date` | `short_datetime` (only on create) |
| Narration (order) | `narration` | `txn_id` |
| Charges | `charges` | `charges_json` |

**Line item fields** (map to `orders_item` columns and `pinfo`):

| UI field | Request field | Written to |
|---|---|---|
| Product | `product_id` | `orders_item.product_id` |
| Ordered qty | `quantity` | `orders_item.quantity` |
| Delivered qty | `qty_delivered` | `orders_item.qty_delivered` |
| Rate | `price` | `orders_item.item_price` |
| HSN code | `hsn_code` | `pinfo.hsn_code` |
| Unit | `unit` | `pinfo.unit` |
| Pack | `pack_id` | `pinfo.selected_pack` |
| Discount % | `discount_percent` | `pinfo.discount_percent` |
| Tax % | `tax_percent` | `pinfo.tax_percent` |

**Tax logic (client-side, before sending to server):**
- Same state as company → SGST 2.5% + CGST 2.5% (total 5%)
- Different state → IGST 5%
- Individual components (SGST, CGST, IGST, CESS) are summed and sent as a single `tax_percent` value. The breakdown itself is stored in `pinfo` for PDF rendering.

---

### Step 3 — API Call

**Path A — updating an existing order:**
```
PUT /api/sales-orders/{id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "billed",
  "bill_number": "INV/25-26/003",
  "bill_dt": "2026-06-04",
  "customer_id": 1234,
  "doc_date": "2026-06-04",
  "bill_roff": 0.50,
  "doc_year": "25-26",
  "charges": [{ "name": "Freight", "amount": 150.00 }],
  "items": [
    {
      "product_id": 42,
      "line_no": 1,
      "quantity": 10,
      "qty_delivered": 10,
      "price": 45.00,
      "hsn_code": "10063090",
      "unit": "Kg",
      "tax_percent": 5.0
    }
  ]
}
```

**Path B — create and immediately bill:** Same body sent to `POST /api/sales-orders`.

---

### Step 4 — Server Guard Checks

Before any write the server checks in this order:

```
1. Fetch order by ID
      → HTTP 404 if not found

2. cancel_invoice = true in request?
      → Write: bill_no=NULL, Bill_Dt=NULL, order_state='pending'
      → Return HTTP 200 immediately — nothing else runs

3. order_state is in ['cancelled', 'rejected', 'returned']?
      → Return HTTP 422 — nothing is written

4. status='billed' but bill_dt is missing?
      → Return HTTP 422

5. All guards passed → proceed to writes
```

---

### Step 5 — Database Writes (single transaction)

All writes are inside `DB::transaction()`. Any failure rolls back everything.

**Write 0 — Resolve the authoritative invoice number (inside the transaction):**

```php
// Lock MAX(invoice_number) for this doc year to block concurrent requests.
// Two simultaneous saves will queue here — the second gets maxNum+1 of the first.
$maxNum  = DB::table('loagma_new.orders')
    ->where('Doc_Year', $docYear)
    ->whereNotNull('invoice_number')
    ->lockForUpdate()
    ->max('invoice_number');

$nextNum   = $maxNum + 1;
$billNo    = 'INV/25-26/' . str_pad($nextNum, 3, '0', STR_PAD_LEFT);
// e.g. → 'INV/25-26/003', $nextNum = 3 stored separately in invoice_number column
```

If the user typed a manual `bill_number` that does not start with the `INV/YY-YY/` prefix, it is used as-is and `invoice_number` is left NULL — the sequence is not consumed.

**Write 1 — Update `orders` row:**

```sql
UPDATE loagma_new.orders SET
  order_state    = 'billed',
  order_total    = 473.50,       -- Σ(qty × price) − discount + delivery, server-computed
  discount       = 0,
  delivery_charge= 0,
  items_count    = 1,
  txn_id         = 'narration text',
  bill_no        = 'INV/25-26/003',
  invoice_number = 3,            -- integer sequence, used for future lockForUpdate() reads
  Bill_Dt        = '2026-06-04',
  Department     = 'Sales',
  Bill_Narration = 'June batch',
  Bill_Vehicle   = 'GJ01AB1234',
  Bill_Statement = 'STMT-001',
  bill_roff      = 0.50,
  Doc_Year       = '25-26',
  salesman_id    = 'SM001',
  charges_json   = '[{"name":"Freight","amount":150.00}]'
WHERE order_id = 123;
```

**Write 2 — Snapshot existing `qty_returned` values, then delete all line items:**

```php
// Read and preserve any return quantities recorded against this order's items.
$returnedMap = DB::table('loagma_new.orders_item')
    ->where('order_id', $id)
    ->pluck('qty_returned', 'product_id');
    // e.g. [42 => 1, 55 => 0]

DB::table('loagma_new.orders_item')->where('order_id', $id)->delete();
```

**Write 3 — Insert fresh line items**, restoring `qty_returned` from the snapshot:

```sql
INSERT INTO loagma_new.orders_item
  (item_id, order_id, product_id, quantity, item_price, item_total,
   pinfo, commission, qty_delivered, qty_returned)
VALUES
  (8842, 123, 42, 10, 45.00, 450.00,
   '{"hsn_code":"10063090","unit":"Kg","selected_pack":{"id":"P001","unit":"Nos"},"tax_percent":5.0}',
   0, 10,
   1   -- restored from $returnedMap[42]; new products get 0
  );
```

---

### Step 6 — Response and PDF

**Server response** (includes charges so the form can pre-fill on re-open):
```json
{
  "success": true,
  "data": {
    "order_id": 123,
    "order_state": "billed",
    "bill_no": "INV/25-26/003",
    "charges": [{ "name": "Freight", "amount": 150.00 }],
    ...
  }
}
```

**Client:** Success toast → 800ms delay → `Get.back(result: true)`.

**PDF** (triggered separately, entirely client-side — no server call):

```
┌─────────────────────────────────────────────────────────┐
│  [Company Logo]   Org Name, Address, GST, FSSAI         │
├─────────────────────────────────────────────────────────┤
│  SALES ORDER    Invoice No: INV/25-26/003               │
│  Date: 04-Jun-2026    Customer: Name, Phone, Address    │
├──────────────┬──────┬───────┬──────┬────────┬───────────┤
│ Product      │ HSN  │ Pack  │ Qty  │ Rate   │ Total     │
│ ...          │ ...  │ ...   │ ...  │ ...    │ ...       │
├─────────────────────────────────────────────────────────┤
│  Freight: ₹150.00                                       │
│  SGST 2.5%: ₹11.25  │  CGST 2.5%: ₹11.25              │
│  Round-off: +₹0.50  │  GRAND TOTAL: ₹623.00            │
├─────────────────────────────────────────────────────────┤
│  Bank: [Name]  A/C: [No]  IFSC: [Code]                 │
└─────────────────────────────────────────────────────────┘
```

Company header comes from `GET /api/admin-info`. Charges come from the `charges` field in the order response. Everything else comes from in-memory controller state.

---

## 5. Editing an Invoice — What Actually Happens to Each Column

When a user opens a `BILLED` order and saves any change — whether editing a quantity, changing a price, adding a new item, or just updating a narration — the server runs **exactly the same code path** as initial invoice creation. There is no separate edit logic.

### `orders` table on edit

Every column listed in the Update SQL above is **overwritten** with whatever the client sends. If the client does not include a field, the server falls back to the existing row value (e.g. `bill_no` falls back to `order->bill_no`). Nothing is automatically preserved without explicit client logic.

If `status = 'billed'` on edit, `resolveInvoiceNumber()` runs again inside the transaction. It detects that the existing `bill_no` already starts with the current prefix and returns the same string — `invoice_number` is not incremented again because the `excludeOrderId` parameter filters out the order's own row from the MAX query.

### `orders_item` table on edit — full delete and re-insert with `qty_returned` preserved

**Example — changing quantity on one item (with a prior return recorded):**

```
Before edit                                  After edit save
───────────────────────────────────────────  ──────────────────────────────────────────────
item_id  product  qty  delivered  returned   item_id  product  qty  delivered  returned
7001     Wheat    10   8          1          8842     Wheat    12   10         1  ← preserved
7002     Rice     5    5          0          8843     Rice     5    5          0
```

- `item_id` values are new — old IDs are gone permanently.
- `qty` on Wheat changed from 10 to 12 as intended.
- `qty_returned` on Wheat was `1` — **it is preserved**, not wiped.
- `order_total` is recomputed: `(12×price) + (5×price) − discount + delivery`.

**Example — adding a new item:**

```
Before edit                    After edit save
─────────────────────────────  ───────────────────────────────────────────
item_id  product  qty  ret     item_id  product  qty  delivered  returned
7001     Wheat    10   1       8842     Wheat    10   8          1  ← preserved
7002     Rice     5    0       8843     Rice     5    5          0
                               8844     Sugar    3    0          0  ← new product, ret=0
```

New products have no prior `qty_returned` in the snapshot map → they get `0` as expected.

**Example — removing an item:**

Simply omit it from the `items` array in the request. The server will not insert a row for it. It is gone from `orders_item` with no warning. Its `qty_returned` snapshot is discarded. `items_count` decreases accordingly.

**Example — editing only a header field (narration, vehicle, etc.) with no item changes:**

The client must still send the **full item list** in the request. If the client sends `items: []` or omits the items key, all line items are deleted. The form controller always re-sends every visible item row for this reason.

### Quantity column reference for implementors

| Column | Who sets it | When | Notes |
|---|---|---|---|
| `quantity` | Client (user input) | Every save | Always from user — never inferred |
| `qty_delivered` | Client (user input) | Every save | If client omits it or sends `0`, it becomes `0` |
| `qty_returned` | Sales return flow | After invoice is billed | Preserved across invoice edits via pre-delete snapshot |
| `item_total` | Server computed | Every save | `quantity × item_price` |
| `invoice_number` | Server (locked sequence) | At save time, inside transaction | Only set when `bill_no` matches the auto prefix |

---

## 6. Cancel Invoice Flow

Cancelling an invoice reverts a billed order back to pending without deleting it:

```
PUT /api/sales-orders/{id}
{ "cancel_invoice": true }
```

**Server writes exactly these three columns and nothing else:**

```sql
UPDATE loagma_new.orders SET
  bill_no     = NULL,
  Bill_Dt     = NULL,
  order_state = 'pending'
WHERE order_id = {id};
```

`invoice_number` and `charges_json` are **not cleared** on cancel — if the order is re-billed, `resolveInvoiceNumber()` detects the existing `bill_no` is NULL and generates the next available number fresh. `charges_json` stays so charges are pre-filled if the user re-opens the invoice form immediately after cancelling.

**What else is NOT changed:** `Department`, `Bill_Narration`, `Bill_Vehicle`, `Bill_Statement`, `bill_roff`, `Doc_Year`, `salesman_id`, `order_total`, `discount`, `delivery_charge` — all stay as they were. Line items in `orders_item` are also untouched, including their `qty_returned` values.

After cancel, the order can be re-billed by submitting a normal invoice save with the same or a new `bill_number`.
