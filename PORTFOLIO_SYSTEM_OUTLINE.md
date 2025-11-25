# Portfolio Management System - Complete Outline
## Merged Concept: Portfolio Ideas + Model Portfolio Builder

---

## **Screen 1: Portfolio Ideas Dashboard** (Main Entry Point)

### Layout Structure:
- **Header**: "Portfolio Ideas" title + "New Portfolio" button
- **Expandable Form Section**: Opens when "New Portfolio" clicked
- **Portfolio Library List**: Shows all created portfolios (model portfolios + client-specific)

---

## **Screen 2: New Portfolio Builder** (Expandable Form)

### **Section A: Client & Goal Context** (Top Card)

#### Client Information:
- **Client Name/ID**: Text input
- **Age**: Numeric input (optional)
- **Risk Profile**: Segmented pills (Conservative / Moderate / Aggressive / Tactical)
- **Investment Horizon**: Slider (1-10 years) + dropdown with snap points (6M, 1Y, 3Y, 5Y, 7Y, 10Y)
- **Initial Capital**: 
  - Text input with ₹ symbol (e.g., ₹1,00,000)
  - Quick chips: ₹50k, ₹1L, ₹2L, ₹5L, ₹10L
  - Currency toggle: INR / USD

#### Goal & Constraints:
- **Target Goal**: Text input (e.g., ₹2,00,000 in 2 years) - optional
- **Max Drawdown Tolerance**: Slider 0-50% (optional)
- **Sector Restrictions**: Multi-select dropdown (e.g., "No Sin Stocks", "Shariah-compliant only")
- **Stock Restrictions**: Textarea for ticker exclusions (comma-separated)

#### Strategy Selection:
- **Strategy Type**: Dropdown (Growth / Value / Dividend / Thematic / Balanced)
- **Benchmark**: Dropdown (NIFTY 50, Bank Nifty, S&P 500, Custom)
- **Portfolio Name**: Text input (e.g., "AI Acceleration Basket")
- **Objective**: Text input (single line)
- **Strategy Theme**: Text input (e.g., "Tech Disruption", "EV Transition")

---

### **Section B: Model Portfolio Definition** (Main Table)

#### Table Structure (Editable Rows):
Columns (left to right):

1. **Ticker Search**: 
   - Typesense-powered search (reuse existing component)
   - Auto-fills company name, current price, sector, exchange
   - Shows shimmer while loading

2. **Company Name**: 
   - Auto-filled, editable text
   - Shows logo if available

3. **Exchange**: 
   - Auto-filled (NSE, BSE, NASDAQ, NYSE)
   - Read-only badge

4. **Sector/Industry**: 
   - Auto-filled from Typesense
   - Read-only badge

5. **Action/Recommendation**: 
   - Dropdown: Buy / Hold / Sell / Reduce / Hedge
   - Color-coded pills (green/red/yellow)

6. **Current Price**: 
   - Auto-filled from Typesense
   - Read-only, updates live if enabled

7. **Target Price**: 
   - Numeric input (required)
   - Shows validation if missing

8. **Upside %**: 
   - Auto-calculated: ((target - current) / current) * 100
   - Color-coded (green if positive, red if negative)
   - Read-only

9. **Allocation %**: 
   - Numeric input (0-100)
   - Must sum to 100% across all legs
   - Shows progress indicator

10. **Allocation Amount (₹)**: 
    - Auto-calculated: (allocation % * total capital) / 100
    - Editable (typing here updates %)
    - Shows running total at top

11. **Quantity (Shares)**: 
    - Auto-calculated: allocation amount / current price
    - Read-only, rounded to nearest whole share

12. **Research Source**: 
    - Dropdown: ICICI / HDFC / Axis / Morgan Stanley / Custom
    - Links to research panel

13. **Research PDF Link**: 
    - Text input (validates http/https)
    - Shows PDF icon pill when valid

14. **Confidence (0-5)**: 
    - Mini slider or pill selector
    - Optional per leg

15. **Notes**: 
    - Short text input (single line)
    - Tooltip on hover for full text

16. **Actions**: 
    - Remove row button (pill with "-" icon)

#### Table Features:
- **Add Row Button**: Pill button "+ Add Stock" (default 3 blank rows)
- **Auto-Distribute Button**: 
  - Options: Equal Weight / Risk-Weighted / Market Cap Weighted
  - Distributes remaining allocation
- **Validate Button**: 
  - Checks: Total allocation = 100%, all required fields filled
  - Shows inline errors per row
- **Allocation Progress Bar**: 
  - Sticky header showing "Allocated: ₹80,000 / ₹1,00,000 (80%)"
  - Turns amber/red if not 100%

---

### **Section C: Portfolio Metadata** (Right Sidebar or Below Table)

#### Supporting Information:
- **Supporting Commentary**: 
  - Markdown-style textarea (3-4 rows)
  - For rationale, key bullets, market outlook

- **Reference Documents**: 
  - Multi-link input (comma/newline separated)
  - Auto-validates http/https
  - Renders as pill chips with PDF icons

- **Risk Bucket**: 
  - Dropdown: Low / Medium / High / Very High
  - Auto-suggested based on holdings

- **Target Horizon**: 
  - Pre-filled from client context
  - Editable dropdown

- **Overall Confidence**: 
  - Slider 0-5
  - Auto-calculated as average of leg confidences (if provided)

#### Sharing & Publishing:
- **Publish to Insights Feed**: Toggle switch
- **Share with Desk Leads**: Toggle switch
- **Notify Compliance**: Toggle switch (optional)

---

### **Section D: Portfolio Summary Footer** (Sticky Bottom Bar)

#### Key Metrics:
- **Total Capital**: ₹1,00,000 (from client context)
- **Allocated**: ₹1,00,000 (sum of all legs)
- **Remaining**: ₹0 (capital - allocated)
- **Long Weight**: 80% (sum of Buy actions)
- **Short Weight**: 20% (sum of Sell/Reduce actions)
- **Average Upside**: +18.5% (weighted average)
- **Overall Confidence**: High (3.8/5.0)
- **Number of Holdings**: 5
- **Sector Diversification**: Tech 40%, Finance 30%, Energy 30%

#### Validation Status:
- Green checkmark if valid, red X if errors
- Click to see detailed validation report

---

### **Section E: Action Buttons**

- **Save Draft**: 
  - Secondary pill button
  - Allows incomplete portfolios (only requires name + at least one leg)

- **Save Portfolio Idea**: 
  - Primary pill button
  - Enabled only when validation passes
  - Shows loading state during submission

- **Preview Portfolio**: 
  - Tertiary button
  - Opens modal with formatted summary

---

## **Screen 3: Portfolio Library / Overview** (Main List View)

### Layout:
- **Filter Bar**: 
  - Search portfolios by name/client
  - Filter by: Strategy, Risk Level, Benchmark, Date Range
  - Sort by: Date Created, Performance, Capital Size

### Portfolio Cards/Table:
Each portfolio shows:

#### Header Row:
- **Portfolio Name** (click to expand)
- **Client Name/ID**
- **Strategy Type** (badge)
- **Risk Level** (badge)
- **Capital**: ₹1,00,000
- **Created Date**: DD/MM/YYYY
- **Status**: Draft / Active / Archived

#### Expandable Details:
- **Holdings Count**: 5 stocks
- **Current Value**: ₹1,18,500
- **Unrealized P&L**: +₹18,500 (+18.5%)
- **vs Benchmark**: +2.3% (NIFTY 50)
- **Last Updated**: DD/MM/YYYY HH:MM

#### Actions:
- **View Details**: Opens portfolio detail screen
- **Clone**: Creates copy for new client
- **Edit**: Opens builder in edit mode
- **Export**: CSV / PDF / Excel
- **Archive**: Move to archived list

---

## **Screen 4: Portfolio Detail View** (When clicking a portfolio)

### **Tab 1: Holdings Table**

Columns:
- Ticker
- Company Name
- Quantity
- Average Buy Price
- Current Price
- Market Value (₹)
- P&L (₹ and %)
- Weight % (Current)
- Target Weight % (from model)
- Deviation (Current - Target %)
- Recommendation (from latest report)
- Target Price (current)
- Upside % (from current price)
- Sector
- Risk Flag (High / Medium / Low)

Features:
- **Rebalance Suggestions**: Highlight rows with deviation > 2-3%
- **One-click Rebalance**: Button to regenerate orders to match target weights
- **Sortable columns**
- **Export to CSV**

---

### **Tab 2: Performance Analytics**

#### Charts:
- **Performance vs Benchmark**: Line chart (portfolio vs NIFTY 50)
- **Date Range Selector**: Since Inception / 1M / 3M / 6M / 1Y / Custom

#### Key Metrics Table:
- **Total Return**: +18.5%
- **Annualized Return**: +22.3%
- **Volatility**: 15.2% (standard deviation)
- **Sharpe Ratio**: 1.45
- **Max Drawdown**: -8.3%
- **Beta**: 1.12 (vs benchmark)

#### Exposure Breakdown:
- **By Sector**: Table with Sector, Weight %, No. of Holdings
- **By Market Cap**: Large / Mid / Small (weight %)
- **By Instrument Type**: Stocks / ETFs / Bonds (if applicable)

---

### **Tab 3: Research Integration Panel**

For selected ticker (or all tickers):

#### Latest Research Reports:
Table columns:
- Date
- Analyst / Institution (ICICI / HDFC / Axis)
- Rating (Buy / Hold / Sell) - color coded
- Target Price
- Report PDF Link (clickable)
- Key Highlights (extracted from PDF or manual entry)

#### Consensus Summary:
- **Consensus Rating**: Strong Buy (4.2/5.0)
- **Consensus Target Price**: ₹1,950
- **No. of Contributing Reports**: 12
- **Last Updated**: DD/MM/YYYY

---

### **Tab 4: Order Execution** (If integrated with broker)

#### Order List:
Columns:
- Ticker
- Side (Buy / Sell)
- Quantity
- Price Type (Market / Limit)
- Est. Execution Price
- Est. Order Value (₹)
- Status (Pending / Executed / Partially Filled)

Features:
- **Generate Orders**: Button to create orders from model + client capital
- **Export Orders**: CSV / PDF to send to broker
- **Execution Status**: Real-time updates if broker API integrated

---

## **Screen 5: Model Library & Versioning**

### Model List Table:
Columns:
- Model Name
- Strategy / Theme
- Risk Level
- Benchmark
- No. of Holdings
- Created Date
- Last Modified
- No. of Clients Using
- 1Y Performance (if tracked)
- Since-Inception Performance

### Actions:
- **Create New Model**: Opens builder
- **Clone Model**: Creates copy
- **Delete / Archive**: Move to archived
- **Compare Models**: Side-by-side comparison (return, volatility, max drawdown, sector weights)

---

## **Screen 6: Client Reporting / Export**

### Report Contents:
1. **Client Info & Goal Summary**
2. **Portfolio Summary**: Capital, return, risk metrics
3. **Holdings Table**: Essential columns
4. **Performance vs Benchmark Chart**
5. **Commentary**: Auto-generated or manual notes

### Export Formats:
- **PDF**: For client presentation
- **CSV / Excel**: For further analysis
- **Email**: Direct send option

---

## **Data Models (Backend Structure)**

### `portfolio_ideas` Collection:
```json
{
  "id": "portfolio_123",
  "name": "AI Acceleration Basket",
  "client_id": "client_456",
  "client_name": "XYZ Corp",
  "strategy_type": "Growth",
  "risk_level": "Aggressive",
  "benchmark": "NIFTY 50",
  "initial_capital": 100000,
  "target_horizon": 5,
  "objective": "Capital appreciation through tech disruption",
  "theme": "AI Adoption",
  "risk_bucket": "High",
  "overall_confidence": 4.2,
  "supporting_commentary": "...",
  "reference_docs": ["url1", "url2"],
  "legs": [
    {
      "ticker": "AAPL",
      "company": "Apple Inc",
      "action": "Buy",
      "allocation_percent": 40,
      "allocation_amount": 40000,
      "quantity": 250,
      "current_price": 160,
      "target_price": 190,
      "upside_percent": 18.75,
      "research_source": "ICICI",
      "research_link": "url",
      "confidence": 4.5,
      "notes": "..."
    }
  ],
  "created_at": "2024-01-15T10:00:00Z",
  "updated_at": "2024-01-15T10:00:00Z",
  "status": "active",
  "published_to_insights": true,
  "shared_with_desk": true
}
```

### `client_portfolios` Collection:
```json
{
  "id": "client_portfolio_789",
  "portfolio_idea_id": "portfolio_123",
  "client_id": "client_456",
  "execution_date": "2024-01-20",
  "holdings": [
    {
      "ticker": "AAPL",
      "quantity": 250,
      "average_buy_price": 160.50,
      "current_price": 165.00,
      "market_value": 41250,
      "p_l": 1125,
      "p_l_percent": 2.8
    }
  ],
  "total_invested": 100000,
  "current_value": 118500,
  "unrealized_pnl": 18500,
  "unrealized_pnl_percent": 18.5
}
```

---

## **Implementation Priority (MVP → Full)**

### **Phase 1: MVP** (Core Functionality)
1. ✅ Client & Goal Context Section
2. ✅ Model Portfolio Definition Table (with allocation validation)
3. ✅ Portfolio Library List View
4. ✅ Basic Portfolio Detail (Holdings table)
5. ✅ Save/Edit/Clone portfolios

### **Phase 2: Enhanced Features**
6. Performance Analytics (charts + metrics)
7. Research Integration Panel
8. Order Execution Simulation
9. Model Versioning

### **Phase 3: Advanced Features**
10. Real-time broker integration
11. AI-generated commentary
12. Advanced risk analytics
13. Client reporting automation

---

## **UI/UX Principles** (Terminal Aesthetic)

- **Compact, dense layout**: No wasted space
- **Muted color palette**: Greens/reds for P&L, blues for primary actions
- **Pill buttons**: Consistent rounded buttons
- **No fancy charts**: Simple line charts, bar charts only
- **Keyboard-first**: Tab order optimized, shortcuts for power users
- **Inline validation**: Red underlines, tooltips for errors
- **Shimmer loading**: Consistent loading states
- **Consistent padding**: Same spacing across all screens

---

This outline merges your original portfolio idea concept with the comprehensive portfolio management system, creating a unified workflow from client setup → portfolio building → tracking → reporting.

