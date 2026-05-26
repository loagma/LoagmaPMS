# Sales Module — High Level Design (HLD)
## Flow: Sales Order → Sales Invoice

> Generated: 2026-05-25  
> Source of truth: `loagma_new.orders`, `loagma_new.orders_item`

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER CLIENT (GetX)                              │
│                                                                             │
│   SalesOrderFormScreen          SalesInvoiceFormScreen                      │
│   ─────────────────────         ───────────────────────                     │
│   SalesOrderFormController      SalesInvoiceFormController                  │
│          │                              │                                   │
│          │  POST /api/sales-orders      │  GET  /api/sales-orders/{id}      │
│          │  PUT  /api/sales-orders/{id} │  GET  /api/sales-orders/invoice-  │
│          │                              │        series                      │
│          │                              │  PUT  /api/sales-orders/{id}      │
│          │                              │  POST /api/sales-orders  (new)    │
└──────────┼──────────────────────────────┼────────────────────────────────────┘
           │                              │
           ▼                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       LARAVEL BACKEND (api.php)                             │
│                                                                             │
│                      SalesOrderController                                   │
│               ┌──────────────┬──────────────┬──────────┐                   │
│            store()        update()       show()     series()                │
│               │              │              │           │                   │
└───────────────┼──────────────┼──────────────┼───────────┼───────────────────┘
                │              │              │           │
                ▼              ▼              ▼           ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DATABASE (loagma_new)                                │
│                                                                             │
│   ┌──────────────────────┐        ┌─────────────────────────┐              │
│   │       orders         │ 1 ──── │       orders_item        │             │
│   │  (header + billing)  │    N   │  (line items + qty)      │             │
│   └──────────────────────┘        └─────────────────────────┘              │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Key architectural decision:** There is NO separate `sales_invoices` table in use for the orders-based flow.  
Invoice = same `orders` row with `order_state = 'billed'` and `bill_no` populated.  
(`sales_invoices` / `sales_invoice_items` tables exist in schema for a future standalone invoice path.)

---

## 2. Status Lifecycle

```
                    ┌─────────┐
                    │  DRAFT  │  ◄── Created by salesman / admin
                    └────┬────┘
                         │  Confirm order
                         ▼
                  ┌─────────────┐
                  │  CONFIRMED  │  ◄── Order locked, dispatch prep
                  └──────┬──────┘
                         │  Create invoice (bill_no assigned)
                         ▼
                    ┌────────┐
                    │ BILLED │  ◄── Invoice generated, bill_no set
                    └──┬──┬──┘
                       │  │
              cancel   │  │  return
              invoice  │  │
                       ▼  ▼
               ┌──────────┐  ┌──────────┐
               │ PENDING  │  │ RETURNED │
               └──────────┘  └──────────┘

Other states: REGISTERED, REJECTED, CANCELLED
```

**Field that drives state:**  
`orders.order_state` (VARCHAR) — set in every PUT/POST payload as `status`.

---

## 3. Database Tables — Field Map

### 3.1 `orders` table (header)

```
FIELD                  SET BY SO    SET BY INVOICE    NOTES
─────────────────────────────────────────────────────────────────────
order_id               auto                           PK, never changes
buyer_userid           ✓                              customer FK
order_state            ✓            ✓ (→ 'billed')   status machine
short_datetime         ✓                              doc_date of SO
txn_id                 ✓                              narration / ref
order_total            ✓            ✓                 recalculated
discount               ✓            ✓
delivery_charge        ✓            ✓
items_count            ✓            ✓                 len(items[])
salesman_id            ✓            ✓                 FK → users
admin_id               ✓                              set by backend

── BILLING FIELDS (null until invoice created) ─────────────────────
bill_no                             ✓                 'INV/25-26/NNN'
bill_number            (legacy INT)                   not used in new flow
Bill_Dt                             ✓                 invoice date
Department             ✓            ✓                 dept name
Bill_Narration                      ✓                 invoice note
Bill_Vehicle                        ✓                 vehicle no
Bill_Statement                      ✓                 statement ref
bill_roff                           ✓                 round-off ±
Doc_Year               ✓            ✓                 '25-26'

── NEVER TOUCHED BY INVOICE ────────────────────────────────────────
payment_status                                        default 'not_paid'
payment_method                                        default 'cod'
master_order_id                                       legacy
trip_id, deli_id                                      delivery ops
amountReceivedInfo                                    payment records
order_wt, trip_pending, pending_date                  logistics
```

### 3.2 `orders_item` table (line items)

```
FIELD                  SET BY SO    SET/CHANGED BY INV   NOTES
──────────────────────────────────────────────────────────────────────
item_id                auto                               PK
order_id               ✓                                 FK → orders
product_id             ✓                                 FK → product
quantity               ✓            ✓ (re-insert)        ordered qty
item_price             ✓            ✓ (re-insert)        unit price
item_total             ✓            ✓ (re-insert)        qty × price
commission             ✓            ✓                    always 0.00

── DELIVERY QTY ────────────────────────────────────────────────────
qty_delivered          ✓ (from SO)  ✓ (from SI)          how many shipped
qty_returned                                              set on return
qty_loaded                                                set by driver

── PRODUCT SNAPSHOT (pinfo JSON) ───────────────────────────────────
pinfo.hsn_code         ✓            ✓
pinfo.unit             ✓            ✓                    from units_master
pinfo.selected_pack    ✓            ✓                    {id, unit, label}
pinfo.product_name     ✓            ✓
pinfo.product_code     ✓            ✓
pinfo.discount_percent ✓            ✓
pinfo.tax_percent      ✓            ✓
pinfo.description      ✓            ✓

── NEVER CHANGED ───────────────────────────────────────────────────
offers, op_id, vendor_product_id                          not in SI flow
```

> **Important:** When invoice is saved via PUT, the backend **deletes all existing items** for that order_id and **re-inserts** fresh rows. Items are never updated in-place.

---

## 4. Field-by-Field Flow Diagram

```
SALES ORDER FORM                    SALES INVOICE FORM
(SalesOrderFormController)          (SalesInvoiceFormController)
──────────────────────────          ──────────────────────────────

customerId          ─────────────►  customerId
customerName        ─────────────►  customerName
docDate             ─────────────►  docDate  (orderDate shown read-only)
departmentId        ─────────────►  departmentId
salesmanId          ─────────────►  salesmanId
narration           ─────────────►  narration (if SO already billed)
Doc_Year / FY       ─────────────►  financialYear
charges[]           ─────────────►  charges[]  (editable in SI)
order_id            ──────────────►  sourceOrderId  (read-only reference)

                                    ┌── NEW fields added at invoice stage ──┐
                                    │  invoiceNumber   GET /invoice-series   │
                                    │  billDt          defaults to today      │
                                    │  billDepartment  defaults to 'Sales'    │
                                    │  billNarration   user enters            │
                                    │  billVehicle     user enters            │
                                    │  billStatement   user enters            │
                                    │  billRoff        user enters (±)        │
                                    └───────────────────────────────────────┘

LINE ITEM FLOW:
──────────────
SO SOLineRow                        SI SILineRow
─────────────                       ────────────
productId           ─────────────►  productId
productName         ─────────────►  productName
hsnCode             ─────────────►  productCode (hsn)
unit                ─────────────►  unit           (from units_master)
quantity            ─────────────►  orderedQty     (read-only reference)
usedQty / qty       ─────────────►  qtyDelivered   (editable — what to bill)
price               ─────────────►  price
discountPercent     ─────────────►  discountPercent
taxPercent          ─────────────►  taxPercent
                                    sgst/cgst/igst/cess  (calculated in SI)
                                    roff                 (calculated in SI)
```

---

## 5. API Call Sequence

```
SALES ORDER CREATION
────────────────────
Client                              Server                  DB
  │                                    │                    │
  │── POST /api/sales-orders ─────────►│                    │
  │   {customer_id, items[], status,   │                    │
  │    doc_date, narration, charges}   │                    │
  │                                    │── INSERT orders ──►│
  │                                    │── INSERT items[] ─►│
  │◄── {success, order_id, so_number} ─│                    │


INVOICE CREATION FROM EXISTING SO
───────────────────────────────────
Client                              Server                  DB
  │                                    │                    │
  │── GET /api/sales-orders/{id} ─────►│                    │
  │                                    │── SELECT orders ──►│
  │                                    │── SELECT items ───►│
  │◄── {order + items + computed qty} ─│                    │
  │                                    │                    │
  │  [user fills bill fields]          │                    │
  │                                    │                    │
  │── GET /api/sales-orders/           │                    │
  │        invoice-series ────────────►│                    │
  │                                    │── COUNT(bill_no) ─►│
  │◄── {prefix, number} ───────────────│  next = count+1    │
  │                                    │                    │
  │── PUT /api/sales-orders/{id} ─────►│                    │
  │   {status:'billed',                │                    │
  │    bill_number:'INV/25-26/001',    │── UPDATE orders ──►│  order_state='billed'
  │    bill_dt, bill_narration,        │                    │  bill_no='INV/25-26/001'
  │    items[], charges[]}             │── DELETE items ───►│  (all old items)
  │                                    │── INSERT items[] ─►│  (fresh insert)
  │◄── {success, order} ───────────────│                    │


CANCEL INVOICE (revert to pending)
───────────────────────────────────
  │── PUT /api/sales-orders/{id} ─────►│                    │
  │   {cancel_invoice: true}           │── UPDATE orders ──►│  bill_no = NULL
  │                                    │                    │  order_state = 'pending'
  │◄── {success} ──────────────────────│                    │
```

---

## 6. Invoice Number Generation

```
GET /api/sales-orders/invoice-series

Backend logic:
  count = SELECT COUNT(*) FROM orders WHERE bill_no IS NOT NULL
  seq   = count + 1
  prefix = 'INV/{FY}/'          e.g. 'INV/25-26/'
  number = prefix + seq.toString().padLeft(3, '0')
                                  e.g. 'INV/25-26/001'

Stored in:
  orders.bill_no   VARCHAR(100)   'INV/25-26/001'
```

---

## 7. Quantity Semantics

```
orders_item fields:

  quantity          ─── Originally ordered
  qty_delivered     ─── Actually shipped / to be billed
  qty_returned      ─── Returned by customer (post delivery)
  qty_loaded        ─── Loaded on vehicle (driver app)

Derived (computed by backend on GET, not stored):
  left_qty          = quantity - qty_delivered
  available_to_return = qty_delivered - qty_returned

In Sales Invoice form:
  orderedQty    ← quantity        (shown read-only, reference)
  qtyDelivered  ← usedQty > 0
                    ? usedQty      (already delivered, pre-fill)
                    : quantity     (not delivered yet, default to full)
```

---

## 8. Tax Calculation Flow

```
Per line item in SI form:

  taxableAmount = (price × qtyDelivered) × (1 - discountPercent/100)

  If intra-state (SGST + CGST):
    sgst = taxableAmount × (taxPercent / 2) / 100
    cgst = taxableAmount × (taxPercent / 2) / 100
    igst = 0

  If inter-state (IGST):
    igst = taxableAmount × taxPercent / 100
    sgst = cgst = 0

  cess = taxableAmount × cessPercent / 100   (if applicable)

  lineValue = taxableAmount + sgst + cgst + igst + cess + roff

  orderTotal = Σ lineValue + Σ charges - discount + delivery_charge + bill_roff
```

---

## 9. Component Responsibility Summary

```
┌────────────────────────────────────────────────────────────────────┐
│  COMPONENT                    RESPONSIBILITY                        │
├────────────────────────────────────────────────────────────────────┤
│  SalesOrderFormController     Create / edit SO. Manage SOLineRow.   │
│                               Load customers, products, salesmen,   │
│                               unit types (units_master via API).    │
├────────────────────────────────────────────────────────────────────┤
│  SalesInvoiceFormController   Load SO → populate SI form.           │
│                               Fetch next invoice number.            │
│                               Add bill fields. Submit as 'billed'.  │
│                               Can also create standalone invoice.   │
├────────────────────────────────────────────────────────────────────┤
│  SalesOrderController.store() INSERT orders + orders_item rows.     │
├────────────────────────────────────────────────────────────────────┤
│  SalesOrderController.update()UPDATE orders, DELETE+INSERT items.   │
│                               Handles cancel_invoice flag.          │
├────────────────────────────────────────────────────────────────────┤
│  SalesOrderController.series()COUNT(bill_no) → next INV number.    │
├────────────────────────────────────────────────────────────────────┤
│  BomController.getUnitTypes() SELECT unit_name FROM units_master.  │
│                               Shared by SO, SI, PO, PV, BOM.       │
└────────────────────────────────────────────────────────────────────┘
```

---

## 10. What Changes: SO → Invoice (Summary Table)

| # | Field | At SO Stage | At Invoice Stage | Who changes it |
|---|-------|-------------|-----------------|----------------|
| 1 | `order_state` | `'draft'` / `'confirmed'` | `'billed'` | SI form PUT |
| 2 | `bill_no` | `NULL` | `'INV/25-26/NNN'` | SI form PUT |
| 3 | `Bill_Dt` | `NULL` | invoice date (today) | SI form PUT |
| 4 | `Department` | dept or NULL | dept (editable) | SI form PUT |
| 5 | `Bill_Narration` | `NULL` | user-entered text | SI form PUT |
| 6 | `Bill_Vehicle` | `NULL` | vehicle number | SI form PUT |
| 7 | `Bill_Statement` | `NULL` | statement ref | SI form PUT |
| 8 | `bill_roff` | `0.00` | round-off amount | SI form PUT |
| 9 | `order_total` | ordered total | billed total | SI recalculates |
| 10 | `items_count` | count of SO lines | count of SI lines | SI recalculates |
| 11 | `orders_item.qty_delivered` | qty from SO form | qty from SI form | re-inserted |
| 12 | `orders_item.item_price` | SO price | SI price (editable) | re-inserted |
| 13 | `orders_item.item_total` | qty × price | billed qty × price | re-inserted |
| 14 | `orders_item.pinfo` | product snapshot | updated snapshot | re-inserted |

**Fields that DO NOT change at invoice stage:**  
`buyer_userid`, `txn_id`, `payment_status`, `payment_method`, `delivery_charge`,  
`discount`, `salesman_id`, `master_order_id`, `trip_id`, `deli_id`, all logistics fields.
