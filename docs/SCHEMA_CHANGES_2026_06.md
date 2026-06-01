# Schema Changes — June 2026

> **Source:** `changes.sql`  
> **Database:** `loagma_new`  
> **Compared against:** `loagma_database_schema (1).sql` (Feb 2026 baseline)

---

## Overview

| # | Area | Type | Tables / Columns |
|---|------|------|-----------------|
| 1 | BOM | New tables | `bom_master`, `bom_items` |
| 2 | Suppliers | New tables | `suppliers`, `supplier_products` |
| 3 | Purchase Orders | New tables | `purchase_orders`, `purchase_order_items` |
| 4 | Taxes & HSN | New tables | `taxes`, `product_taxes`, `hsn_codes` |
| 5 | Units | New table + seed | `units_master` |
| 6 | Finance | New tables | `general_account`, `fa_cash_main`, `fa_cash_line`, `fa_main_line` |
| 7 | Purchase Vouchers | New tables | `purchase_vouchers`, `purchase_voucher_items` |
| 8 | Purchase Returns | New tables | `purchase_returns`, `purchase_return_items` |
| 9 | Sales Invoices | New tables | `sales_invoices`, `sales_invoice_items` |
| 10 | Stock Vouchers | New tables | `stock_voucher`, `stock_voucher_items` |
| 11 | Production | New tables | `issue_to_production`, `issue_to_production_items`, `receive_from_production`, `receive_from_production_items` |
| 12 | Masters | New tables | `pincode_masters`, `product_sales_daily`, `business_types`, `departments`, `BusinessType`, `Department` |
| 13 | Users & Roles | New tables | `roles`, `users` |
| 14 | Trip / Delivery | New tables | `vehicles`, `trip_cards`, `trip_card_pincode`, `zone_vehicles`, `trip_audit_log`, `order_zone_overrides` |
| 15 | Stock Management | New tables | `stock_audit_log`, `stock_notify`, `stock_count_master_session`, `stock_count_assignments`, `stock_count` |
| 16 | Misc | New tables | `product_purchase`, `vendor_area_categories` |
| 17 | Existing tables | Column additions | `orders`, `product`, `admin`, `deli_staff`, `otp`, `user`, `purchase_orders`, `purchase_order_items` |

---

## 1 — Bill of Materials (BOM)

**Why:** Products are manufactured from raw materials. BOM defines what and how much raw material goes into one unit of a finished product. This is the foundation for production planning, raw material consumption tracking, and cost calculation.

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `bom_master` | `bom_id` | BIGINT PK | |
| | `product_id` | BIGINT | Finished product |
| | `bom_version` | VARCHAR(20) | Multiple versions per product |
| | `status` | ENUM | DRAFT / APPROVED / LOCKED |
| | `created_by`, `approved_by` | BIGINT | Staff references |
| `bom_items` | `bom_item_id` | BIGINT PK | |
| | `bom_id` | BIGINT FK | → `bom_master` |
| | `raw_material_id` | BIGINT FK | → `product` |
| | `quantity_per_unit` | DECIMAL(10,3) | Qty of raw material per finished unit |
| | `unit_type` | VARCHAR(20) | |
| | `wastage_percent` | DECIMAL(5,2) | Default 0 |

---

## 2 — Suppliers

**Why:** Previously the system had no supplier master. All purchasing was informal. A proper supplier registry enables PO workflows, rate tracking, credit limits, and compliance fields (GST, PAN, FSSAI).

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `suppliers` | `id` | BIGINT PK | |
| | `supplier_code` | VARCHAR(50) | Unique |
| | `supplier_name` | VARCHAR(255) | |
| | `gst_no`, `pan_no`, `fssai_no` | VARCHAR | Compliance |
| | `contact_person`, `email`, `phone` | VARCHAR | |
| | `bank_account_number`, `ifsc_code` | VARCHAR | Payment |
| | `payment_terms_days`, `credit_limit` | SMALLINT / DECIMAL | |
| | `status` | ENUM | ACTIVE / INACTIVE / SUSPENDED |
| `supplier_products` | `id` | BIGINT PK | |
| | `supplier_id` | BIGINT FK | → `suppliers` |
| | `product_id` | BIGINT FK | → `product` |
| | `supplier_sku`, `price`, `tax_percent` | — | Supplier-specific pricing |
| | `lead_time_days`, `last_purchase_price` | — | Procurement data |
| | UNIQUE | `(supplier_id, product_id)` | One product once per supplier |

---

## 3 — Purchase Orders

**Why:** Formalises procurement. Before this, purchases were ad-hoc with no approval trail. POs enable quantity tracking, partial receipt, and linkage to purchase invoices.

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `purchase_orders` | `id` | BIGINT PK | |
| | `po_number` | VARCHAR(50) | Unique |
| | `supplier_id` | BIGINT FK | → `suppliers` |
| | `status` | ENUM | DRAFT / SENT / PARTIALLY_RECEIVED / CLOSED / CANCELLED |
| | `total_amount` | DECIMAL(14,2) | |
| | `charges_total`, `charges_json`, `total_with_charges` | — | Added later for extra charges |
| | `salesman_id`, `department_id` | VARCHAR | Who raised / which dept |
| `purchase_order_items` | `id` | BIGINT PK | |
| | `purchase_order_id` | BIGINT FK | → `purchase_orders` |
| | `product_id` | BIGINT FK | → `product` |
| | `quantity`, `price`, `line_total` | DECIMAL | |
| | `hsn_code` | VARCHAR(50) | Added for GST reporting |
| | `consumed_quantity` | DECIMAL(12,3) | Qty used in production |
| | `written_off_quantity` | DECIMAL(12,3) | Qty damaged / expired |
| | `remaining_quantity` | DECIMAL(12,3) | qty − consumed − written off |

---

## 4 — Taxes & HSN Codes

**Why:** GST compliance requires HSN codes and tax rates per product. Hard-coded tax values were error-prone; a master table lets rates be managed centrally and linked to products.

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `taxes` | `id` | BIGINT PK | |
| | `tax_category`, `tax_sub_category` | VARCHAR | e.g. GST / SGST |
| | `tax_name` | VARCHAR(150) | |
| | `is_active` | TINYINT | |
| `product_taxes` | `id` | BIGINT PK | |
| | `product_id` | BIGINT FK | → `product` |
| | `tax_id` | BIGINT FK | → `taxes` |
| | `tax_percent` | DECIMAL(5,2) | Rate applied to this product |
| | UNIQUE | `(product_id, tax_id)` | One tax type once per product |
| `hsn_codes` | `id` | BIGINT PK | |
| | `hsn_code` | VARCHAR(50) | |
| | `is_active` | TINYINT | |

---

## 5 — Units Master

**Why:** Unit dropdowns (KG, LTR, PCS, etc.) were hardcoded in multiple places — BOM, purchase orders, stock vouchers, sales invoices. A single table eliminates inconsistency and lets admin add new units without code changes.

| Table | Column | Type | Notes |
|-------|--------|------|-------|
| `units_master` | `unit_id` | INT PK | |
| | `unit_name` | VARCHAR(100) | KG, GM, LTR, PCS … |
| | `serial_no` | INT | Display order |
| | `conversion_rate` | DECIMAL(10,4) | Relative to base unit (KG=1, GM=0.001) |

**Seeded with 20 units:** KG, GM, LTR, ML, NOS, PCS, BOX, PKT, BAG, DOZEN, BUNCH, MTR, CM, TIN, JAR, BTL, POUCH, STRIP, ROLL, SET.

---

## 6 — Finance / Accounts

**Why:** Cash receipt vouchers and a unified journal ledger are needed to record payments against invoices and maintain a basic chart of accounts for reporting.

| Table | Purpose |
|-------|---------|
| `general_account` | Chart of accounts — account number, name, type |
| `fa_cash_main` | Cash receipt voucher header (doc_no, receipt_mode, book account) |
| `fa_cash_line` | Line items per cash receipt (account, amount, bill reference) |
| `fa_main_line` | Unified ledger — all voucher types write here (DR/CR, account, date) |

---

## 7 & 8 — Purchase Vouchers & Returns

**Why:** A purchase invoice (GRN) records what was actually received against a PO, captures tax values (SGST/CGST/IGST), and updates inventory. Purchase returns (debit notes) reverse this when goods are sent back.

| Table | Key Columns |
|-------|-------------|
| `purchase_vouchers` | `doc_no`, `vendor_id`, `purchase_order_id`, `bill_no`, `status` (DRAFT/POSTED/CANCELLED), `items_total`, `net_total` |
| `purchase_voucher_items` | `product_id`, `quantity`, `unit_price`, `sgst`, `cgst`, `igst`, `cess`, `value`, `overrun_qty`, `writeoff_qty` |
| `purchase_returns` | `source_purchase_voucher_id`, `vendor_id`, `doc_date`, `reason`, `status` |
| `purchase_return_items` | `original_quantity`, `returned_quantity`, `sgst`, `cgst`, `igst`, `value` |

---

## 9 — Sales Invoices

**Why:** Sales invoices are a separate module from delivery orders. They capture formal GST-compliant billing with HSN codes, tax breakdowns, and linkage back to the original sales order.

| Table | Key Columns |
|-------|-------------|
| `sales_invoices` | `doc_no` (unique), `customer_id`, `doc_date`, `status` (DRAFT/POSTED/CANCELLED), `items_total`, `net_total` |
| `sales_invoice_items` | `product_id`, `quantity`, `unit_price`, `sgst`, `cgst`, `igst`, `hsn_code`, `source_sales_order_id` |

---

## 10 — Stock Vouchers

**Why:** Manual stock adjustments (inbound/outbound corrections, damage write-offs) need an auditable voucher rather than direct table edits.

| Table | Key Columns |
|-------|-------------|
| `stock_voucher` | `voucher_type` (IN/OUT), `status` (DRAFT/POSTED), `voucher_date`, `remarks` |
| `stock_voucher_items` | `product_id`, `quantity`, `unit_type` |

---

## 11 — Production Flow

**Why:** Raw materials are issued to the factory floor and finished goods come back. These two vouchers track that movement so inventory stays accurate on both sides.

| Table | Key Columns |
|-------|-------------|
| `issue_to_production` | `status` (DRAFT/ISSUED/COMPLETED/CANCELLED), `issued_by`, `issued_at` |
| `issue_to_production_items` | `raw_material_id`, `quantity`, `unit_type` |
| `receive_from_production` | `status` (DRAFT/RECEIVED), `received_at` |
| `receive_from_production_items` | `finished_product_id`, `quantity`, `unit_type` |

---

## 12 — Master / Lookup Tables

**Why:** Multiple dropdowns and lookups were previously hardcoded. Centralising them allows admin to manage values without deployments.

| Table | Purpose |
|-------|---------|
| `pincode_masters` | Pincode → city / state / district lookup used for auto-fill |
| `product_sales_daily` | Daily aggregated sales per product for dashboards |
| `business_types` | Dropdown for supplier/customer business type |
| `departments` | PMS department master (separate from CRM departments) |
| `BusinessType` | Legacy CRM-side business type (kept for backward compat) |
| `Department` | Legacy CRM-side department (kept for backward compat) |

---

## 13 — Users & Roles (PMS)

**Why:** The PMS previously reused the CRM's `LoginUser_crm` table. A dedicated `users` + `roles` table gives PMS its own auth with OTP login, attendance grace rules, and department linkage.

| Table | Key Columns |
|-------|-------------|
| `roles` | `id` (R001…), `name` — seeded: Admin, Employee, Manager, Telecaller, Developer |
| `users` | `contactNumber` (login), `roleId`, `departmentId`, `otp`, `otpExpiry`, `workStartTime`, `workEndTime`, `latePunchInGraceMinutes` |

---

## 14 — Trip / Delivery Module

**Why:** Deliveries are organised into zones (trip cards) with assigned vehicles and drivers. The audit log captures discrepancies between what was loaded, claimed delivered, and verified — making drivers accountable for stock.

| Table | Purpose |
|-------|---------|
| `vehicles` | Vehicle master with capacity |
| `trip_cards` | Delivery zone master — each zone maps to a route |
| `trip_card_pincode` | Pincodes served by each zone |
| `zone_vehicles` | Which vehicle is assigned to which zone |
| `trip_audit_log` | Loaded vs delivered vs returned qty per item; discrepancy auto-calculated via generated columns |
| `order_zone_overrides` | Manual override when an order's zone doesn't match its pincode |

```
vehicles ──────────────────┐
                           ↓
trip_cards ◄── zone_vehicles
    │
    ├── trip_card_pincode  (pincodes served)
    │
    └── trip_audit_log     (per order/item accountability)

orders ── order_zone_overrides  (zone correction)
```

---

## 15 — Stock Management

**Why:** Stock counts, mutation logs, and restock alerts were missing, making it impossible to audit discrepancies or run periodic physical stock counts.

| Table | Purpose |
|-------|---------|
| `stock_audit_log` | Every stock mutation logged with pack-level JSON detail and reason |
| `stock_notify` | Users who want an alert when a product comes back in stock |
| `stock_count_master_session` | Supervisor creates a count session across all categories |
| `stock_count_assignments` | Each category assigned to a counter with status tracking |
| `stock_count` | Individual product counts submitted per assignment |

```
stock_count_master_session
    └── stock_count_assignments  (per category)
            └── stock_count      (per product)
```

---

## 16 — Miscellaneous

| Table | Purpose | Why |
|-------|---------|-----|
| `product_purchase` | Historical purchase cost per product per day | Used for COGS / cost analysis |
| `vendor_area_categories` | Maps admin to area + category combos with commission | Controls what products show in which delivery areas |

---

## 17 — Column Additions to Existing Tables

**Why:** Rather than creating new tables, these columns extend existing records to avoid JOINs and keep related data together.

### `orders`

| Column | Type | Why Added |
|--------|------|-----------|
| `bill_no` | VARCHAR(100) | Short bill number alias for display |
| `Bill_Dt` | DATE | Invoice date on the order |
| `Department` | VARCHAR(100) | Department that raised the order |
| `Bill_Narration`, `Bill_Vehicle`, `Bill_Statement` | TEXT/VARCHAR | Invoice metadata |
| `bill_roff` | DECIMAL(10,2) | Round-off amount on bill |
| `Doc_Year` | VARCHAR(20) | Financial year of document |
| `salesman_id` | VARCHAR(191) | Salesman who created the order |
| `order_wt` | DECIMAL(10,3) | Total order weight (default 25 kg) |
| `trip_pending` | TINYINT | Flags order as pending trip assignment |
| `pending_date` | DATE | Date order became trip-pending |
| `Sales_Return_VoucherNo` | VARCHAR(100) | Return voucher number |
| `Sales_Return_Dt` | DATE | Return date |
| `Sales_Return_Reason` | TEXT | Reason for return |

### `product`

| Column | Type | Why Added |
|--------|------|-----------|
| `order_limit` | INT | Max orderable qty per order |
| `buffer_limit` | INT | Safety stock threshold |
| `product_pack_count` | INT | Number of packs in a product unit |
| `nop` | INT | Number of pieces per pack |
| `pack_prd_wt` | DECIMAL(12,3) | Weight of product in the pack |
| `gross_wt_of_pack` | DECIMAL(12,3) | Gross weight including packaging |
| `gst_tax_type` | VARCHAR(50) | GST applicability type |

### `admin`

| Column | Why Added |
|--------|-----------|
| `fssai_no`, `gst_no` | Compliance / licence numbers on invoices |
| `licence_1`, `licence_2` | Additional licences |
| `bank_name`, `bank_branch`, `account_number`, `ifsc_code`, `account_type` | Bank details for payment QR / transfer |
| `scanner_qr`, `phonepe_no`, `gpay_no` | UPI payment options on invoices |

### `deli_staff`

| Column | Why Added |
|--------|-----------|
| `otp`, `otp_expires_at` | OTP-based login for delivery app |
| `pincode`, `city`, `state` | Location enrichment from GPS |

### `otp`

| Column | Why Added |
|--------|-----------|
| `otp_num` | Store actual OTP value directly on the row |

### `user`

| Column | Why Added |
|--------|-----------|
| `pincode`, `city`, `state` | Auto-filled from pincode master for address accuracy |

### `purchase_orders`

| Column | Why Added |
|--------|-----------|
| `salesman_id` | Who raised the PO |
| `department_id` | Which department the PO belongs to |
| `charges_total`, `charges_json`, `total_with_charges` | Extra charges (freight, handling) broken out separately |

### `purchase_order_items`

| Column | Why Added |
|--------|-----------|
| `hsn_code` | Required on purchase invoices for GST |
| `consumed_quantity` | Tracks how much of received qty was used in production |
| `written_off_quantity` | Tracks damage/expiry write-offs |
| `remaining_quantity` | Derived: qty − consumed − written off |
