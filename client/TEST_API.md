# Test API Response

## Quick Test

Run this in your terminal to see the API response:

```bash
curl http://10.0.2.2:8000/api/products | jq '.data[0]'
```

## Expected Response Format

The API should return JSON in this format:

```json
{
  "data": [
    {
      "product_id": 123,
      "product_name": "Product Name",
      "product_code": null,
      "product_type": "FINISHED",
      "default_unit": "WEIGHT"
    }
  ]
}
```

## Field Mapping

| API Field | Flutter Model | Type | Required |
|-----------|---------------|------|----------|
| `product_id` | `id` | int | ✅ Yes |
| `product_name` | `name` | String | ✅ Yes |
| `product_code` | `code` | String? | ❌ No |
| `product_type` | `productType` | String | ✅ Yes |
| `default_unit` | `defaultUnit` | String? | ❌ No |

## Product Types

- `FINISHED` - For finished products (shows in "Finished Product" dropdown)
- `RAW` - For raw materials (shows in "Raw Material" dropdown)

## Default Units

- `WEIGHT` - For weight-based products (KG)
- `QUANTITY` - For count-based products (PCS)
- `LITRE` - For liquid products (LTR)
- `METER` - For length-based products (MTR)

## What the Controller Does

1. **Fetches** products from `/api/products`
2. **Parses** JSON response
3. **Filters** out products with empty names
4. **Separates** by type (FINISHED vs RAW)
5. **Sorts** alphabetically by name
6. **Displays** in dropdowns

## If You Get Errors

### Check API Response
```bash
curl http://10.0.2.2:8000/api/products
```

Should return valid JSON with `data` array.

### Check First Product
```bash
curl http://10.0.2.2:8000/api/products | jq '.data[0]'
```

Should have all required fields: `product_id`, `product_name`, `product_type`

### Check Product Count
```bash
curl http://10.0.2.2:8000/api/products | jq '.data | length'
```

Should return a number > 0

## Debug Logs

Look for these in Flutter console:

```
[BOM] Fetching products from: http://10.0.2.2:8000/api/products
[BOM] Response status: 200
[BOM] Received 1234 products
[BOM] Loaded 56 finished products
[BOM] Loaded 1178 raw materials
```

If you see errors, they'll show as:
```
[BOM] Error loading products: <error message>
```
