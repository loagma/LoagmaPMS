# Max Variation (mv) — Testing Guide

`mv` limits how much a salesman can vary a pack's price in an order or invoice.
If `mv = 10`, the price must stay within `rp ± 10%`. If `mv` is absent, price is freely editable.

---

## Test Products

### 1. Aalmond - Australian (Product ID: 532)

| Pack | Base Price (rp) | mv | Allowed Range | Min | Max |
|---|---|---|---|---|---|
| 500g | ₹369 | ±10% | ₹332.10 – ₹405.90 | ₹332.10 | ₹405.90 |
| 10gm | ₹19 | ±5% | ₹18.05 – ₹19.95 | ₹18.05 | ₹19.95 |

---

### 2. Green Grapes - Angoor (Product ID: 555)

| Pack | Base Price (rp) | mv | Allowed Range | Notes |
|---|---|---|---|---|
| 1 kg | ₹60 | ±15% | ₹51.00 – ₹69.00 | Restricted |
| 500 gm | ₹30 | **none** | Free | No hint shown, no validation |

> Green Grapes 500gm intentionally has **no mv** — use this to verify free pricing still works normally.

---

### 3. Mint Leaves - Pudina (Product ID: 587)

| Pack | Base Price (rp) | mv | Allowed Range | Min | Max |
|---|---|---|---|---|---|
| 1 piece | ₹15 | ±20% | ₹12.00 – ₹18.00 | ₹12.00 | ₹18.00 |
| 10 pieces | ₹160 | ±8% | ₹147.20 – ₹172.80 | ₹147.20 | ₹172.80 |

---

## What to Test

### In the Order / Invoice Form

1. **Add any of the above products** → select a pack with `mv` set
2. **Inline hint appears** below the price field showing the allowed range in grey
3. **Type a price within range** → hint stays grey, save proceeds normally
4. **Type a price outside range** → hint turns red with the allowed range
5. **Tap Save with an out-of-range price** → warning dialog appears:
   - Title: "Price Out of Range"
   - Lists each violating item with product name and allowed range
   - Only "Fix Prices" button — save is blocked
6. **Add Green Grapes 500gm** → no hint shown, price freely editable, no dialog on save

### In the Product Package Form

1. Open any product → tap a pack → edit
2. **Max Variation %** field is visible below Retail Prices
3. Enter `10` → save → verify pack JSON now contains `"mv": 10`
4. Clear the field → save → `mv` key is removed from the pack JSON

---

## Quick Reference — All Test Ranges

| Product | Pack | Type price | Expected |
|---|---|---|---|
| Aalmond 500g | rp=369, mv=10% | ₹350 | ✅ within range |
| Aalmond 500g | rp=369, mv=10% | ₹300 | ❌ below ₹332.10 |
| Aalmond 500g | rp=369, mv=10% | ₹410 | ❌ above ₹405.90 |
| Aalmond 10gm | rp=19, mv=5% | ₹19 | ✅ within range |
| Aalmond 10gm | rp=19, mv=5% | ₹17 | ❌ below ₹18.05 |
| Green Grapes 1kg | rp=60, mv=15% | ₹55 | ✅ within range |
| Green Grapes 1kg | rp=60, mv=15% | ₹70 | ❌ above ₹69.00 |
| Green Grapes 500gm | no mv | ₹5 or ₹500 | ✅ always allowed |
| Mint 1 piece | rp=15, mv=20% | ₹13 | ✅ within range |
| Mint 1 piece | rp=15, mv=20% | ₹11 | ❌ below ₹12.00 |
| Mint 10 pieces | rp=160, mv=8% | ₹160 | ✅ exact base |
| Mint 10 pieces | rp=160, mv=8% | ₹180 | ❌ above ₹172.80 |
