# Portfolio Builder API Documentation

This document outlines all API endpoints required for the Portfolio Builder feature, including saving portfolios, managing drafts, and archiving.

---

## Base URL
```
/api/portfolios
```

---

## 1. Save Portfolio (POST)
**Creates a new active portfolio**

### Endpoint
```
POST /api/portfolios
```

### Request Body
```json
{
  "portfolio_name": "AI Acceleration Basket",
  "client_name": "John Doe",
  "client_age": 35,
  "risk_profile": "Moderate",
  "strategy_type": "Growth",
  "benchmark": "NIFTY 50",
  "objective": "Capital appreciation through tech disruption",
  "initial_capital": 100000.0,
  "investment_horizon": "5 Years",
  "expected_rate_of_return": 12.5,
  "commentary": "Supporting commentary and rationale...",
  "holdings": [
    {
      "ticker": "AAPL",
      "company": "Apple Inc",
      "exchange": "NASDAQ",
      "sector": "Technology",
      "current_price": 160.50,
      "target_price": 190.00,
      "quantity": 250,
      "allocation_percent": 40.0,
      "allocation_amount": 40125.0,
      "market_cap": 2500000000000.0,
      "pe_ratio": 28.5,
      "notes": "Strong fundamentals"
    }
  ],
  "status": "active"
}
```

### Required Fields
- `portfolio_name` (string): Name of the portfolio
- `client_name` (string): Name or ID of the client
- `initial_capital` (number): Total investment amount
- `holdings` (array): At least one holding must be provided
  - `ticker` (string, required)
  - `quantity` (integer, required)
  - `current_price` (number, required)
  - `target_price` (number, required)
  - `allocation_percent` (number, calculated)
  - `allocation_amount` (number, calculated)

### Optional Fields
- `client_age` (integer)
- `risk_profile` (string): One of: "Conservative", "Moderate", "Aggressive", "Tactical", "Income", "Balanced"
- `strategy_type` (string): One of: "Growth", "Value", "Dividend", "Thematic", "Balanced"
- `benchmark` (string): e.g., "NIFTY 50", "Bank Nifty", "S&P 500", "Custom"
- `objective` (string)
- `investment_horizon` (string): One of: "6 Months", "1 Year", "3 Years", "5 Years", "7 Years", "10 Years"
- `expected_rate_of_return` (number): Between 8.0 and 30.0 (percentage)
- `commentary` (string)
- For each holding:
  - `company` (string)
  - `exchange` (string)
  - `sector` (string)
  - `market_cap` (number)
  - `pe_ratio` (number)
  - `notes` (string)

### Response (Success - 200)
```json
{
  "status": "success",
  "message": "Portfolio saved successfully",
  "data": {
    "id": "portfolio_123",
    "portfolio_name": "AI Acceleration Basket",
    "client_name": "John Doe",
    "client_age": 35,
    "risk_profile": "Moderate",
    "strategy_type": "Growth",
    "benchmark": "NIFTY 50",
    "objective": "Capital appreciation through tech disruption",
    "initial_capital": 100000.0,
    "investment_horizon": "5 Years",
    "expected_rate_of_return": 12.5,
    "commentary": "Supporting commentary and rationale...",
    "allocated_amount": 40125.0,
    "allocation_percent": 40.125,
    "estimated_returns": 73450.25,
    "holdings_count": 1,
    "holdings": [
      {
        "id": "holding_456",
        "ticker": "AAPL",
        "company": "Apple Inc",
        "exchange": "NASDAQ",
        "sector": "Technology",
        "current_price": 160.50,
        "target_price": 190.00,
        "quantity": 250,
        "allocation_percent": 40.125,
        "allocation_amount": 40125.0,
        "market_cap": 2500000000000.0,
        "pe_ratio": 28.5,
        "notes": "Strong fundamentals"
      }
    ],
    "status": "active",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

### Response (Error - 400/422)
```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": {
    "portfolio_name": ["Portfolio name is required"],
    "initial_capital": ["Initial capital must be greater than 0"],
    "holdings": ["At least one holding is required"]
  }
}
```

### Calculated Fields (Backend should compute)
- `allocated_amount`: Sum of all `allocation_amount` from holdings
- `allocation_percent`: (allocated_amount / initial_capital) * 100
- `estimated_returns`: Calculated using compound interest formula
  - Formula: `initial_capital * (1 + expected_rate_of_return/100)^years - initial_capital`
  - Years converted from investment_horizon string
- `holdings_count`: Count of holdings array

---

## 2. Save Draft (POST)
**Creates a new draft portfolio (incomplete portfolio)**

### Endpoint
```
POST /api/portfolios/drafts
```

### Request Body
Same structure as Save Portfolio, but with relaxed validation:
- `portfolio_name` is required (minimum)
- `holdings` can be empty or incomplete
- All other fields are optional

```json
{
  "portfolio_name": "AI Acceleration Basket (Draft)",
  "client_name": "John Doe",
  "initial_capital": 100000.0,
  "holdings": []
}
```

### Response (Success - 200)
```json
{
  "status": "success",
  "message": "Draft saved successfully",
  "data": {
    "id": "draft_789",
    "portfolio_name": "AI Acceleration Basket (Draft)",
    "status": "draft",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

---

## 3. Update Portfolio/Draft (PUT)
**Updates an existing portfolio or draft**

### Endpoint
```
PUT /api/portfolios/{portfolio_id}
```

### Request Body
Same structure as Save Portfolio. Only provided fields will be updated.

### Response (Success - 200)
Same structure as Save Portfolio response.

### Response (Error - 404)
```json
{
  "status": "error",
  "message": "Portfolio not found"
}
```

---

## 4. Get Active Portfolios (GET)
**Retrieves all active portfolios**

### Endpoint
```
GET /api/portfolios/active
```

### Query Parameters
- `page` (integer, optional): Page number (default: 1)
- `limit` (integer, optional): Items per page (default: 20, max: 100)
- `sort_by` (string, optional): Sort field - "created_at", "updated_at", "portfolio_name", "initial_capital" (default: "updated_at")
- `sort_order` (string, optional): "asc" or "desc" (default: "desc")
- `search` (string, optional): Search by portfolio name or client name

### Response (Success - 200)
```json
{
  "status": "success",
  "data": {
    "portfolios": [
      {
        "id": "portfolio_123",
        "portfolio_name": "AI Acceleration Basket",
        "client_name": "John Doe",
        "initial_capital": 100000.0,
        "allocated_amount": 40125.0,
        "allocation_percent": 40.125,
        "holdings_count": 1,
        "estimated_returns": 73450.25,
        "investment_horizon": "5 Years",
        "expected_rate_of_return": 12.5,
        "strategy_type": "Growth",
        "risk_profile": "Moderate",
        "status": "active",
        "last_updated": "2024-01-15T10:00:00Z",
        "created_at": "2024-01-15T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 98,
      "items_per_page": 20
    }
  }
}
```

### Notes for Card View
The response should include all fields needed for the card display:
- Portfolio name
- Client name
- Total capital (`initial_capital`)
- Number of holdings (`holdings_count`)
- Allocation progress (`allocation_percent`)
- Last updated date (`last_updated`)
- Status badge (`status`)

Optional fields that could be useful:
- `estimated_returns` (for preview)
- `strategy_type` (for categorization)
- `risk_profile` (for filtering)

---

## 5. Get Draft Portfolios (GET)
**Retrieves all draft portfolios**

### Endpoint
```
GET /api/portfolios/drafts
```

### Query Parameters
Same as Get Active Portfolios.

### Response (Success - 200)
Same structure as Get Active Portfolios, but with `status: "draft"`.

---

## 6. Get Archived Portfolios (GET)
**Retrieves all archived portfolios**

### Endpoint
```
GET /api/portfolios/archived
```

### Query Parameters
Same as Get Active Portfolios.

### Response (Success - 200)
Same structure as Get Active Portfolios, but with `status: "archived"`.

---

## 7. Get Portfolio by ID (GET)
**Retrieves full details of a specific portfolio (for detail view/modal)**

### Endpoint
```
GET /api/portfolios/{portfolio_id}
```

### Response (Success - 200)
```json
{
  "status": "success",
  "data": {
    "id": "portfolio_123",
    "portfolio_name": "AI Acceleration Basket",
    "client_name": "John Doe",
    "client_age": 35,
    "risk_profile": "Moderate",
    "strategy_type": "Growth",
    "benchmark": "NIFTY 50",
    "objective": "Capital appreciation through tech disruption",
    "initial_capital": 100000.0,
    "investment_horizon": "5 Years",
    "expected_rate_of_return": 12.5,
    "commentary": "Supporting commentary and rationale...",
    "allocated_amount": 40125.0,
    "allocation_percent": 40.125,
    "estimated_returns": 73450.25,
    "holdings_count": 1,
    "holdings": [
      {
        "id": "holding_456",
        "ticker": "AAPL",
        "company": "Apple Inc",
        "exchange": "NASDAQ",
        "sector": "Technology",
        "current_price": 160.50,
        "target_price": 190.00,
        "quantity": 250,
        "allocation_percent": 40.125,
        "allocation_amount": 40125.0,
        "market_cap": 2500000000000.0,
        "pe_ratio": 28.5,
        "notes": "Strong fundamentals"
      }
    ],
    "status": "active",
    "created_at": "2024-01-15T10:00:00Z",
    "updated_at": "2024-01-15T10:00:00Z"
  }
}
```

### Response (Error - 404)
```json
{
  "status": "error",
  "message": "Portfolio not found"
}
```

---

## 8. Archive Portfolio (PATCH)
**Moves a portfolio to archived status**

### Endpoint
```
PATCH /api/portfolios/{portfolio_id}/archive
```

### Request Body
Optional - can include archive reason:
```json
{
  "archive_reason": "Portfolio completed"
}
```

### Response (Success - 200)
```json
{
  "status": "success",
  "message": "Portfolio archived successfully",
  "data": {
    "id": "portfolio_123",
    "status": "archived",
    "archived_at": "2024-01-20T10:00:00Z"
  }
}
```

### Response (Error - 404)
```json
{
  "status": "error",
  "message": "Portfolio not found"
}
```

---

## 9. Unarchive Portfolio (PATCH)
**Moves an archived portfolio back to active**

### Endpoint
```
PATCH /api/portfolios/{portfolio_id}/unarchive
```

### Response (Success - 200)
```json
{
  "status": "success",
  "message": "Portfolio unarchived successfully",
  "data": {
    "id": "portfolio_123",
    "status": "active"
  }
}
```

---

## 10. Delete Portfolio (DELETE)
**Permanently deletes a portfolio (drafts only, or with confirmation)**

### Endpoint
```
DELETE /api/portfolios/{portfolio_id}
```

### Response (Success - 200)
```json
{
  "status": "success",
  "message": "Portfolio deleted successfully"
}
```

### Response (Error - 403)
If trying to delete active/archived portfolio without proper permissions:
```json
{
  "status": "error",
  "message": "Cannot delete active portfolio. Archive it first."
}
```

---

## Data Models

### Portfolio Status
- `"active"`: Completed and active portfolio
- `"draft"`: Incomplete/saved draft
- `"archived"`: Archived portfolio

### Investment Horizon Mapping
Backend should convert string to years for calculations:
- `"6 Months"` → 0.5 years
- `"1 Year"` → 1.0 years
- `"3 Years"` → 3.0 years
- `"5 Years"` → 5.0 years
- `"7 Years"` → 7.0 years
- `"10 Years"` → 10.0 years

### Estimated Returns Calculation
```javascript
function calculateEstimatedReturns(initialCapital, rateOfReturn, investmentHorizon) {
  const years = getYearsFromHorizon(investmentHorizon);
  const rate = rateOfReturn / 100;
  const totalValue = initialCapital * Math.pow(1 + rate, years);
  return totalValue - initialCapital; // Returns only (not total value)
}
```

### Allocation Calculation
For each holding:
- `allocation_amount` = `current_price * quantity`
- `allocation_percent` = (`allocation_amount` / `initial_capital`) * 100

Total portfolio:
- `allocated_amount` = Sum of all holdings' `allocation_amount`
- `allocation_percent` = (`allocated_amount` / `initial_capital`) * 100

---

## Error Response Format

All error responses follow this structure:
```json
{
  "status": "error",
  "message": "Human-readable error message",
  "errors": {
    "field_name": ["Specific error for this field"]
  }
}
```

---

## Authentication

All endpoints require authentication. Include authentication token in headers:
```
Authorization: Bearer {token}
```

---

## Summary

### Endpoints Overview

1. **POST** `/api/portfolios` - Save active portfolio
2. **POST** `/api/portfolios/drafts` - Save draft portfolio
3. **PUT** `/api/portfolios/{id}` - Update portfolio/draft
4. **GET** `/api/portfolios/active` - List active portfolios
5. **GET** `/api/portfolios/drafts` - List draft portfolios
6. **GET** `/api/portfolios/archived` - List archived portfolios
7. **GET** `/api/portfolios/{id}` - Get portfolio details
8. **PATCH** `/api/portfolios/{id}/archive` - Archive portfolio
9. **PATCH** `/api/portfolios/{id}/unarchive` - Unarchive portfolio
10. **DELETE** `/api/portfolios/{id}` - Delete portfolio

### Key Data Fields

**Portfolio Level:**
- Portfolio identification: `portfolio_name`, `client_name`, `client_age`
- Strategy: `strategy_type`, `benchmark`, `risk_profile`, `objective`
- Financial: `initial_capital`, `investment_horizon`, `expected_rate_of_return`
- Calculated: `allocated_amount`, `allocation_percent`, `estimated_returns`, `holdings_count`
- Metadata: `status`, `created_at`, `updated_at`, `commentary`

**Holding Level:**
- Stock info: `ticker`, `company`, `exchange`, `sector`
- Pricing: `current_price`, `target_price`
- Allocation: `quantity`, `allocation_percent`, `allocation_amount`
- Metrics: `market_cap`, `pe_ratio`
- Notes: `notes`


