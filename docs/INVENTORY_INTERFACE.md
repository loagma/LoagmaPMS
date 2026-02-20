# Inventory Interface Documentation

## Overview

The Inventory Interface provides a comprehensive view of all vendor products with their package-level stock information. It supports pagination, search, and real-time stock updates with automatic synchronization across package sizes.

## Features

### 1. Product List View
- **Pagination**: Loads 10 products at a time for optimal performance
- **Infinite Scroll**: Automatically loads more products as you scroll
- **Search**: Real-time search by product name
- **Stock Status Indicators**:
  - 🔴 Red: Out of stock
  - 🟠 Orange: Low stock (< 10 units)
  - 🟢 Green: In stock

### 2. Product Details View
- View all packages for a vendor product
- See stock levels for each package size
- View pricing information (original price, retail price, tax)
- Update stock for individual packages
- Check stock consistency across all packages

### 3. Stock Management
- **Increase/Decrease Stock**: Update stock for any package
- **Automatic Synchronization**: All related packages update proportionally
- **Reason Tracking**: Record reason for every stock change
- **Audit Trail**: All changes are logged for accountability

### 4. Consistency Checking
- Validate that all packages have proportionally correct stock
- Identify inconsistencies with detailed reports
- View expected vs actual stock for each package

## API Endpoints

### Get Vendor Products List
```
GET /api/vendor-products?limit=10&page=1&search=rice
```

**Query Parameters**:
- `limit` (optional, default: 10): Number of products per page
- `page` (optional, default: 1): Page number
- `search` (optional): Search query for product name

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "admin_vendor_id": 1,
      "product_id": 456,
      "product_name": "Basmati Rice",
      "packs": "[{\"pi\":\"pack_5kg\",\"ps\":\"5\",\"pu\":\"kg\",\"stk\":10,...}]",
      "default_pack_id": "pack_5kg",
      "status": "1",
      "in_stock": "1",
      "created_at": "2024-01-01 00:00:00"
    }
  ],
  "pagination": {
    "total": 150,
    "page": 1,
    "limit": 10,
    "total_pages": 15
  }
}
```

### Get Single Vendor Product
```
GET /api/vendor-products/{id}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "id": 123,
    "admin_vendor_id": 1,
    "product_id": 456,
    "product_name": "Basmati Rice",
    "packs": "[{\"pi\":\"pack_5kg\",\"ps\":\"5\",\"pu\":\"kg\",\"stk\":10,...}]",
    "default_pack_id": "pack_5kg",
    "status": "1",
    "in_stock": "1",
    "created_at": "2024-01-01 00:00:00"
  }
}
```

### Update Pack Stock
```
POST /api/vendor-products/{id}/packs/{packId}/stock
```

**Request Body**:
```json
{
  "stock_change": -5,
  "reason": "sale"
}
```

**Response**:
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

### Check Stock Consistency
```
GET /api/vendor-products/{id}/stock-consistency
```

**Response (Consistent)**:
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

**Response (Inconsistent)**:
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

## Flutter Implementation

### Files Created

1. **Models**:
   - `client/lib/models/inventory_model.dart`: VendorProduct and Pack models

2. **Controllers**:
   - `client/lib/controllers/inventory_controller.dart`: Inventory state management

3. **Screens**:
   - `client/lib/screens/modules/inventory_list_screen.dart`: Product list view
   - `client/lib/screens/modules/inventory_details_screen.dart`: Product details view

4. **Backend**:
   - `server/app/Http/Controllers/VendorProductController.php`: API endpoints

### Usage

#### Navigate to Inventory
```dart
Get.toNamed(AppRoutes.inventory);
```

#### Access from Dashboard
The Inventory module is available on the dashboard with an "Inventory" card.

## Data Structure

### Vendor Product
```dart
class VendorProduct {
  final int id;
  final int vendorId;
  final int productId;
  final String productName;
  final String status;
  final String inStock;
  final List<Pack> packs;
  final String? defaultPackId;
  final double? totalStock;
}
```

### Pack
```dart
class Pack {
  final String packId;        // pi
  final String packSize;      // ps
  final String packUnit;      // pu
  final double stock;         // stk
  final int inStock;          // in_stk
  final String tax;           // tx
  final String originalPrice; // op
  final String retailPrice;   // rp
  final int serialNumber;     // sn
}
```

## User Workflows

### Workflow 1: View Inventory
1. Open app and navigate to Dashboard
2. Tap on "Inventory" card
3. View list of all vendor products
4. Scroll to load more products
5. Use search to find specific products

### Workflow 2: Update Stock
1. Navigate to Inventory list
2. Tap on a product to view details
3. Tap "Update Stock" button on any package
4. Select "Increase" or "Decrease"
5. Enter quantity and reason
6. Tap "Update"
7. All related packages update automatically

### Workflow 3: Check Consistency
1. Navigate to product details
2. Tap the consistency check icon (✓) in app bar
3. View consistency status
4. If inconsistent, view detailed report
5. Fix inconsistencies by updating stock

### Workflow 4: Search Products
1. Navigate to Inventory list
2. Tap on search bar
3. Type product name
4. Press enter or search button
5. View filtered results
6. Clear search to see all products

## Performance Considerations

### Pagination
- Initial load: 10 products
- Subsequent loads: 10 products per scroll
- Prevents loading all products at once
- Improves app responsiveness

### Search Optimization
- Server-side search using SQL LIKE
- Debounced search input (on submit)
- Clears previous results before new search

### Caching
- Products cached in controller
- Refresh on pull-to-refresh
- Auto-refresh after stock updates

## Error Handling

### Network Errors
- Displays error snackbar
- Allows retry via refresh
- Maintains previous data if available

### Validation Errors
- Validates quantity input
- Validates reason input
- Shows user-friendly error messages

### API Errors
- Handles 404 (not found)
- Handles 400 (bad request)
- Handles 500 (server error)
- Displays appropriate error messages

## Testing

### Manual Testing Checklist

1. **List View**:
   - [ ] Products load on first open
   - [ ] Pagination works (scroll to load more)
   - [ ] Search filters products correctly
   - [ ] Clear search resets to all products
   - [ ] Pull-to-refresh reloads data
   - [ ] Empty state shows when no products
   - [ ] Loading indicator shows during fetch

2. **Details View**:
   - [ ] Product details load correctly
   - [ ] All packages display with correct data
   - [ ] Stock colors match status (red/orange/green)
   - [ ] Prices and tax display correctly
   - [ ] Refresh button reloads data

3. **Stock Update**:
   - [ ] Update dialog opens
   - [ ] Increase/decrease radio buttons work
   - [ ] Quantity validation works
   - [ ] Reason validation works
   - [ ] Stock updates successfully
   - [ ] All packages sync automatically
   - [ ] Success message displays
   - [ ] Product list refreshes

4. **Consistency Check**:
   - [ ] Consistency check runs
   - [ ] Consistent status shows success
   - [ ] Inconsistent status shows details
   - [ ] Inconsistency dialog displays correctly

## Future Enhancements

1. **Bulk Operations**:
   - Update stock for multiple products at once
   - Export inventory to CSV/Excel
   - Import stock updates from file

2. **Advanced Filters**:
   - Filter by stock status (in stock, low stock, out of stock)
   - Filter by vendor
   - Filter by product category

3. **Stock Alerts**:
   - Push notifications for low stock
   - Email alerts for out of stock
   - Configurable alert thresholds

4. **Analytics**:
   - Stock movement trends
   - Most/least stocked products
   - Stock value calculations

5. **Barcode Scanning**:
   - Scan product barcode to view details
   - Quick stock updates via barcode

## Troubleshooting

### Products Not Loading
- Check network connection
- Verify API endpoint is accessible
- Check server logs for errors
- Ensure database has vendor_products data

### Search Not Working
- Verify search query is being sent to API
- Check API logs for search parameter
- Ensure product names are searchable

### Stock Update Fails
- Verify pack_id exists in vendor product
- Check stock_change is valid number
- Ensure reason is provided
- Check API error response for details

### Inconsistency Check Shows Errors
- This is expected if stock was manually updated
- Use stock update feature to fix
- Check audit logs for recent changes

## Support

For issues or questions:
1. Check server logs: `storage/logs/laravel.log`
2. Check Flutter console for errors
3. Review API documentation: `server/docs/API_DOCUMENTATION.md`
4. Review service documentation: `server/docs/SERVICE_DOCUMENTATION.md`
