# Customers & Addresses

## Overview

Customers represent business partners in Xentral. They can be persons (B2C) or companies (B2B). Customers are managed through V2 and V3 endpoints, with addresses and contact persons as sub-resources.

## V2 Customers

### Create

```
POST /api/v2/customers
```

**Person (B2C)**:

```json
{
  "customerType": "person",
  "firstname": "Max",
  "lastname": "Mustermann",
  "email": "max@example.com",
  "project": {
    "id": 1
  }
}
```

**Company (B2B)**:

```json
{
  "customerType": "company",
  "name": "ACME GmbH",
  "email": "info@acme.de",
  "project": {
    "id": 1
  }
}
```

| Field | Required | Description |
|---|---|---|
| `customerType` | Yes | `person` or `company` |
| `firstname` | Yes (person) | First name |
| `lastname` | Yes (person) | Last name |
| `name` | Yes (company) | Company name |
| `email` | No | Email address |
| `project.id` | Yes | Project / sales channel ID |

### List

```
GET /api/v2/customers
```

Supports pagination, filtering, and ordering:

```
GET /api/v2/customers?filter[0][key]=customerType&filter[0][op]=equals&filter[0][value]=company&page[size]=25
```

### View

```
GET /api/v2/customers/{id}
```

## V3 Customers

### Create

```
POST /api/v3/customers
```

V3 provides the newest customer creation endpoint with additional fields and validation.

## Addresses

Addresses are sub-resources of customers. Each address has a type that determines its purpose.

### Address Types

| Type | Description |
|---|---|
| `masterdata` | Primary/master address |
| `billingaddress` | Billing address |
| `deliveryaddress` | Delivery/shipping address |

### List Addresses

```
GET /api/v2/customers/{customerId}/addresses
```

### Create Address

```
POST /api/v2/customers/{customerId}/addresses
```

```json
{
  "type": "deliveryaddress",
  "name": "Max Mustermann",
  "street": "Hauptstrasse 1",
  "zip": "10115",
  "city": "Berlin",
  "country": "DE"
}
```

| Field | Required | Description |
|---|---|---|
| `type` | Yes | `masterdata`, `billingaddress`, or `deliveryaddress` |
| `name` | Yes | Full name or company name |
| `street` | Yes | Street and house number |
| `zip` | Yes | Postal code |
| `city` | Yes | City |
| `country` | Yes | ISO 3166-1 alpha-2 country code |

### Delete Address

```
DELETE /api/v2/customers/{customerId}/addresses/{addressId}
```

## Contact Persons

Contact persons represent individuals associated with a company customer.

### Create Contact Person

```
POST /api/v1/customers/{customerId}/contactPersons
```

```json
{
  "firstname": "Anna",
  "lastname": "Schmidt",
  "email": "anna.schmidt@acme.de",
  "phone": "+49 30 12345678",
  "position": "Purchasing Manager"
}
```

### List Contact Persons

```
GET /api/v1/customers/{customerId}/contactPersons
```

### Delete Contact Person

```
DELETE /api/v1/customers/{customerId}/contactPersons/{contactPersonId}
```

## Common Patterns

### Create Customer with Address

```typescript
// 1. Create the customer
const { data: customer } = await xentral('v2', '/customers', {
  method: 'POST',
  body: {
    customerType: 'company',
    name: 'ACME GmbH',
    email: 'info@acme.de',
    project: { id: 1 },
  },
})

// 2. Add billing address
await xentral('v2', `/customers/${customer.id}/addresses`, {
  method: 'POST',
  body: {
    type: 'billingaddress',
    name: 'ACME GmbH',
    street: 'Hauptstrasse 1',
    zip: '10115',
    city: 'Berlin',
    country: 'DE',
  },
})

// 3. Add delivery address
await xentral('v2', `/customers/${customer.id}/addresses`, {
  method: 'POST',
  body: {
    type: 'deliveryaddress',
    name: 'ACME GmbH - Warehouse',
    street: 'Industrieweg 5',
    zip: '80331',
    city: 'Munich',
    country: 'DE',
  },
})
```

### Find or Create Customer

```typescript
// Search for existing customer by email
const { data: existing } = await xentral('v2',
  '/customers?filter[0][key]=email&filter[0][op]=equals&filter[0][value]=info@acme.de'
)

if (existing.length > 0) {
  return existing[0]
}

// Create new customer if not found
const { data: customer } = await xentral('v2', '/customers', {
  method: 'POST',
  body: { customerType: 'company', name: 'ACME GmbH', project: { id: 1 } },
})

return customer
```
