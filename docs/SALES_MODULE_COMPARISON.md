# Sales Module Comparison

## Previous

| Area | Current structure |
|---|---|
| Main header table | `orders` |
| Main item table | `orders_item` |
| Customer master | `user` |
| Sales number | `order_id` / mixed legacy IDs |
| Status tracking | `order_state`, `payment_status` |
| Delivery tracking | `trip_id`, `deli_id`, JSON in `delivery_info` |
| Item fulfillment | `quantity`, `qty_loaded`, `qty_delivered`, `qty_returned` |
| Pricing | `item_price`, `item_total`, `discount`, `delivery_charge` |
| Payment details | `amountReceivedInfo` JSON text |
| Product reference | `product_id`, `vendor_product_id` |
| Reporting | Legacy dump-style output |

## What We Want

| Area | Target structure |
|---|---|
| Main header table | `sales_orders` |
| Main item table | `sales_order_items` |
| Customer master | `customers` or a dedicated customer view over `user` |
| Sales number | `sales_no` / `invoice_no` with prefix + sequence |
| Status tracking | `order_status`, `payment_status`, `fulfillment_status` |
| Delivery tracking | Normalized delivery assignment tables + structured fields |
| Item fulfillment | Keep line-level quantity tracking, but normalize workflow states |
| Pricing | Keep line totals, add tax/discount breakdown columns if needed |
| Payment details | Separate payment table / transaction ledger |
| Product reference | Keep product reference, add FK constraints if possible |
| Reporting | API + report views based on the new sales module |

## Recommendation

| Decision | Choice |
|---|---|
| Data source | Use current tables as historical source |
| New module | Build around `sales_orders` and `sales_order_items` |

## Exact New Tables

| # | Table name | Structure summary |
|---|---|---|

| 1 | `sales_customers` | `id`, `legacy_user_id`, `name`, `contact_no`, `email`, `address`, `city_id`, `area_id`, `gst_no`, `customer_type`, `is_active`, `created_at`, `updated_at` |
| 2 | `sales_orders` | `id`, `sales_no`, `invoice_no`, `customer_id`, `order_date`, `delivery_date`, `order_status`, `payment_status`, `fulfillment_status`, `delivery_type`, `trip_id`, `deli_id`, `subtotal`, `discount_total`, `delivery_charge`, `tax_total`, `grand_total`, `notes`, `created_by`, `updated_by`, `created_at`, `updated_at` |
| 3 | `sales_order_items` | `id`, `sales_order_id`, `product_id`, `vendor_product_id`, `line_no`, `product_name`, `unit`, `quantity`, `qty_loaded`, `qty_delivered`, `qty_returned`, `rate`, `discount_percent`, `tax_percent`, `line_total`, `created_at`, `updated_at` |
| 4 | `sales_payments` | `id`, `sales_order_id`, `payment_date`, `payment_method`, `reference_no`, `amount`, `payment_status`, `received_by`, `remarks`, `created_at`, `updated_at` |
| 5 | `sales_shipments` | `id`, `sales_order_id`, `trip_id`, `deli_id`, `route_name`, `vehicle_no`, `driver_name`, `driver_mobile`, `shipment_status`, `packed_at`, `dispatched_at`, `delivered_at`, `created_at`, `updated_at` |
| 6 | `sales_returns` | `id`, `sales_order_id`, `return_no`, `return_date`, `return_status`, `reason`, `refund_amount`, `created_by`, `approved_by`, `created_at`, `updated_at` |
| 7 | `sales_return_items` | `id`, `sales_return_id`, `sales_order_item_id`, `product_id`, `quantity`, `refund_amount`, `reason`, `created_at`, `updated_at` |

| Total tables | 7 |
