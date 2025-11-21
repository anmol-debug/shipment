# Business Data Validation

## Overview

Added comprehensive validation for shipment business data fields including container numbers, BOL numbers, ports, weights, flight numbers, and more.

## Where Validation Was Added

### 1. New Validator Module: [app/services/validators.py](app/services/validators.py)

Created a new module with the `ShipmentValidator` class that validates all business data fields.

**Location**: `/Users/anmolgewal/take_home/app/services/validators.py`

**What it validates**:

#### Status Field
- Must be one of: `new`, `pending`, `in_progress`, `completed`, `cancelled`, `archived`
- Case-insensitive
- **Example Error**: `"Validation Error: Invalid status 'unknown'. Must be one of: archived, cancelled, completed, in_progress, new, pending"`

#### Transport Mode
- Must be one of: `ocean`, `air`, `land`, `rail`
- Case-insensitive
- **Example Error**: `"Validation Error: Invalid transport mode 'truck'. Must be one of: air, land, ocean, rail"`

#### Container Number
- Must follow ISO 6346 format: 4 uppercase letters + 7 digits
- Example valid: `MSCU1234567`
- **Example Error**: `"Validation Error: Invalid container number format. Must be 4 uppercase letters followed by 7 digits (e.g., MSCU1234567)"`

#### BOL Numbers (House and Master)
- Must be 4-20 characters
- Alphanumeric with dashes allowed
- **Example Error**: `"Validation Error: House BOL must be at least 4 characters"`

#### Port Names
- Minimum 2 characters, maximum 100 characters
- Allows international characters (Unicode letters)
- Allows spaces, commas, periods, dashes, parentheses
- Valid examples: `"Shanghai, China"`, `"Long Beach, CA"`, `"Los Angeles"`
- **Example Error**: `"Validation Error: Port of Loading must be at least 2 characters"`

#### Weight (Gross Weight)
- Must be a positive number
- Automatically strips unit suffixes (e.g., "1000 KGS" → 1000)
- Maximum 1,000,000 kg (sanity check)
- **Example Errors**:
  - `"Validation Error: Weight must be a positive number"`
  - `"Validation Error: Weight must be a valid number"`
  - `"Validation Error: Weight seems unreasonably high (max 1,000,000 kg)"`

#### Vessel Name
- Minimum 2 characters, maximum 100 characters
- Alphanumeric with spaces and common punctuation
- Valid examples: `"COSCO BELGIUM"`, `"Maersk Line"`
- **Example Error**: `"Validation Error: Vessel name must be at least 2 characters"`

#### Voyage Number
- Minimum 2 characters, maximum 20 characters
- Alphanumeric with dashes/underscores
- Valid examples: `"095E"`, `"V-2024-001"`
- **Example Error**: `"Validation Error: Voyage number must be alphanumeric"`

#### Flight Number
- Must be 2-3 letters + 1-4 digits
- Format: Airline code + flight number
- Valid examples: `"AA123"`, `"UA4567"`, `"DL1234"`
- **Example Error**: `"Validation Error: Flight number must be 2-3 letters followed by 1-4 digits (e.g., AA123)"`

#### Names (Consignee, Shipper)
- Minimum 2 characters, maximum 200 characters
- Allows international characters
- Allows common business punctuation (ampersand, apostrophes, quotes, commas, periods)
- Valid examples: `"KABOFER TRADING INC"`, `"John & Sons Co., Ltd."`
- **Example Error**: `"Validation Error: Consignee Name must be at least 2 characters"`

### 2. Updated Audit Service: [app/services/audit_service.py](app/services/audit_service.py)

**Modified**: Lines 9, 95-103

**What changed**:
```python
# Added import
from app.services.validators import validate_shipment_data, ValidationError

# Added validation call in create_audit_event()
# ========================================
# BUSINESS DATA VALIDATION
# ========================================
# Validate business data fields (container numbers, ports, weights, etc.)
try:
    validate_shipment_data(snapshot_data, strict=False)
except ValidationError as e:
    # Re-raise with proper type
    raise ValueError(str(e))
```

**When it runs**:
- Every time an audit event is created
- Before database transaction begins
- Returns clear error messages immediately

## Validation Flow

```
1. User edits shipment in frontend
   ↓
2. Frontend sends POST /api/shipments/{id}/audit with snapshot_data
   ↓
3. API routes.py receives request
   ↓
4. audit_service.create_audit_event() is called
   ↓
5. VALIDATION LAYER 1: Event-level validation
   - shipment_id required?
   - event_type valid?
   - actor_id and actor_name provided?
   - snapshot_data has id and title?
   ↓
6. VALIDATION LAYER 2: Business data validation (NEW!)
   - validate_shipment_data() checks all fields
   - Container number format valid?
   - Status is allowed value?
   - Port names valid length?
   - Weight is positive number?
   - Flight/voyage numbers valid format?
   ↓
   If validation fails → Return 400/500 with clear error message
   ↓
7. Database transaction begins
   ↓
8. Server assigns version number
   ↓
9. Insert audit history entry
   ↓
10. Commit transaction
```

## Examples of Validation in Action

### Example 1: Invalid Container Number

**Request**:
```json
{
  "event_type": "updated",
  "actor_id": "user-123",
  "actor_name": "John Doe",
  "reason": "Updated container info",
  "snapshot_data": {
    "id": "shipment-123",
    "title": "Ocean Freight",
    "container_number": "ABC123"  // Invalid: too short
  }
}
```

**Response** (400 Bad Request):
```json
{
  "detail": "Validation Error: Invalid container number format. Must be 4 uppercase letters followed by 7 digits (e.g., MSCU1234567)"
}
```

### Example 2: Invalid Status

**Request**:
```json
{
  "snapshot_data": {
    "id": "shipment-123",
    "title": "Ocean Freight",
    "status": "unknown_status"  // Invalid
  }
}
```

**Response** (400 Bad Request):
```json
{
  "detail": "Validation Error: Invalid status 'unknown_status'. Must be one of: archived, cancelled, completed, in_progress, new, pending"
}
```

### Example 3: Invalid Weight

**Request**:
```json
{
  "snapshot_data": {
    "id": "shipment-123",
    "title": "Ocean Freight",
    "gross_weight_kgs": "-500"  // Invalid: negative
  }
}
```

**Response** (400 Bad Request):
```json
{
  "detail": "Validation Error: Weight must be a positive number"
}
```

### Example 4: Invalid Flight Number

**Request**:
```json
{
  "snapshot_data": {
    "id": "shipment-123",
    "title": "Air Freight",
    "flight_number": "12345"  // Invalid: no airline code
  }
}
```

**Response** (400 Bad Request):
```json
{
  "detail": "Validation Error: Flight number must be 2-3 letters followed by 1-4 digits (e.g., AA123)"
}
```

### Example 5: Port Name Too Short

**Request**:
```json
{
  "snapshot_data": {
    "id": "shipment-123",
    "title": "Ocean Freight",
    "port_of_loading": "X"  // Invalid: too short
  }
}
```

**Response** (400 Bad Request):
```json
{
  "detail": "Validation Error: Port of Loading must be at least 2 characters"
}
```

### Example 6: Multiple Errors Combined

**Request**:
```json
{
  "snapshot_data": {
    "id": "shipment-123",
    "title": "Ocean Freight",
    "status": "bad_status",
    "container_number": "ABC",
    "gross_weight_kgs": "-100"
  }
}
```

**Response** (400 Bad Request):
```json
{
  "detail": "Validation Error: Invalid status 'bad_status'. Must be one of: archived, cancelled, completed, in_progress, new, pending; Validation Error: Invalid container number format. Must be 4 uppercase letters followed by 7 digits (e.g., MSCU1234567); Validation Error: Weight must be a positive number"
}
```

## Fields That Are Validated

| Field | Validation Rules | Example Valid | Example Invalid |
|-------|------------------|---------------|-----------------|
| `status` | Must be: new, pending, in_progress, completed, cancelled, archived | `"pending"` | `"unknown"` |
| `transportMode` | Must be: ocean, air, land, rail | `"ocean"` | `"truck"` |
| `container_number` | 4 letters + 7 digits (ISO 6346) | `"MSCU1234567"` | `"ABC123"` |
| `house_bol_number` | 4-20 alphanumeric chars | `"ZMLU34110002"` | `"AB"` |
| `master_bol_number` | 4-20 alphanumeric chars | `"COSU534343282"` | `"X"` |
| `port_of_loading` | 2-100 chars, allows international | `"Shanghai, China"` | `"X"` |
| `port_of_discharge` | 2-100 chars, allows international | `"Long Beach, CA"` | `""` |
| `gross_weight_kgs` | Positive number | `"1000"` or `"1000 KGS"` | `"-50"` or `"abc"` |
| `vessel_name` | 2-100 chars, alphanumeric | `"COSCO BELGIUM"` | `"X"` |
| `voyage_number` | 2-20 chars, alphanumeric | `"095E"` | `"X"` |
| `flight_number` | 2-3 letters + 1-4 digits | `"AA123"` | `"12345"` |
| `consignee_name` | 2-200 chars, business name chars | `"KABOFER TRADING INC"` | `"X"` |
| `shipper_name` | 2-200 chars, business name chars | `"ACME CORP"` | `""` |

## Testing Validation

### Test Invalid Container Number:
```bash
curl -X POST http://localhost:8000/api/shipments/test-id/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "updated",
    "actor_id": "user-123",
    "actor_name": "Test User",
    "reason": "Testing validation",
    "snapshot_data": {
      "id": "test-id",
      "title": "Test Shipment",
      "container_number": "INVALID"
    }
  }'

# Expected: 400/500 with clear error about container format
```

### Test Invalid Status:
```bash
curl -X POST http://localhost:8000/api/shipments/test-id/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "updated",
    "actor_id": "user-123",
    "actor_name": "Test User",
    "reason": "Testing validation",
    "snapshot_data": {
      "id": "test-id",
      "title": "Test Shipment",
      "status": "bad_status"
    }
  }'

# Expected: Error about invalid status
```

### Test Invalid Weight:
```bash
curl -X POST http://localhost:8000/api/shipments/test-id/audit \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "updated",
    "actor_id": "user-123",
    "actor_name": "Test User",
    "reason": "Testing validation",
    "snapshot_data": {
      "id": "test-id",
      "title": "Test Shipment",
      "gross_weight_kgs": "-500"
    }
  }'

# Expected: Error about weight must be positive
```

## Configuring Validation

### Strict vs Non-Strict Mode

The validator supports two modes:

**Strict Mode** (default in code):
```python
validate_shipment_data(snapshot_data, strict=False)
```
- Collects ALL validation errors
- Returns all errors in one message
- Better for user experience (see all issues at once)

**Non-Strict Mode**:
```python
validate_shipment_data(snapshot_data, strict=True)
```
- Returns FIRST validation error only
- Faster fail
- User fixes one error at a time

### Disabling Specific Validations

To skip validation for a specific field, modify [app/services/validators.py](app/services/validators.py):

```python
# Comment out the validation you want to disable:

# if 'container_number' in snapshot_data:
#     error = cls.validate_container_number(snapshot_data['container_number'])
#     if error:
#         errors.append(error)
```

### Adding Custom Validations

To add validation for a new field:

1. Add validation method to `ShipmentValidator` class:
```python
@staticmethod
def validate_custom_field(value: Any) -> Optional[str]:
    """Validate your custom field"""
    if not value:
        return None  # Optional field

    # Your validation logic
    if some_condition:
        return "Validation Error: Your error message"

    return None
```

2. Call it in `validate_snapshot_data()`:
```python
if 'your_field' in snapshot_data:
    error = cls.validate_custom_field(snapshot_data['your_field'])
    if error:
        errors.append(error)
```

## Benefits

### Data Quality
- ✅ No invalid container numbers in database
- ✅ No negative weights
- ✅ No invalid status values
- ✅ No malformed BOL numbers
- ✅ Consistent data formats

### User Experience
- ✅ Clear, specific error messages
- ✅ Know exactly what's wrong and how to fix it
- ✅ Immediate feedback (before database call)
- ✅ All errors shown at once (not one at a time)

### Developer Experience
- ✅ Reusable validator class
- ✅ Easy to add new validations
- ✅ Easy to test validations
- ✅ Centralized validation logic

### System Reliability
- ✅ Prevents corrupt data from entering system
- ✅ Maintains data integrity
- ✅ Easier to query and report on valid data
- ✅ Reduces downstream errors

## Files Modified/Created

### New Files:
- [app/services/validators.py](app/services/validators.py) - Complete validator module (370 lines)

### Modified Files:
- [app/services/audit_service.py](app/services/audit_service.py) - Added validation call (lines 9, 95-103)

### No Changes Required:
- [app/api/routes.py](app/api/routes.py) - Already uses audit_service, benefits automatically
- Frontend code - Gets clear error messages automatically
- Database - Already has event-level validation

## Summary

**Where validation was added**: [app/services/validators.py](app/services/validators.py) (new file)

**Where it's called**: [app/services/audit_service.py](app/services/audit_service.py) line 100

**What it validates**: 12 different field types with specific business rules

**When it runs**: Every time an audit event is created, before the database transaction

**Result**: Clear, actionable error messages for invalid business data
