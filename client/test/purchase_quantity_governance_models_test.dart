import 'package:flutter_test/flutter_test.dart';

import 'package:client/models/purchase_order_model.dart';
import 'package:client/models/purchase_voucher_model.dart';

void main() {
  group('Purchase quantity governance models', () {
    test('PurchaseOrderItem parses used/left quantities', () {
      final item = PurchaseOrderItem.fromJson({
        'id': 1,
        'product_id': 101,
        'quantity': 10,
        'price': 20,
        'used_qty': 5,
        'left_qty': 5,
      });

      expect(item.usedQty, 5);
      expect(item.leftQty, 5);
    });

    test('PurchaseVoucherItemRow parses overrun and PO-line fields', () {
      final row = PurchaseVoucherItemRow.fromJson({
        'source_purchase_order_id': 11,
        'source_purchase_order_item_id': 21,
        'source_po_number': 'PO-25-0001',
        'ordered_qty': 10,
        'used_qty': 8,
        'left_qty': 2,
        'quantity': 4,
        'overrun_qty': 2,
        'is_overrun_approved': true,
        'overrun_reason': 'Urgent requirement',
        'overrun_approved_by': 501,
        'overrun_approved_at': '2026-04-08 10:30:00',
      });

      expect(row.sourcePurchaseOrderId, 11);
      expect(row.sourcePurchaseOrderItemId, 21);
      expect(row.orderedQty, 10);
      expect(row.usedQty, 8);
      expect(row.leftQty, 2);
      expect(row.isOverrunApproved, true);
      expect(row.overrunQty, 2);
      expect(row.overrunApprovedBy, 501);
    });
  });
}
