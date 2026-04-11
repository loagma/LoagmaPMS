## Plan: Purchase Voucher Quantity Governance

Implement strict line-level PO consumption tracking with controlled over-quantity override, so linked purchase vouchers cannot silently exceed PO quantities and partially consumed POs remain transparently pending across multiple invoices. The approach introduces a durable data model for "ordered vs used vs left", enforces backend integrity, and adds a user confirmation dialog + visibility in Flutter.

**Steps**
1. Phase 1 - Domain Contract and Migration Strategy
2. Define a canonical quantity contract at line level: ordered_qty, consumed_qty, remaining_qty, overrun_qty, is_overrun_approved, overrun_reason, overrun_approved_by, overrun_approved_at. This is the backbone for API and UI consistency.
3. Decide destructive reset execution for legacy data (as requested): document SQL cleanup order, downtime window, and rollback snapshot. *blocks all later steps*
4. Add schema changes to support line-level traceability and overrun audit: add source_purchase_order_item_id in voucher items, add consumption counters in PO items, add overrun audit fields in voucher items, and add indexes for fast aggregation. *depends on 3*
5. Phase 2 - Backend Integrity and Status Automation
6. Introduce a dedicated quantity allocation service in Laravel to centralize checks/recompute logic (single source of truth used by create/update/post). *depends on 4*
7. Enforce server validation pipeline in purchase voucher create/update: supplier consistency with linked PO, mandatory source_purchase_order_item_id for linked lines, remaining calculation from DRAFT+POSTED vouchers, overrun rejection unless explicit override_approved=true, optional overrun reason capture. *depends on 6*
8. Add final backend guard even when client already confirmed at line edit time, to prevent race-condition bypasses and direct API misuse. *depends on 7*
9. Automate purchase order status from computed remaining quantities: OPEN/PENDING when partially consumed, CLOSED when fully consumed; prevent CLOSED if any line has remaining > 0. *depends on 7*
10. Expose new read-model fields in APIs for PO link dialog and voucher line rendering: used_qty, left_qty, overrun_qty and warning metadata. *depends on 7; parallel with 9*
11. Phase 3 - Flutter UX and Workflow
12. Extend voucher line model state to include poLineId, orderedQty, usedQty, leftQty, overrun flags, and approval reason fields. *depends on 10*
13. Update PO linking flow to bind each voucher line to a specific PO line id (strict mapping) and preload live used/left quantities from backend response. *depends on 12*
14. Add line-edit over-quantity dialog: when entered qty > left_qty, ask accept/reject; if accepted set override flag (and optional reason), if rejected clamp/revert qty and show inline guidance. *depends on 13*
15. Display per-line consumption info in voucher UI format requested: "Used X, Left Y"; add overrun badge so subsequent purchase invoices clearly show excess over PO. *depends on 14*
16. Keep save/post behavior aligned: no extra dialog at save, but API errors must map to row-level messages when backend guard rejects due to stale usage updates. *depends on 14*
17. Phase 4 - Operations, Quality, and Rollout
18. Add backend tests: unit tests for allocation math and feature tests for create/update with exact, partial, overrun-approved, overrun-rejected, concurrent updates, supplier mismatch, and status transitions. *depends on 7*
19. Add Flutter tests: controller tests for dialog decision paths and widget tests for "Used X, Left Y" and overrun labels. *depends on 15*
20. Define rollout controls: perform destructive legacy cleanup first, run migrations, deploy backend before client, then enable client release. Keep temporary monitoring logs for overrun approvals. *depends on 18 and 19*

**Relevant files**
- c:/sparsh workspace/ADRS/LoagmaPMS/server/app/Http/Controllers/PurchaseVoucherController.php — inject line-level validation hooks and payload contract enforcement.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/app/Http/Controllers/PurchaseOrderController.php — expose pending/consumed fields and status updates for linked order views.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/app/Models/PurchaseOrder.php — include computed consumption/status projections for API serialization.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/app/Models/PurchaseOrderItem.php — persist and expose ordered/used/left counters.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/app/Models/PurchaseVoucher.php — ensure PO relation and status-aware aggregation behavior.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/app/Models/PurchaseVoucherItem.php — store source_purchase_order_item_id and overrun audit metadata.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/database/migrations — add schema/index/audit migrations for quantity governance.
- c:/sparsh workspace/ADRS/LoagmaPMS/server/routes/api.php — verify/extend endpoints for PO line-level quantity visibility.
- c:/sparsh workspace/ADRS/LoagmaPMS/client/lib/controllers/purchase_voucher_controller.dart — line-edit dialog flow, override state management, API error mapping.
- c:/sparsh workspace/ADRS/LoagmaPMS/client/lib/screens/modules/purchase_voucher_screen.dart — quantity input trigger, dialog UI, "Used X, Left Y" display, overrun indicator.
- c:/sparsh workspace/ADRS/LoagmaPMS/client/lib/models/purchase_voucher_model.dart — request/response model updates for poLineId and overrun fields.
- c:/sparsh workspace/ADRS/LoagmaPMS/client/lib/models/purchase_order_model.dart — PO line quantity projection fields consumed by voucher linker.

**Verification**
1. Run backend migration in staging after DB snapshot and validate new columns/indexes exist.
2. Execute API feature tests for all quantity cases: exact, partial, multi-voucher partial, overrun reject, overrun accept, stale concurrent update reject.
3. Manual backend scenario: PO qty 10, voucher A uses 5 -> PO shows pending and left 5; voucher B attempts 7 -> dialog accept path required and overrun recorded +2.
4. Validate purchase invoice/voucher retrieval shows overrun metadata for lines where accepted quantity exceeded linked PO left.
5. Validate UI workflow: line-edit dialog appears only on exceed, reject path restores valid qty, accept path persists override and displays Used/Left correctly.
6. Regression test unrelated voucher flows (unlinked vouchers, drafts, posted records, taxes/total recalculation) to ensure no breakage.

**Decisions**
- Over-quantity policy: allowed only with explicit user confirmation override.
- Override reason: optional.
- Dialog timing: line edit only, with mandatory backend final guard at save/post.
- Consumption basis: DRAFT + POSTED vouchers count toward used quantity.
- Mapping rule: strict PO line-level mapping (not product-level approximation).
- Legacy handling: delete existing purchase voucher/order data before rollout (destructive reset).
- UI text: show "Used X, Left Y" per linked line.
- Tolerance: none; only explicit override can exceed remaining quantity.

**Further Considerations**
1. Destructive cleanup safety: prefer a one-time archival export (SQL dump) before deletion so rollback remains possible.
2. Concurrency control: add optimistic check token (updated_at/version) per PO line to improve user messaging for simultaneous edits.
3. Audit visibility: add an overrun approvals report filter in voucher list to monitor policy exceptions after go-live.
