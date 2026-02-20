# API Documentation: Linked Package Stock Management

## Overview

This document describes the REST API endpoints for the Linked Package Stock Management system. All endpoints automatically synchronize stock levels across multiple package sizes using proportional calculations.

## Base URL

```
/api
```

## Authentication

All endpoints require authentication. Include your authentication token in the request headers:

```
Authorization: Bearer {your_token}
```

## Error Handling

All endpoints use consistent error response format:

```json
{
  "success": false,
  "message": "Error description",
  "errors": {
    "field_name": ["Error detail"]
  }
}
```

### HTTP Status Codes

- `200 OK`: Request succeeded
- `201 Created`: Resource created successfully
- `400 Bad Request`: Validation error or business logic error
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation failed
- `500 Internal Server Error`: Unexpected server error

### Error Codes

| Code | Message | Description |
|------|---------|-------------|
| `VENDOR_PRODUCT_NOT_FOUND` | Vendor product not found | The specified vendor product ID doesn't exist |
| `PACK_NOT_FOUND` | Pack not found in vendor product | The specified pack_id doesn't exist in the vendor product |
| `JSON_PARSE_ERROR` | Failed to parse pack JSON | The pack JSON data is malformed |
| `VALIDATION_ERROR` | Validation failed | Request data failed validation |
| `MISSING_REQUIRED_FIELDS` | Missing required transaction fields | Required fields are missing from the request |

---

## Endpoints

### 1. Update Pack Stock

Updates stock for a specific package and automatically synchronizes all related packages.

**Endpoint**: `POST /api/vendor-products/{id}/packs/{packId}/stock`

**URL Parameters**:
- `id` (integer, required): Vendor product ID
- `packId` (string, required): Pack ID (from `pi` field in JSON)

**Request Body**:
```json
{
  "stock_change": -5,
  "reason": "sale"
}
```

**Request Fields**:
- `stock_change` (number, required): Amount to change stock by (positive for increase, negative for decrease)
- `reason` (string, required, max 255 chars): Reason for the stock change

**Success Response** (200 OK):
```json
{
  "success": true,
  "message": "Stock updated successfully",
  "data": {
    "pack_updates": [
      {
        "pack_id": "pack_5kg",
        "old_stock": 10,
        "new_stock": 5,
        "change": -5
      },
      {
        "pack_id": "pack_1kg",
        "old_stock": 50,
        "new_stock": 25,
        "change": -25
      }
    ]
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "message": "Vendor product not found",
  "errors": {
    "vendor_product_id": 123
  }
}
```

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/vendor-products/123/packs/pack_5kg/stock \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer {token}' \
  -d '{
    "stock_change": -5,
    "reason": "sale to customer ABC"
  }'
```

**Use Cases**:
- Manual stock adjustments
- Correcting stock discrepancies
- Recording stock changes from external systems

---

### 2. Process Inventory Transaction

Processes an inventory transaction and updates all affected packages. Supports different action types (purchase, sale, return, etc.).

**Endpoint**: `POST /api/inventory-transactions`

**Request Body**:
```json
{
  "vendor_product_id": 123,
  "pack_id": "pack_5kg",
  "quantity": 10,
  "action_type": "purchase",
  "notes": "Purchase order #PO-2024-001"
}
```

**Request Fields**:
- `vendor_product_id` (integer, required): Vendor product ID
- `pack_id` (string, required): Pack ID (from `pi` field in JSON)
- `quantity` (number, required): Transaction quantity (always positive)
- `action_type` (string, required): Type of transaction
  - `purchase`: Add stock (purchase from supplier)
  - `sale`: Reduce stock (sale to customer)
  - `return`: Add stock (customer return)
  - `damage`: Reduce stock (damaged goods)
  - `adjustment_increase`: Add stock (manual adjustment)
  - `adjustment_decrease`: Reduce stock (manual adjustment)
  - `adjustment`: Use quantity as-is (generic adjustment)
- `notes` (string, optional, max 500 chars): Additional notes for audit trail

**Success Response** (200 OK):
```json
{
  "success": true,
  "message": "Stock updated successfully",
  "data": {
    "pack_updates": [
      {
        "pack_id": "pack_5kg",
        "old_stock": 10,
        "new_stock": 20,
        "change": 10
      },
      {
        "pack_id": "pack_1kg",
        "old_stock": 50,
        "new_stock": 100,
        "change": 50
      }
    ]
  }
}
```

**Error Response** (400 Bad Request):
```json
{
  "success": false,
  "message": "Missing required transaction fields",
  "errors": {
    "required_fields": ["vendor_product_id", "pack_id", "quantity"],
    "provided": {
      "vendor_product_id": 123
    }
  }
}
```

**Validation Error Response** (422 Unprocessable Entity):
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "action_type": [
      "The selected action type is invalid."
    ],
    "quantity": [
      "The quantity must be a number."
    ]
  }
}
```

**Example Request**:
```bash
curl -X POST \
  http://localhost:8000/api/inventory-transactions \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer {token}' \
  -d '{
    "vendor_product_id": 123,
    "pack_id": "pack_5kg",
    "quantity": 10,
    "action_type": "purchase",
    "notes": "Purchase order #PO-2024-001"
  }'
```

**Action Type Behavior**:

| Action Type | Effect | Use Case |
|-------------|--------|----------|
| `purchase` | Adds to stock | Receiving goods from supplier |
| `sale` | Reduces stock | Selling goods to customer |
| `return` | Adds to stock | Customer returns |
| `damage` | Reduces stock | Damaged or expired goods |
| `adjustment_increase` | Adds to stock | Manual stock increase |
| `adjustment_decrease` | Reduces stock | Manual stock decrease |
| `adjustment` | Uses quantity as-is | Generic adjustment |

**Use Cases**:
- Recording purchase orders
- Processing sales transactions
- Handling customer returns
- Recording damaged goods
- Manual stock adjustments

---

### 3. Validate Stock Consistency

Validates that all packages have proportionally correct stock levels. Useful for detecting data integrity issues.

**Endpoint**: `GET /api/vendor-products/{id}/stock-consistency`

**URL Parameters**:
- `id` (integer, required): Vendor product ID

**Success Response** (200 OK) - Consistent:
```json
{
  "success": true,
  "data": {
    "is_consistent": true,
    "inconsistencies": [],
    "reference_base_units": 50.0
  }
}
```

**Success Response** (200 OK) - Inconsistent:
```json
{
  "success": true,
  "data": {
    "is_consistent": false,
    "inconsistencies": [
      {
        "pack_id": "pack_5kg",
        "pack_size": "5",
        "pack_unit": "kg",
        "expected_stock": 10.0,
        "actual_stock": 9.0,
        "difference": 1.0,
        "difference_in_base_units": 5.0
      }
    ],
    "reference_base_units": 50.0
  }
}
```

**Response Fields**:
- `is_consistent` (boolean): Whether stock is consistent across all packages
- `inconsistencies` (array): List of inconsistencies found (empty if consistent)
  - `pack_id` (string): Pack identifier
  - `pack_size` (string): Package size
  - `pack_unit` (string): Package unit
  - `expected_stock` (number): Expected stock based on proportional calculation
  - `actual_stock` (number): Actual stock in database
  - `difference` (number): Difference in package units
  - `difference_in_base_units` (number): Difference in base units
- `reference_base_units` (number): Total stock in base units

**Example Request**:
```bash
curl -X GET \
  http://localhost:8000/api/vendor-products/123/stock-consistency \
  -H 'Authorization: Bearer {token}'
```

**Use Cases**:
- Periodic data integrity checks
- Debugging stock discrepancies
- Audit trail validation
- Post-migration verification

**Consistency Tolerance**: The system allows a tolerance of 0.01 base units to account for rounding errors.

---

## Integration Guide

### Workflow 1: Recording a Purchase

```bash
# Step 1: Process purchase transaction
POST /api/inventory-transactions
{
  "vendor_product_id": 123,
  "pack_id": "pack_10kg",
  "quantity": 50,
  "action_type": "purchase",
  "notes": "PO-2024-001 from Supplier XYZ"
}

# Step 2: Verify consistency (optional)
GET /api/vendor-products/123/stock-consistency
```

### Workflow 2: Recording a Sale

```bash
# Step 1: Process sale transaction
POST /api/inventory-transactions
{
  "vendor_product_id": 123,
  "pack_id": "pack_5kg",
  "quantity": 10,
  "action_type": "sale",
  "notes": "Invoice #INV-2024-456"
}

# Step 2: Check updated stock
GET /api/vendor-products/123/stock-consistency
```

### Workflow 3: Manual Stock Adjustment

```bash
# Option A: Using inventory transaction endpoint
POST /api/inventory-transactions
{
  "vendor_product_id": 123,
  "pack_id": "pack_5kg",
  "quantity": 5,
  "action_type": "adjustment_increase",
  "notes": "Physical count adjustment"
}

# Option B: Using direct stock update endpoint
POST /api/vendor-products/123/packs/pack_5kg/stock
{
  "stock_change": 5,
  "reason": "Physical count adjustment"
}
```

### Workflow 4: Detecting and Fixing Inconsistencies

```bash
# Step 1: Check consistency
GET /api/vendor-products/123/stock-consistency

# Response shows inconsistency:
# {
#   "is_consistent": false,
#   "inconsistencies": [...]
# }

# Step 2: Fix by updating stock for one package
# (all other packages will sync automatically)
POST /api/vendor-products/123/packs/pack_5kg/stock
{
  "stock_change": 0,
  "reason": "Consistency fix - recalculate all packages"
}

# Step 3: Verify fix
GET /api/vendor-products/123/stock-consistency
```

---

## Data Models

### Pack JSON Structure

The `vendor_products.packs` field contains a JSON array of packages:

```json
[
  {
    "pi": "pack_5kg",
    "ps": "5",
    "pu": "kg",
    "stk": 10,
    "in_stk": 1,
    "tx": "5",
    "op": "500",
    "rp": "550",
    "sn": 1
  },
  {
    "pi": "pack_1kg",
    "ps": "1",
    "pu": "kg",
    "stk": 50,
    "in_stk": 1,
    "tx": "5",
    "op": "100",
    "rp": "110",
    "sn": 2
  }
]
```

**Field Descriptions**:
- `pi` (pack_id): Unique identifier for the package
- `ps` (pack_size): Numeric size value (e.g., "5", "500")
- `pu` (pack_unit): Unit type (e.g., "kg", "gm", "nos")
- `stk` (stock): Current stock level
- `in_stk` (in_stock): Stock availability flag (0 = out of stock, 1 = in stock)
- `tx` (tax): Tax percentage
- `op` (original_price): Original price
- `rp` (retail_price): Retail price
- `sn` (serial_number): Display order

**Important**: The API automatically updates `stk` and `in_stk` fields. All other fields are preserved.

---

## Supported Units

### Weight Units
- `kg` (kilogram) - Base unit
- `gm` (gram) - Converted to kg (1 gm = 0.001 kg)

### Volume Units
- `litre` - Base unit
- `ml` (milliliter) - Converted to litre (1 ml = 0.001 litre)

### Discrete Units
- `nos` (numbers/pieces)
- `pack`
- `dozen`
- `box`
- `bag`
- `piece`
- `bunch`
- `tin`
- `pouch`
- `cs` (case)
- `barrel`
- `jar`

**Note**: Discrete units are automatically rounded to the nearest integer.

---

## Rate Limiting

API endpoints are rate-limited to prevent abuse:

- **Rate Limit**: 60 requests per minute per user
- **Headers**: Rate limit information is included in response headers:
  - `X-RateLimit-Limit`: Maximum requests per minute
  - `X-RateLimit-Remaining`: Remaining requests in current window
  - `X-RateLimit-Reset`: Unix timestamp when the rate limit resets

**Rate Limit Exceeded Response** (429 Too Many Requests):
```json
{
  "message": "Too Many Attempts."
}
```

---

## Webhooks (Future Feature)

Webhook support for stock change notifications is planned for a future release. This will allow external systems to receive real-time notifications when stock levels change.

---

## Testing

### Test Endpoints

Use the following test data for development:

**Test Vendor Product**:
- ID: 999
- Packs: 5kg, 1kg packages

**Test Requests**:

```bash
# Test stock increase
curl -X POST http://localhost:8000/api/vendor-products/999/packs/pack_5kg/stock \
  -H 'Content-Type: application/json' \
  -d '{"stock_change": 10, "reason": "test"}'

# Test stock decrease
curl -X POST http://localhost:8000/api/vendor-products/999/packs/pack_5kg/stock \
  -H 'Content-Type: application/json' \
  -d '{"stock_change": -5, "reason": "test"}'

# Test consistency check
curl -X GET http://localhost:8000/api/vendor-products/999/stock-consistency
```

---

## Troubleshooting

### Common Issues

**Issue**: "Vendor product not found" error
- **Cause**: Invalid vendor_product_id
- **Solution**: Verify the vendor product exists in the database

**Issue**: "Pack not found in vendor product" error
- **Cause**: pack_id doesn't match any package in the vendor product
- **Solution**: Check the `pi` field in the vendor_products.packs JSON

**Issue**: "Failed to parse pack JSON" error
- **Cause**: Malformed JSON in vendor_products.packs field
- **Solution**: Validate and fix the JSON structure in the database

**Issue**: Stock inconsistencies after manual database updates
- **Cause**: Direct database updates bypassed the synchronization logic
- **Solution**: Use the API endpoints or call StockManagerService directly

**Issue**: Negative stock values
- **Cause**: Stock reduction exceeds available stock
- **Solution**: This is allowed by design; implement business logic to prevent if needed

### Debug Mode

Enable detailed API logging by setting log level to DEBUG in `.env`:

```
LOG_LEVEL=debug
```

Check logs at `storage/logs/laravel.log` for detailed request/response information.

---

## Changelog

### Version 1.0.0 (Current)
- Initial release
- Stock update endpoint
- Inventory transaction endpoint
- Consistency validation endpoint
- Support for 17 unit types
- Automatic package synchronization
- Audit trail logging

---

## Support

For API support:
- Review the [Service Documentation](./SERVICE_DOCUMENTATION.md)
- Review the [Integration Guide](./INTEGRATION_GUIDE.md)
- Check audit logs in `storage/logs/laravel.log`
- Contact the development team

---

## Appendix: Complete Example

### Scenario: Recording a Purchase and Verifying Stock

```bash
# 1. Check current stock consistency
curl -X GET http://localhost:8000/api/vendor-products/123/stock-consistency \
  -H 'Authorization: Bearer {token}'

# Response:
# {
#   "success": true,
#   "data": {
#     "is_consistent": true,
#     "reference_base_units": 50.0
#   }
# }

# 2. Process purchase transaction (50 units of 10kg package)
curl -X POST http://localhost:8000/api/inventory-transactions \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer {token}' \
  -d '{
    "vendor_product_id": 123,
    "pack_id": "pack_10kg",
    "quantity": 50,
    "action_type": "purchase",
    "notes": "Purchase order #PO-2024-001"
  }'

# Response:
# {
#   "success": true,
#   "message": "Stock updated successfully",
#   "data": {
#     "pack_updates": [
#       {
#         "pack_id": "pack_10kg",
#         "old_stock": 5,
#         "new_stock": 55,
#         "change": 50
#       },
#       {
#         "pack_id": "pack_5kg",
#         "old_stock": 10,
#         "new_stock": 110,
#         "change": 100
#       },
#       {
#         "pack_id": "pack_1kg",
#         "old_stock": 50,
#         "new_stock": 550,
#         "change": 500
#       }
#     ]
#   }
# }

# 3. Verify consistency after update
curl -X GET http://localhost:8000/api/vendor-products/123/stock-consistency \
  -H 'Authorization: Bearer {token}'

# Response:
# {
#   "success": true,
#   "data": {
#     "is_consistent": true,
#     "reference_base_units": 550.0
#   }
# }
```

This example demonstrates:
1. Initial consistency check
2. Processing a purchase transaction
3. Automatic synchronization across all package sizes (10kg, 5kg, 1kg)
4. Final consistency verification
