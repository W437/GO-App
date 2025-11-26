 Context

  We've made security fixes and improvements to the user zone and address management endpoints.
   There is a breaking change that requires frontend updates.

  ---
  🔴 BREAKING CHANGE: Update Zone Endpoint

  Old Implementation:
  // ❌ OLD - No longer works
  GET /api/v1/customer/update-zone
  Headers: {
    "Authorization": "Bearer {token}",
    "zoneId": "[1]"  // JSON array as string
  }

  New Implementation:
  // ✅ NEW - Must use PUT method
  PUT /api/v1/customer/update-zone
  Headers: {
    "Authorization": "Bearer {token}",
    "zoneId": "[1]"  // JSON array as string, first element is used
  }

  // Success Response (200):
  { "message": "Zone updated", "zone_id": 1 }

  // Error Responses:
  // 403 - Missing or invalid zoneId header
  // 404 - Zone doesn't exist or is inactive

  Action Required: Update all API calls from GET to PUT for the update-zone endpoint.

  ---
  Zone Endpoints Reference

  | Endpoint                     | Method | Auth | Purpose                                    |
  |------------------------------|--------|------|--------------------------------------------|
  | /api/v1/zone/list            | GET    | No   | Get all active zones (for zone picker)     |
  | /api/v1/zone/check           | GET    | No   | Check if lat/lng is within a specific zone |
  | /api/v1/config/get-zone-id   | GET    | No   | Get zone(s) containing coordinates         |
  | /api/v1/customer/update-zone | PUT    | Yes  | Update user's current browsing zone        |

  Get Zone by Coordinates

  GET /api/v1/config/get-zone-id?lat=32.9234&lng=35.0821

  // Response (200):
  {
    "zone_id": "[1]",  // JSON string of zone IDs
    "zone_data": [
      {
        "id": 1,
        "status": 1,
        "minimum_shipping_charge": 10,
        "per_km_shipping_charge": 2,
        "maximum_shipping_charge": 50
      }
    ]
  }

  ---
  Address Endpoints Reference

  | Endpoint                             | Method | Auth | Purpose                     |
  |--------------------------------------|--------|------|-----------------------------|
  | /api/v1/customer/address/list        | GET    | Yes  | List user's saved addresses |
  | /api/v1/customer/address/add         | POST   | Yes  | Add new delivery address    |
  | /api/v1/customer/address/update/{id} | PUT    | Yes  | Update existing address     |
  | /api/v1/customer/address/delete      | DELETE | Yes  | Delete an address           |

  List Addresses

  GET /api/v1/customer/address/list?limit=10&offset=1
  Headers: { "Authorization": "Bearer {token}" }

  // Response (200):
  {
    "total_size": 3,
    "limit": 10,
    "offset": 1,
    "addresses": [
      {
        "id": 1,
        "address_type": "home",
        "address": "123 Main St",
        "contact_person_name": "John",
        "contact_person_number": "0501234567",
        "latitude": "32.9234",
        "longitude": "35.0821",
        "zone_id": 1,
        "floor": "2",
        "road": "Main St",
        "house": "123"
      }
    ]
  }

  Add Address

  POST /api/v1/customer/address/add
  Headers: { "Authorization": "Bearer {token}" }
  Body: {
    "contact_person_name": "John Doe",       // required
    "contact_person_number": "0501234567",   // required
    "address_type": "home",                  // required: "home", "office", "other"
    "address": "123 Main Street",            // required
    "latitude": "32.9234",                   // required
    "longitude": "35.0821",                  // required
    "floor": "2",                            // optional
    "road": "Main St",                       // optional
    "house": "123"                           // optional
  }

  // Success (200):
  { "message": "New address added", "zone_ids": [1] }

  // Error (403) - Outside service area:
  { "errors": [{ "code": "coordinates", "message": "Service not available in this area" }] }

  Update Address

  PUT /api/v1/customer/address/update/{address_id}
  Headers: { "Authorization": "Bearer {token}" }
  Body: { /* same as add */ }

  // Success (200):
  { "message": "Address updated", "zone_id": 1 }

  // Error (404) - Address not found or doesn't belong to user:
  { "message": "Not found" }

  Delete Address

  DELETE /api/v1/customer/address/delete
  Headers: { "Authorization": "Bearer {token}" }
  Body: { "address_id": 1 }

  // Success (200):
  { "message": "Address removed" }

  // Error (404):
  { "message": "Not found" }

  ---
  Key Behaviors to Note

  1. Zone Auto-Assignment: When adding/updating an address, the backend automatically
  determines which zone it belongs to based on coordinates. You don't send zone_id — it's
  calculated.
  2. Service Area Validation: If coordinates are outside all active service zones, the address
  cannot be saved. Show user-friendly error: "We don't deliver to this location yet"
  3. Zone vs Address:
    - users.zone_id = User's browsing zone (what restaurants they see)
    - customer_addresses.zone_id = Delivery zone for that specific address
  4. Ownership Enforcement: Users can only view/edit/delete their own addresses. Attempting to
  access another user's address returns 404 (not 403, to prevent enumeration).

  ---
  Error Handling Summary

  | Status | Meaning                                                                 |
  |--------|-------------------------------------------------------------------------|
  | 200    | Success                                                                 |
  | 403    | Validation error (missing fields, invalid format, outside service area) |
  | 404    | Resource not found or not owned by user                                 |

  ---
  Priority Action: Update the zone selection flow to use PUT instead of GET for
  /api/v1/customer/update-zone.
