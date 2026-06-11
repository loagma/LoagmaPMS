# Plan: vendor_products_inventory Ledger + Pack Stock for All Transaction Flows

## Pack JSON Field Reference

Fields inside `vendor_products.packs` JSON (each pack object):
| Field | Meaning |
|-------|---------|
| `pi` | Pack ID — used as `pack_id` in ledger rows |
| `ps` + `pu` | Size + Unit — together form the label |
| `rp` | Retail price — used for sales-side amount calculation |
| `op` | Original/base price |
| `stk` | Current stock quantity |
| `in_stk` | 1 = in stock, 0 = out of stock |
| `mv` | Max variation % for price |

---

## Flow Matrix (fully confirmed)

| Flow | packs.stk | vendor_products_inventory | Trigger | Vendor match |
|------|-----------|--------------------------|---------|--------------|
| **Purchase Order** | ❌ none | ❌ none | — | — |
| **Purchase Invoice** | ✅ INCREASE | ✅ CREDIT | DRAFT→POSTED only | `supplier_id` on voucher |
| **Purchase Return** | ✅ DECREASE | ✅ DEBIT | DRAFT→POSTED only | `supplier_id` on return |
| **Sales Order** | ✅ DECREASE | ❌ none | Every save (create + update) | `supplier_id` on SO (deli_staff vendor) |
| **Sales Invoice** | ❌ none | ✅ DEBIT | SO status → BILLED only | First active row for product |
| **Sales Return** | ✅ INCREASE | ✅ CREDIT | Every save | First active row for product |
| **Stock Voucher IN** | ✅ INCREASE (existing) | ✅ CREDIT | Every save | First active row (existing logic) |
| **Stock Voucher OUT** | ✅ DECREASE (existing) | ✅ DEBIT | Every save | First active row (existing logic) |

---

## Step 0: New Column `source` on vendor_products_inventory
> Add a nullable `source varchar(100)` column to `vendor_products_inventory` so every ledger row carries a machine-readable tag for where it came from (e.g. `purchase_invoice`, `sales_return`). Existing rows stay NULL.

**File to create:** `server/database/migrations/YYYY_add_source_to_vendor_products_inventory.php`

```php
Schema::table('vendor_products_inventory', function (Blueprint $table) {
    $table->string('source', 100)->nullable()->after('note');
});
```

| Flow | source value |
|------|-------------|
| Purchase Invoice | `purchase_invoice` |
| Purchase Return | `purchase_return` |
| Sales Invoice (BILLED) | `sales_invoice` |
| Sales Return | `sales_return` |
| Stock Voucher | `stock_voucher` |
| Existing trip rows | NULL (leave untouched — column is nullable) |

---

## Step 1: Create InventoryLedgerService
> A new shared service (`server/app/Services/InventoryLedgerService.php`) with three methods used by all 5 flows: `resolveVendorProduct()` to look up the right vendor_product row, `recordLedger()` to insert one audit entry, and `updatePacksStock()` to adjust the `stk` field inside the packs JSON. All callers wrap this in try/catch so inventory errors never break the main save.

**File:** `server/app/Services/InventoryLedgerService.php`

Three methods:

### `resolveVendorProduct(int $productId, ?int $adminVendorId = null): ?object`
- If `$adminVendorId` given → `WHERE product_id = ? AND admin_vendor_id = ? AND status = '1'`
- If null → `WHERE product_id = ? AND status = '1' LIMIT 1` (same as existing StockVoucher logic)
- Returns first matching row or null

### `recordLedger(...): void`
Inserts one row into `vendor_products_inventory`. Parameters:
```
int    $vendorProductId
int    $productId
string $packId           // pi from packs JSON, or '' if unavailable
float  $quantity
string $unitType
float  $amount           // qty * price; 0 if no price
string $actionType       // purchase | purchase_return | sale | sale_return | stock_in | stock_out
string $invType          // CREDIT | DEBIT
string $source           // purchase_invoice | purchase_return | sales_invoice | sales_return | stock_voucher
string $note
string $invDate          // Y-m-d
?int   $vendorId = null
?int   $tripId = null
```

### `updatePacksStock(int $vendorProductId, float $qty, string $operation): string`
- Loads `vendor_products.packs` JSON for given row
- Applies `increase` or `decrease` (floor 0) to `stk` on **every pack** (all flows)
- Updates `in_stk` flag (1 if stk > 0, else 0)
- Re-saves JSON back to `vendor_products`
- Returns first pack's `pi` value as a fallback (used as `pack_id` in ledger row for purchase flows)
- Handles both map-keyed and array-indexed packs JSON formats

**All callers must wrap in `try/catch (\Throwable $e) { Log::warning(...); }` — inventory must never break the main save.**

---

## Step 2: PurchaseVoucherController — packs INCREASE + CREDIT ledger
> When a purchase voucher is POSTed (DRAFT→POSTED only), increase `packs.stk` for each item and write a CREDIT row to the ledger. Skipped entirely on DRAFT saves and when `do_not_update_inventory=true`.

**File:** `server/app/Http/Controllers/PurchaseVoucherController.php`

**Trigger:** Only when status transitions to `POSTED` (i.e. `$voucher->status === 'POSTED'`).
DRAFT saves: skip entirely.
`do_not_update_inventory` flag: skip both packs + ledger if true.

**On `store()`:** After items saved, if POSTED → loop items, call service.

**On `update()`:** Only if new status is POSTED AND old status was DRAFT (one-way transition — POSTED is locked for edits per confirmed design). If re-POSTing is not possible, this is a create-only trigger.

**pack_id handling (lenient):** Purchase items don't always carry a pack selection. Use `item.pack_id` if present, otherwise fall back to the first pack's `pi` returned by `updatePacksStock()`.

**Per item:**
```
vp = resolveVendorProduct(item.product_id, voucher.supplier_id)
firstPackId = updatePacksStock(vp.id, item.quantity, 'increase')
packId = item.pack_id ?: firstPackId   // lenient — fall back to first pack pi
recordLedger(
  vendorProductId: vp.id,
  productId: item.product_id,
  packId: packId,
  quantity: item.quantity,
  unitType: item.unit,
  amount: item.quantity * item.unit_price,
  actionType: 'purchase',
  invType: 'CREDIT',
  source: 'purchase_invoice',
  note: "Purchase Invoice {voucher.doc_no} - {item.product_name}",
  invDate: voucher.doc_date,
  vendorId: voucher.supplier_id,
)
```

**Edge case:** `resolveVendorProduct` returns null → skip item silently, log warning.

---

## Step 3: PurchaseReturnController — packs DECREASE + DEBIT ledger
> Mirror of Step 2 but reversed — when a purchase return is POSTed, decrease `packs.stk` for each returned item and write a DEBIT row. No reverse logic needed on update because POSTED vouchers are locked for editing.

**File:** `server/app/Http/Controllers/PurchaseReturnController.php`

**Trigger:** Only when status = POSTED. DRAFT: skip.

Same pattern as Purchase Invoice but:
```
qty field: item.returned_quantity
operation: 'decrease'
actionType: 'purchase_return'
invType: 'DEBIT'
source: 'purchase_return'
note: "Purchase Return {return.doc_no} - {item.product_name}"
vendorId: return.supplier_id
packId: item.pack_id ?: firstPackId   // lenient — same as purchase invoice
```

**On update:** Since POSTED is locked (per confirmed design — only DRAFT editable), no reverse logic needed. The POSTED transition fires once.

---

## Step 4: SalesOrderController — packs DECREASE (no ledger) + BILLED ledger
> Two separate concerns: (1) every SO save (create or update) decreases `packs.stk` — on update it reverses the old qty first then re-applies the new qty; (2) only when the SO transitions to BILLED does a DEBIT ledger row get written. Stock moves immediately on save; the financial audit trail only appears on invoice.

**File:** `server/app/Http/Controllers/SalesOrderController.php`

### 4a. packs DECREASE on every save

**Vendor match:** Use `supplier_id` from the SO payload (the logged-in deli_staff's admin_vendor_id, sent as `supplier_id` in the request).

**pack_id handling (strict):** Sales items always carry a `pack_id` (stored in `pinfo.selected_pack.id`). This must be used as-is in the ledger row. Do **not** fall back to the first pack's `pi` — if `pack_id` is missing on a sales item, log a warning and use `''`.

**On `store()`:**
- After items are saved, for each item: `resolveVendorProduct(item.product_id, supplier_id)` → `updatePacksStock(vp.id, qty, 'decrease')`

**On `update()` — reverse + re-apply:**
1. **Guard:** Before reversing, check if any item has `qty_returned > 0`. If yes → return error "Cannot edit order with processed returns."
2. Load existing items from DB for this order
3. For each old item: `updatePacksStock(vp.id, old_qty, 'increase')` (reverse)
4. Save new items
5. For each new item: `updatePacksStock(vp.id, new_qty, 'decrease')` (re-apply)

**Vendor for step 3:** Use `supplier_id` currently on the order record (before update).
**Vendor for step 5:** Use `supplier_id` from the new request payload.

### 4b. DEBIT ledger when status = BILLED

On `store()` or `update()`, detect BILLED:
- `store()`: if `$request->status === 'BILLED'`
- `update()`: if old status ≠ `BILLED` and new status = `BILLED`

When BILLED, for each item:
```
vp = resolveVendorProduct(item.product_id, supplier_id)  // first active if supplier_id null
recordLedger(
  vendorProductId: vp.id,
  productId: item.product_id,
  packId: item.pack_id ?? '',     // STRICT — pack_id from pinfo.selected_pack.id; '' if absent (log warning)
  quantity: item.qty,
  unitType: item.unit,
  amount: item.qty * item.price,
  actionType: 'sale',
  invType: 'DEBIT',
  source: 'sales_invoice',
  note: "Sales Invoice SO#{order.id} - {item.product_name}",
  invDate: order.doc_date,
)
```

**Edge:** PARTIALLY_INVOICED → no ledger row (only BILLED triggers it).

---

## Step 5: SalesReturnController — packs INCREASE + CREDIT ledger
> When a customer returns goods, increase `packs.stk` by the delta qty returned in this request (not cumulative) and write a CREDIT ledger row at the original sale price. No `supplier_id` on returns — always resolves to the first active vendor_product for the product.

**File:** `server/app/Http/Controllers/SalesReturnController.php`

Uses legacy `loagma_new.orders_item` table. After `qty_returned` is updated:

**Qty to use:** Delta only — the qty being returned in THIS request (not cumulative).

**Vendor match:** No supplier_id on sales returns. Use `resolveVendorProduct(product_id, null)` → first active vendor_product row.

**pack_id handling (strict):** The original SO item has `pack_id` in `pinfo.selected_pack.id`. Read it from the original `orders_item` row and use it directly. Do **not** fall back to first pack's `pi`.

Per returned item:
```
vp = resolveVendorProduct(item.product_id, null)
updatePacksStock(vp.id, returned_qty, 'increase')
packId = item.pinfo.selected_pack.id ?? ''   // STRICT — from original order item; '' if missing (log warning)
recordLedger(
  vendorProductId: vp.id,
  productId: item.product_id,
  packId: packId,
  quantity: returned_qty,
  unitType: item.unit,
  amount: returned_qty * item.item_price,   // original sale price from orders_item
  actionType: 'sale_return',
  invType: 'CREDIT',
  source: 'sales_return',
  note: "Sales Return Order #{order_id} - {item.product_name}",
  invDate: return.doc_date,
)
```

---

## Step 6: StockVoucherController — CREDIT/DEBIT ledger (packs already updated)
> The existing controller already updates `packs.stk`. The only change is to make `updateVendorProductStock()` return the `vendor_product_id` it touched, then use that to write one CREDIT (IN) or DEBIT (OUT) ledger row per item. No pack logic changes — just wiring in the audit entry.

**File:** `server/app/Http/Controllers/StockVoucherController.php`

The existing `updateVendorProductStock()` already updates packs and uses `break` after the first matching vendor_product. We need the `vendor_product_id` of that first row.

**Approach:** Modify `updateVendorProductStock()` to return the `vendor_product_id` it updated (or null), then use that to call ledger.

After the existing method returns a `$updatedVpId`:
```
recordLedger(
  vendorProductId: updatedVpId,
  productId: item.product_id,
  packId: '',        // no pack_id in stock_voucher_items; use '' or first pack pi
  quantity: item.quantity,
  unitType: item.unit_type,
  amount: 0,         // no price on stock vouchers
  actionType: voucher_type === 'IN' ? 'stock_in' : 'stock_out',
  invType: voucher_type === 'IN' ? 'CREDIT' : 'DEBIT',
  source: 'stock_voucher',
  note: "Stock Voucher #{voucherId} {voucher_type} - {item.unit_type}",
  invDate: voucher.voucher_date,
)
```

Only one ledger row per item (for the one vendor_product that was updated — matches the existing `break` behaviour).

---

## Files to Create / Modify

| File | Action |
|------|--------|
| `server/database/migrations/YYYY_add_source_to_vendor_products_inventory.php` | **Create** |
| `server/app/Services/InventoryLedgerService.php` | **Create** |
| `server/app/Http/Controllers/PurchaseVoucherController.php` | Add packs increase + CREDIT ledger on POSTED |
| `server/app/Http/Controllers/PurchaseReturnController.php` | Add packs decrease + DEBIT ledger on POSTED |
| `server/app/Http/Controllers/SalesOrderController.php` | Add packs decrease on every save (reverse+reapply on update); DEBIT ledger on BILLED |
| `server/app/Http/Controllers/SalesReturnController.php` | Add packs increase + CREDIT ledger |
| `server/app/Http/Controllers/StockVoucherController.php` | Return updated vp_id from existing method; add CREDIT/DEBIT ledger |

---

## Edge Cases Summary

| Case | Handling |
|------|----------|
| `resolveVendorProduct` returns null | Skip silently, `Log::warning()` |
| `do_not_update_inventory = true` | Skip packs + ledger entirely |
| SO update with existing returns | Block with error: "Cannot edit order with processed returns" |
| PI/PR update on POSTED voucher | Not possible (POSTED is locked) — no reverse logic needed |
| packs stk going negative | `max(0, stk - qty)` — floor at 0 |
| PARTIALLY_INVOICED SO | No ledger row — only BILLED triggers sales_invoice entry |
| All inventory calls | Wrapped in `try/catch` — never break the main DB transaction |
| Stock Voucher pack_id | Use `''` empty string (no pack tracking at SV item level) |
| Sales pack_id missing | Log warning, use `''` — do NOT fall back to first pack's `pi` |
| Purchase pack_id missing | Fall back to first pack's `pi` returned by `updatePacksStock()` |

---

## Verification Checklist

> Run these checks manually after implementation. Each one covers a specific trigger — pass all 13 before marking the feature done.

1. **Purchase Invoice POSTED** → `vendor_products_inventory` CREDIT row (`source=purchase_invoice`), packs `stk` goes up
2. **Purchase Invoice DRAFT** → no changes to packs or ledger
3. **Purchase Return POSTED** → DEBIT row (`source=purchase_return`), packs `stk` goes down
4. **Sales Order create** → packs `stk` decreases, NO ledger row
5. **Sales Order update (qty change)** → packs reversed to original, then re-applied with new qty
6. **Sales Order update with existing return** → API returns error, no changes
7. **Sales Order → BILLED** → DEBIT ledger row (`source=sales_invoice`), packs unchanged
8. **Sales Order → PARTIALLY_INVOICED** → NO ledger row
9. **Sales Return** → CREDIT ledger row (`source=sales_return`), packs `stk` increases by returned delta
10. **Stock Voucher IN** → CREDIT ledger row (`source=stock_voucher`)
11. **Stock Voucher OUT** → DEBIT ledger row (`source=stock_voucher`)
12. **Purchase Order** → zero changes anywhere
13. **`do_not_update_inventory=true` on PI** → no packs change, no ledger row

---

## Summary

This plan adds a complete audit trail to `vendor_products_inventory` across all 5 transaction flows. Currently the table exists but nothing writes to it from any flow.

**What gets built:**
- A migration to add a `source` column so every ledger row is traceable back to its origin
- A shared `InventoryLedgerService` with 3 methods used by all controllers — keeping the logic in one place
- Hooks in 5 controllers to write ledger rows and update `packs.stk` at the right trigger point per flow

**The key rule per flow:**
| Flow | packs.stk | Ledger | When |
|------|-----------|--------|------|
| Purchase Invoice | +increase | CREDIT | POSTED only |
| Purchase Return | −decrease | DEBIT | POSTED only |
| Sales Order | −decrease | ❌ none | Every save |
| Sales Invoice | no change | DEBIT | BILLED only |
| Sales Return | +increase | CREDIT | Every save |
| Stock Voucher | already done | CREDIT/DEBIT | Every save |

**pack_id rule (two-tier):**
- **Sales flows (SO, Sales Invoice, Sales Return):** `pack_id` is **strict** — always use the exact `pi` from the item's selected pack. If missing, use `''` and log a warning. Never fall back to first pack.
- **Purchase flows (Purchase Invoice, Purchase Return):** `pack_id` is **lenient** — use item's `pack_id` if present, otherwise fall back to first pack's `pi` from `updatePacksStock()`.
- **Stock Voucher:** always `''` (no pack selection at voucher item level).

`packs.stk` movement is always across **all packs** on the vendor_product row regardless of which pack was selected — `pack_id` only affects the ledger row, not which pack's stock changes.

**Safety:** All inventory calls are wrapped in `try/catch` — an inventory failure can never roll back or block the main order/voucher save. Stock can never go below 0 (`max(0, stk - qty)`).
