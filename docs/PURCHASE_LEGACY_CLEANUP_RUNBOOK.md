## Purchase Legacy Cleanup Runbook

### Purpose
Use this runbook to safely perform destructive cleanup of legacy purchase order and purchase voucher data before enabling strict line-level quantity governance.

### Preconditions
1. Maintenance window approved.
2. Full SQL backup taken and verified.
3. Application writes paused for purchase modules.
4. Team notified (backend, QA, finance ops).

### Backup
1. Export database snapshot before cleanup.
2. Store backup in a secure, timestamped path.

### Execution
1. Run migration updates first:

```bash
php artisan migrate
```

2. Execute cleanup script:

```bash
mysql -u <user> -p <database_name> < docs/purchase_legacy_cleanup.sql
```

3. Verify cleanup counts:

```sql
SELECT COUNT(*) AS c FROM purchase_orders;
SELECT COUNT(*) AS c FROM purchase_order_items;
SELECT COUNT(*) AS c FROM purchase_vouchers;
SELECT COUNT(*) AS c FROM purchase_voucher_items;
```

### Post-Cleanup Validation
1. Create a PO with one line (qty 10).
2. Create voucher linked to same PO line with qty 5.
3. Confirm PO shows partially received and left qty 5.
4. Create second voucher for qty 7 and verify overrun confirmation is required.

### Rollback
1. If validation fails, restore from pre-cleanup SQL backup.
2. Re-run migrations if schema changed since backup.

### Ownership
- Executor: Backend engineer
- Verifier: QA lead
- Approver: Product/Finance owner
