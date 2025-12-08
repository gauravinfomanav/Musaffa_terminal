# App-Wide Customizable Layout (Workspace) Feature - Complete Plan

## 📋 Overview

This document explains how we'll implement a **customizable layout system** that works across the **ENTIRE APPLICATION** - not just the main dashboard, but on **ALL SCREENS** where users can:
- Drag and drop widgets to rearrange them
- Add or remove widgets
- Resize widgets
- Save multiple layouts (workspaces) **per screen**
- Switch between different layouts instantly **on any screen**

**Key Point**: We'll build this WITHOUT modifying any existing widget files. All existing widgets stay exactly the same!

**Scope**: This system will work on:
- ✅ Main Dashboard Screen
- ✅ Ticker Detail Screen
- ✅ Screener Screen
- ✅ Sector Details Screen
- ✅ ETF Details Screen
- ✅ Portfolio Screens
- ✅ Trading Ideas Screen
- ✅ Financials Screens
- ✅ Any future screens



## 🎯 What We're Building

### Current Situation
Right now, the app has a **fixed layout**:
- Top: Market Indices (4 mini widgets)
- Middle: Market Summary Table (left) + Trading Chart (right)
- Bottom: Heatmap tiles

Users **cannot change** this layout. It's the same for everyone.

### After Implementation
Users will be able to:
- ✅ **Rearrange** widgets by dragging them
- ✅ **Add** new widgets from a library
- ✅ **Remove** widgets they don't need
- ✅ **Resize** widgets to preferred sizes (width and height)
  - **Watchlist Sidebar**: Expand from narrow to wide (e.g., 2 columns → 4 columns → 6 columns)
  - **Market Summary Table**: Make wider or narrower as needed
  - **Trading Charts**: Adjust width and height independently
  - **News Feed**: Resize to show more or fewer articles
  - **All widgets**: Full control over dimensions
- ✅ **Save** multiple layouts with names (e.g., "Trading Setup", "Research Mode")
- ✅ **Switch** between saved layouts instantly
- ✅ **Customize ANY screen** in the application, not just the dashboard

---

## 🌐 App-Wide Customization Scope

### Which Screens Can Be Customized?

**ALL SCREENS** in your application can have customizable layouts! Here are examples:

#### 1. **Main Dashboard Screen**
- Currently: Fixed layout (Market Indices → Table + Chart → Heatmaps)
- After: Users customize widget arrangement, sizes, add/remove widgets

#### 2. **Ticker Detail Screen** (Stock Details Page)
- Currently: Fixed sections (Overview tab, Financials tab, etc.)
- After: Users can rearrange sections like:
  - Trading Chart position
  - News Feed location
  - Recommendations widget
  - Financial data tables
  - Research notes panel

#### 3. **Screener Screen**
- Currently: Fixed layout (Filters on left, Results table on right)
- After: Users can customize:
  - Filter panel position/size
  - Results table layout
  - Add quick filters as widgets
  - Custom result views

#### 4. **Sector Details Screen**
- Currently: Fixed sections
- After: Users can rearrange:
  - Sector performance widgets
  - Top stocks table
  - Charts and metrics

#### 5. **ETF Details Screen**
- Currently: Fixed layout
- After: Users can customize:
  - Holdings table
  - Performance charts
  - Allocation widgets

#### 6. **Portfolio Screens**
- Currently: Fixed forms and tables
- After: Users can customize:
  - Portfolio builder layout
  - Performance widgets
  - Position tables

#### 7. **Any Future Screen**
- The system is flexible enough to work on any screen you add later!

---

### How It Works Across Different Screens

#### Concept: Screen-Specific Layouts

Each screen can have **its own set of saved layouts**:

```
Main Dashboard:
  - "Trading Setup" layout
  - "Research Mode" layout
  - "Market Overview" layout

Ticker Detail Screen:
  - "Quick Analysis" layout
  - "Deep Dive" layout
  - "Comparison View" layout

Screener Screen:
  - "Quick Filter" layout
  - "Advanced Analysis" layout
```

**Key Point**: Layouts are saved **per screen type**, not globally. Each screen remembers its own layouts!

---

### Real-World Example Scenarios

#### Scenario 1: Customizing Ticker Detail Screen

**User opens Apple (AAPL) stock page:**
- Default layout shows: Chart on top, News below, Recommendations on side
- User clicks "Edit Layout"
- User drags News widget to the right side
- User resizes Chart to be smaller
- User adds "Peer Comparison" widget
- User saves as "My Stock Analysis Layout"
- Next time user opens any stock, they can use this layout!

#### Scenario 2: Customizing Screener Screen

**User is screening stocks:**
- Default: Filters on left, Results table takes full width
- User prefers: Filters at top (horizontal), Results below
- User customizes layout
- User saves as "Wide Results View"
- Now screening is faster for this user!

#### Scenario 3: Resizing Watchlist Sidebar

**User wants wider watchlist:**
- Default: Watchlist is narrow (2-3 columns wide)
- User clicks "Edit Layout"
- User hovers over watchlist widget
- User drags right edge handle to expand width
- Watchlist grows: 2 columns → 3 → 4 → 5 → 6 columns
- User can now see more ticker information at once
- Other widgets automatically adjust to accommodate
- User saves as "Wide Watchlist Layout"
- Next time, watchlist loads at preferred width!

#### Scenario 4: Different Users, Different Preferences

- **Trader A** customizes dashboard: Charts everywhere, minimal tables, narrow watchlist
- **Analyst B** customizes dashboard: Data tables, detailed metrics, wide watchlist (6 columns)
- **Manager C** customizes dashboard: Summary widgets, high-level overview, medium watchlist
- Each user's layouts are saved separately!

---

## 🏗️ Architecture: The Wrapper Approach

### Simple Concept
Instead of editing every widget file (which would be messy and hard to maintain), we'll create a **wrapper system**.

Think of it like this:
- **Your existing widgets** = The actual content (Market Table, Charts, etc.)
- **Wrapper** = A box that wraps around your widget and adds drag/resize features
- **Controller** = Manages all widgets and their positions

```
┌─────────────────────────────────────┐
│  WRAPPER (adds drag/resize)        │
│  ┌───────────────────────────────┐ │
│  │  YOUR EXISTING WIDGET         │ │ ← No changes needed!
│  │  (MarketSummaryTable, etc.)   │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Why This Approach?
✅ **Write Once, Use Everywhere**: Build the wrapper once, use for all widgets **on all screens**
✅ **No Changes to Existing Code**: All your current widgets stay untouched
✅ **Easy to Maintain**: Fix bugs or add features in one place
✅ **Easy to Extend**: Add new widgets easily without writing drag code each time
✅ **Screen-Agnostic**: Same wrapper system works on **any screen** in the app
✅ **Per-Screen Layouts**: Each screen can have its own saved layouts independently

---

## 📦 What Needs to Be Created

### New Files to Create (Only 5-7 files)

#### 1. **Models** (Data Structure)
- `dashboard_widget.dart` - Stores widget info (position, size, type)
- `dashboard_layout.dart` - Stores complete layout (collection of widgets)
- `grid_config.dart` - Grid system configuration

#### 2. **Wrapper Component**
- `draggable_widget_wrapper.dart` - The wrapper that makes any widget draggable

#### 3. **Controllers** (Business Logic)
- `dashboard_controller.dart` - Manages all widgets and layout operations

#### 4. **Services** (Utilities)
- `widget_factory_service.dart` - Creates widget instances from config
- `layout_persistence_service.dart` - Saves/loads layouts (to backend/local storage)

#### 5. **UI Components**
- `widget_library_panel.dart` - Sidebar showing available widgets
- `workspace_switcher.dart` - Dropdown to switch between saved workspaces

#### 6. **Main Screen Update**
- Update `main_screen.dart` - Use the new system instead of fixed layout

---

## 🔧 Implementation Plan (Step by Step)

### Phase 1: Foundation (Models & Basic Structure)

**Step 1.1**: Create data models
- Define what a "widget" looks like in our system
- Define what a "layout" looks like
- Define grid system (12 or 24 columns)

**What this means**: Create classes that hold widget information like:
```dart
class DashboardWidget {
  String id;                    // Unique identifier
  String type;                  // "MARKET_SUMMARY", "TRADING_VIEW", "WATCHLIST", etc.
  Position position;            // X, Y coordinates in grid
  Size size;                    // Width, height in grid units (columns, rows)
  Map<String, dynamic> config;  // Widget-specific settings
  
  // Size example:
  // Watchlist: width=2 (narrow) or width=6 (wide)
  // Chart: width=6, height=4 (default) or width=10, height=6 (expanded)
  // Table: width=8, height=5 (wide) or width=4, height=3 (compact)
}
```

---

### Phase 2: Widget Registry (Register All Widgets)

**Step 2.1**: Create widget factory
- Create a service that knows how to create any widget
- Register all existing widgets (MarketSummary, TradingView, etc.)

**What this means**: One file where we list all available widgets:
```dart
Widget createWidget(String type) {
  switch(type) {
    case 'MARKET_SUMMARY':
      return MarketSummaryDynamicTable();  // Your existing widget
    case 'TRADING_VIEW':
      return DynamicHeightTradingView();   // Your existing widget
    // ... all other widgets
  }
}
```

**Key Point**: This is the ONLY place where we reference existing widgets. They don't need to change!

---

### Phase 3: Wrapper System (Make Widgets Draggable & Resizable)

**Step 3.1**: Create draggable wrapper
- Build a widget that wraps any other widget
- Add drag handle (header bar)
- Add resize handles (corners/edges)
- Handle positioning logic
- **Handle resize logic** (width and height adjustments)

**What this means**: Create a reusable component that:
- Takes any widget as input (child)
- Adds drag functionality around it
- Adds resize functionality (width and height)
- Shows controls in "edit mode"
- Handles all drag/resize logic
- **Supports expanding watchlist and other widgets to any desired size**

**Visual**:
```
┌─────────────────────────────┐
│ [≡] Widget Name  [⚙️] [×]  │ ← Header (only in edit mode)
├─────────────────────────────┤
│                             │
│     Your Widget Content     │ ← Your existing widget (unchanged)
│                             │
└─────────────────────────────┘
   ↖  ↑  ↗                    ← Corner handles (resize both dimensions)
   ←        →                  ← Edge handles (resize width only)
   ↙  ↓  ↘                    ← Corner handles (resize both dimensions)
```

**Resize Features**:
- **8 corner handles**: Resize both width and height simultaneously
- **4 edge handles**: Resize width (left/right) or height (top/bottom) independently
- **Grid-based resizing**: Snaps to grid units for clean alignment
- **Constraint validation**: Enforces min/max sizes per widget type
- **Live preview**: Widget content updates as user drags
- **Collision detection**: Prevents overlapping with other widgets

---

### Phase 4: Layout Controller (Brain of the System)

**Step 4.1**: Create controller
- Manage all widgets on **any screen**
- Handle drag operations
- Calculate positions
- Save/load layouts **per screen type**

**What this means**: A reusable controller that:
- Works on **any screen** (Main Screen, Ticker Detail, Screener, etc.)
- Keeps track of all widgets and their positions **for that screen**
- Handles when user drags/resizes widgets
- Saves layout to backend with **screen identifier** (e.g., "main_screen", "ticker_detail")
- Loads layout when user switches workspace **for that specific screen**

**Key Point**: 
- Each screen creates its **own controller instance**
- Layouts are saved with screen type: `"main_screen"`, `"ticker_detail"`, `"screener"`, etc.
- Same controller code, different instances per screen!

---

### Phase 5: UI Components (User Interface)

**Step 5.1**: Create widget library panel
- Sidebar showing all available widgets
- User can drag widgets from here to dashboard
- Search/filter widgets

**Step 5.2**: Create workspace switcher
- Dropdown in toolbar
- Shows all saved workspaces
- User can switch between them
- "Save as..." option

---

### Phase 6: Integration (Connect Everything)

**Step 6.1**: Update screens to use customizable layout
- Replace fixed layout code with new system
- Add edit mode toggle button
- Add workspace switcher
- Wire up controller

**What this means**: Instead of hardcoded layout:
```dart
// OLD WAY (fixed) - Main Screen:
Column(
  children: [
    MiniWidgetsRow(),
    Row(
      children: [
        MarketSummaryDynamicTable(),
        DynamicHeightTradingView(),
      ],
    ),
  ],
)

// NEW WAY (customizable) - Main Screen:
CustomizableLayout(
  screenType: 'main_screen',
  widgets: layoutController.buildWidgets(),
  isEditMode: _isEditMode,
)

// OLD WAY (fixed) - Ticker Detail Screen:
Column(
  children: [
    TradingViewWidget(),
    NewsWidget(),
    RecommendationsWidget(),
  ],
)

// NEW WAY (customizable) - Ticker Detail Screen:
CustomizableLayout(
  screenType: 'ticker_detail',
  widgets: layoutController.buildWidgets(),
  isEditMode: _isEditMode,
)
```

**Key Point**: The **same reusable component** (`CustomizableLayout`) works on **every screen**! Just pass the screen type!

---

### Phase 7: Multi-Screen Implementation (Apply to All Screens)

**Step 7.1**: Create screen-specific widget registries
- Each screen can have different available widgets
- Main Screen: Market widgets, Charts, Heatmaps
- Ticker Detail: Chart widgets, News, Recommendations, Financials
- Screener: Filter widgets, Result tables, Analysis widgets

**Step 7.2**: Implement on each screen
- Update `main_screen.dart` - Use customizable layout
- Update `ticker_detail_screen.dart` - Use customizable layout
- Update `screener_screen.dart` - Use customizable layout
- Update other screens as needed

**What this means**: Each screen:
1. Creates its own controller instance
2. Defines which widgets are available for that screen
3. Uses the same `CustomizableLayout` component
4. Saves/loads layouts specific to that screen type

**Example**:
```dart
// In ticker_detail_screen.dart
final layoutController = Get.put(
  LayoutController(screenType: 'ticker_detail'),
);

// In main_screen.dart
final layoutController = Get.put(
  LayoutController(screenType: 'main_screen'),
);

// Same controller, different screen types = different layouts!
```

---

## 📁 File Structure

```
lib/
├── customizable_layout/                 ← NEW FOLDER (works app-wide)
│   ├── models/
│   │   ├── dashboard_widget.dart       ← Widget data model
│   │   ├── dashboard_layout.dart       ← Layout data model
│   │   └── grid_config.dart            ← Grid configuration
│   │
│   ├── controllers/
│   │   └── layout_controller.dart      ← Main controller (works on all screens)
│   │
│   ├── services/
│   │   ├── widget_factory_service.dart ← Creates widgets
│   │   └── layout_persistence_service.dart ← Saves/loads
│   │
│   ├── widgets/
│   │   ├── draggable_widget_wrapper.dart ← The wrapper
│   │   ├── widget_library_panel.dart   ← Widget sidebar
│   │   ├── workspace_switcher.dart     ← Layout switcher
│   │   └── customizable_layout.dart    ← Main layout UI (works on all screens)
│   │
│   └── screens/
│       └── customizable_main_screen.dart ← Optional: New main screen
│
├── Components/                          ← NO CHANGES HERE!
│   ├── market_summary.dart             ← Untouched
│   ├── trading_view_widget.dart        ← Untouched
│   ├── mini_widgets_row.dart           ← Untouched
│   └── ... (all existing widgets)      ← Untouched
│
└── Screens/                             ← Minimal changes here
    ├── main_screen.dart                 ← Use customizable layout
    ├── ticker_detail_screen.dart        ← Use customizable layout
    ├── screener_screen.dart             ← Use customizable layout
    ├── sector_details_screen.dart       ← Use customizable layout
    ├── etf_details_screen.dart          ← Use customizable layout
    └── ... (other screens)              ← Use customizable layout
```

---

## 🔄 How It Works (User Flow)

### Scenario: User Wants to Customize Dashboard

1. **User clicks "Edit Layout" button**
   - App enters edit mode
   - Grid lines appear
   - Widget headers appear (with drag handles)

2. **User drags a widget**
   - Clicks and holds on widget header
   - Drags to new position
   - Grid highlights valid drop zones
   - Releases mouse
   - Widget snaps to new position
   - Other widgets adjust automatically

3. **User adds a widget**
   - Opens widget library panel (sidebar)
   - Sees list of available widgets
   - Drags "News Feed" widget to dashboard
   - Widget appears at drop location
   - Widget starts loading data automatically

4. **User resizes a widget**
   - Hovers over widget corner or edge
   - Resize handle appears (corners for both dimensions, edges for single dimension)
   - Drags to make widget bigger/smaller
   - Widget resizes within min/max limits
   - Adjacent widgets adjust automatically
   - **Watchlist Example**: User drags right edge to expand from 2 columns to 5 columns wide
   - **Chart Example**: User drags bottom-right corner to make chart taller and wider
   - **Table Example**: User drags left edge to make table narrower, giving more space to adjacent widget

5. **User saves workspace**
   - Clicks "Save Workspace"
   - Enters name: "My Trading Setup"
   - Layout saved to backend
   - Success message shown

6. **User switches workspace**
   - Opens workspace dropdown
   - Selects "Research Mode"
   - Screen updates instantly
   - All widgets load in new positions

---

## 💾 Data Storage

### What Gets Saved?

When user saves a workspace, we save:
- Workspace name
- List of widgets (their types, positions, sizes, configurations)
- Grid settings
- Created/updated timestamps

### Where to Save?

**Option 1: Backend API** (Recommended)
- Extend existing user preferences API
- Store in database
- Syncs across devices
- Users can share layouts

**Option 2: Local Storage** (Fallback)
- Use SharedPreferences
- Only on current device
- Lost if app is uninstalled

### Data Format (JSON Example)

**Important**: Layouts are saved **per screen type**!

```json
{
  "workspace_id": "ws_123",
  "screen_type": "main_screen",          // ← Which screen this layout is for
  "name": "My Trading Setup",
  "widgets": [
    {
      "id": "widget_1",
      "type": "MARKET_SUMMARY",
      "position": {"x": 0, "y": 0},
      "size": {"width": 6, "height": 4},
      "config": {}
    },
    {
      "id": "widget_2",
      "type": "TRADING_VIEW",
      "position": {"x": 6, "y": 0},
      "size": {"width": 6, "height": 4},
      "config": {
        "symbol": "AAPL",
        "timeframe": "1D"
      }
    }
  ]
}
```

**Example for Ticker Detail Screen:**
```json
{
  "workspace_id": "ws_456",
  "screen_type": "ticker_detail",        // ← Different screen type
  "name": "Quick Analysis Layout",
  "widgets": [
    {
      "id": "widget_1",
      "type": "TRADING_VIEW",
      "position": {"x": 0, "y": 0},
      "size": {"width": 8, "height": 5},
      "config": {"symbol": "{{DYNAMIC}}"}  // Uses current ticker
    },
    {
      "id": "widget_2",
      "type": "NEWS_FEED",
      "position": {"x": 8, "y": 0},
      "size": {"width": 4, "height": 5},
      "config": {}
    }
  ]
}
```

**Key Point**: Each screen type can have multiple saved layouts, stored separately!

---

## 🎨 Grid System

### How Grid Works

Think of the dashboard as a **grid** (like a chess board):
- **12 or 24 columns** (horizontal)
- **Unlimited rows** (vertical)
- Each widget takes up **X columns × Y rows**

Example:
- Widget at position (0, 0) with size (6, 4) = Top-left, 6 columns wide, 4 rows tall
- Widget at position (6, 0) with size (6, 4) = Top-right, 6 columns wide, 4 rows tall

### Grid Benefits

✅ **Snap to Grid**: Widgets always align perfectly
✅ **No Overlapping**: Collision detection prevents widgets on top of each other
✅ **Responsive**: Grid adjusts to screen size
✅ **Easy Calculations**: Simple math for positioning

---

## 🔧 Resizing System: Full Width & Height Control

### Overview
Users can **resize any widget** by dragging resize handles. This includes:
- **Width adjustments**: Make widgets wider or narrower
- **Height adjustments**: Make widgets taller or shorter
- **Both dimensions**: Resize width and height simultaneously

### How Resizing Works

#### Resize Handles
In edit mode, each widget shows resize handles:
- **Corner handles** (8 total): Resize both width and height
- **Edge handles** (4 total): Resize only width (left/right) or height (top/bottom)

```
┌─────────────────────────────┐
│  ↖        ↑        ↗        │ ← Top edge and corners
│  ←                         → │ ← Left/Right edges
│  ↙        ↓        ↘        │ ← Bottom edge and corners
└─────────────────────────────┘
```

#### Resize Behavior
- **Grid-based**: Widgets resize in grid units (columns/rows)
- **Minimum sizes**: Each widget type has minimum width/height
- **Maximum sizes**: Widgets can't exceed screen bounds
- **Auto-adjustment**: Adjacent widgets automatically shift to accommodate resized widget
- **Collision prevention**: System prevents overlapping during resize

### Widget-Specific Resizing Examples

#### 1. **Watchlist Sidebar**
**Current**: Fixed narrow width (e.g., 2-3 columns)
**After Customization**:
- User can expand to **4-6 columns** for wider watchlist
- User can make it **taller** to show more tickers
- User can make it **narrower** to save space for other widgets
- **Use Case**: Trader wants to see more tickers at once → Expands width from 2 to 5 columns

#### 2. **Market Summary Table**
**Current**: Fixed width (e.g., 6 columns)
**After Customization**:
- User can make it **wider** (8-10 columns) to show more columns/data
- User can make it **narrower** (4 columns) to give more space to chart
- User can adjust **height** to show more/fewer rows
- **Use Case**: Analyst wants to see more market data → Expands to 10 columns wide

#### 3. **Trading View Chart**
**Current**: Fixed size (e.g., 6 columns × 4 rows)
**After Customization**:
- User can make chart **wider** for better technical analysis
- User can make chart **taller** to see more price history
- User can make it **full-width** (12 columns) for maximum visibility
- **Use Case**: Day trader wants larger chart → Expands to 10 columns × 6 rows

#### 4. **News Feed Widget**
**Current**: Fixed size
**After Customization**:
- User can make it **wider** to show more article content
- User can make it **taller** to see more articles without scrolling
- User can make it **narrower** to fit alongside other widgets
- **Use Case**: User wants to read more news → Expands height to 8 rows

#### 5. **Stock Heatmap**
**Current**: Fixed size
**After Customization**:
- User can make it **wider** to show more stocks
- User can make it **taller** for better visualization
- User can make it **full-screen** for detailed analysis
- **Use Case**: User wants to see entire market → Expands to 12 columns × 8 rows

#### 6. **Recommendations Widget**
**Current**: Fixed narrow sidebar
**After Customization**:
- User can expand **width** to show more recommendation details
- User can adjust **height** to see more recommendations
- **Use Case**: User wants detailed recommendations → Expands to 5 columns wide

#### 7. **Market Indices Row**
**Current**: Fixed horizontal row
**After Customization**:
- User can make each mini widget **wider** to show more data
- User can arrange in **2x2 grid** instead of horizontal row
- **Use Case**: User wants larger index displays → Each widget becomes 3 columns wide

#### 8. **Financial Data Tables**
**Current**: Fixed size
**After Customization**:
- User can make tables **wider** to show more columns
- User can make tables **taller** to show more rows
- **Use Case**: Analyst needs to see full financial statement → Expands to 10 columns × 12 rows

### Resize Constraints

Each widget type will have:
- **Minimum width**: Prevents widget from becoming too small to be useful
  - Watchlist: Minimum 2 columns
  - Charts: Minimum 4 columns
  - Tables: Minimum 3 columns
- **Minimum height**: Ensures content is readable
  - Watchlist: Minimum 3 rows
  - Charts: Minimum 3 rows
  - Tables: Minimum 2 rows
- **Maximum width**: Can't exceed screen width (12 columns)
- **Maximum height**: Can't exceed reasonable limits (prevents infinite scrolling)

### Resize Interactions

#### Corner Drag (Both Dimensions)
- User drags **bottom-right corner** → Widget expands both width and height
- User drags **top-left corner** → Widget shrinks both width and height
- **Visual feedback**: Grid highlights show new size in real-time

#### Edge Drag (Single Dimension)
- User drags **right edge** → Widget expands/shrinks width only
- User drags **left edge** → Widget expands/shrinks width only (shifts position)
- User drags **bottom edge** → Widget expands/shrinks height only
- User drags **top edge** → Widget expands/shrinks height only (shifts position)

#### Smart Resizing
- **Snap to grid**: Resize increments by grid units (1 column/row at a time)
- **Live preview**: Widget content updates as user drags
- **Collision detection**: System prevents resizing into other widgets
- **Auto-layout**: Adjacent widgets adjust automatically

### Real-World Resize Scenarios

#### Scenario 1: Expanding Watchlist
1. User enters edit mode
2. User hovers over watchlist widget
3. Resize handles appear on right edge
4. User drags right edge to the right
5. Watchlist expands from 2 columns → 3 columns → 4 columns → 5 columns
6. Other widgets automatically shift/adjust
7. User exits edit mode
8. Watchlist now shows more tickers in wider view

#### Scenario 2: Making Chart Larger
1. User wants bigger trading chart
2. User drags bottom-right corner of chart widget
3. Chart expands: 6×4 → 8×5 → 10×6
4. Market table automatically becomes narrower to accommodate
5. User saves layout as "Large Chart View"

#### Scenario 3: Narrow Sidebar, Wide Main Content
1. User makes watchlist narrower (5 columns → 2 columns)
2. User makes market table wider (6 columns → 9 columns)
3. More space for market data, less for watchlist
4. Perfect for users who focus on market data

### Technical Implementation

#### Resize Detection
- Use `GestureDetector` on resize handles
- Track drag delta (how much user moved)
- Convert pixel movement to grid units
- Update widget size in real-time

#### Size Constraints
```dart
class WidgetSizeConstraints {
  final int minWidth;   // Minimum columns
  final int maxWidth;   // Maximum columns
  final int minHeight;  // Minimum rows
  final int maxHeight;  // Maximum rows
}

// Example constraints:
// Watchlist: minWidth=2, maxWidth=6, minHeight=3, maxHeight=20
// Chart: minWidth=4, maxWidth=12, minHeight=3, maxHeight=15
// Table: minWidth=3, maxWidth=12, minHeight=2, maxHeight=20
```

#### Resize Validation
- Check if new size is within constraints
- Check if new size causes collisions
- If valid → Apply resize
- If invalid → Show visual feedback (red highlight) and prevent resize

---

## 🚀 Implementation Phases

### Phase 1: MVP (Minimum Viable Product)
**Goal**: Basic drag and drop working

- ✅ Create models (widget, layout)
- ✅ Create wrapper component
- ✅ Create controller
- ✅ Basic drag functionality
- ✅ Save/load one layout
- ⏱️ **Estimated Time**: 2-3 days

### Phase 2: Enhanced Features
**Goal**: Full customization

- ✅ **Resize widgets** (width and height)
  - Expand watchlist sidebar from narrow to wide
  - Resize charts, tables, and all widgets
  - Independent width and height control
  - Grid-based resizing with constraints
- ✅ Add/remove widgets
- ✅ Widget library panel
- ✅ Multiple layouts
- ✅ Widget configuration dialogs
- ⏱️ **Estimated Time**: 3-4 days

### Phase 3: Polish & Optimization
**Goal**: Production ready

- ✅ Smooth animations
- ✅ Keyboard shortcuts
- ✅ Widget presets
- ✅ Performance optimization
- ✅ Error handling
- ⏱️ **Estimated Time**: 2-3 days

**Total Estimated Time**: 7-10 days

---

## 🔑 Key Principles

### 1. Don't Touch Existing Widgets
All your existing widget files (`market_summary.dart`, `trading_view_widget.dart`, etc.) stay **completely unchanged**.

### 2. Write Once, Use Everywhere
The wrapper system is built **once** and used for all widgets.

### 3. Separation of Concerns
- **Models** = Data structure
- **Controller** = Business logic
- **Wrapper** = UI wrapper
- **Services** = Utilities

### 4. Backward Compatible
The old fixed layout can stay as a "default workspace" if needed.

---

## ✅ Benefits of This Approach

### For Development
- ✅ No changes to existing code = Less risk of bugs
- ✅ Single source of truth = Easier to maintain
- ✅ Modular design = Easy to test
- ✅ Reusable components = Faster development

### For Users
- ✅ Personal customization = Better user experience
- ✅ Multiple workspaces = Different setups for different needs
- ✅ Save time = Favorite layouts load instantly
- ✅ Professional feel = Like Bloomberg/TradingView

---

## 📝 Widget Types to Support

Here are the widgets that can be made customizable:

1. **Market Data**
   - Market Summary Table
   - Market Indices Row
   - Top Movers
   - Market Quotes

2. **Charts**
   - Trading View Chart (with configurable symbols)
   - Mini Charts (multiple symbols)

3. **Watchlists**
   - Watchlist Sidebar
   - Ticker Monitor

4. **Visualizations**
   - Stock Heatmap
   - ETF Heatmap
   - Crypto Heatmap
   - Forex Heatmap

5. **News & Research**
   - News Feed
   - Research Notes
   - Trading Ideas
   - Recommendations

6. **Portfolio**
   - Portfolio Summary
   - Position Monitor

---

## 🎯 Success Criteria

The feature is complete when:

- ✅ Users can drag widgets to rearrange
- ✅ Users can resize widgets (width and height independently)
  - ✅ Expand watchlist sidebar from 2 columns to 6+ columns
  - ✅ Resize charts to any desired width/height
  - ✅ Adjust table widths to show more/fewer columns
  - ✅ Resize any widget with corner and edge handles
  - ✅ Resize constraints enforced (min/max sizes)
  - ✅ Collision detection prevents overlapping
- ✅ Users can add widgets from library
- ✅ Users can remove widgets
- ✅ Users can save multiple workspaces
- ✅ Users can switch between workspaces
- ✅ Layout persists after app restart
- ✅ All existing widgets work normally
- ✅ No performance issues
- ✅ Smooth animations (60fps)

---

## 🐛 Potential Challenges & Solutions

### Challenge 1: Widget State Management
**Problem**: Some widgets have complex state (controllers, timers, etc.)
**Solution**: Widget factory creates fresh instances. Wrapper doesn't affect widget lifecycle.

### Challenge 2: Performance with Many Widgets
**Problem**: Too many widgets might slow down the app
**Solution**: 
- Only render visible widgets
- Use `AutomaticKeepAliveClientMixin` for important widgets
- Lazy loading for widgets off-screen

### Challenge 3: Responsive Design
**Problem**: Widgets need to work on different screen sizes
**Solution**: Grid system automatically adjusts. Widgets scale proportionally.

### Challenge 4: WebView Widgets (TradingView)
**Problem**: WebViews might not work well with drag/resize
**Solution**: Wrapper handles positioning, WebView just resizes. TradingView widgets already support resizing.

---

## 📚 Technical Details (For Developers)

### Technologies Used

- **GetX**: For state management (already in project)
- **Flutter Gesture Detector**: For drag operations
- **Custom Grid System**: Built with Flutter's layout widgets
- **JSON**: For layout data storage
- **HTTP API**: For saving/loading layouts (extend existing API)

### Dependencies

No new dependencies needed! We'll use:
- ✅ `get` package (already installed)
- ✅ `http` package (already installed)
- ✅ Flutter built-in widgets only

---

## 🎓 Learning Resources

If you want to understand the concepts better:

1. **Flutter Drag and Drop**: Official Flutter documentation on `Draggable` and `DragTarget`
2. **Grid Systems**: Research CSS Grid or Bootstrap Grid (similar concept)
3. **State Management**: GetX documentation (already using it)
4. **Layout Systems**: Flutter's layout widgets documentation

---

## 🌟 App-Wide Customization: Complete Picture

### How It All Works Together

#### 1. **One Wrapper System, Multiple Screens**

The same wrapper component (`DraggableWidgetWrapper`) works everywhere:
- ✅ Main Dashboard
- ✅ Ticker Detail Screen
- ✅ Screener Screen
- ✅ Any screen you add

**No duplication** - write once, use everywhere!

#### 2. **Screen-Specific Controllers**

Each screen gets its own controller instance:
```dart
// Main Screen
LayoutController(screenType: 'main_screen')

// Ticker Detail Screen
LayoutController(screenType: 'ticker_detail')

// Screener Screen
LayoutController(screenType: 'screener')
```

Same controller class, different instances = different layouts per screen!

#### 3. **Screen-Specific Widget Libraries**

Each screen can have different widgets available:
- **Main Screen**: Market widgets, Charts, Heatmaps, Indices
- **Ticker Detail**: Chart, News, Recommendations, Financials, Research Notes
- **Screener**: Filter widgets, Result tables, Analysis tools
- **Portfolio**: Portfolio widgets, Performance charts, Holdings

Widget factory knows which widgets are available for each screen type.

#### 4. **Independent Layout Storage**

Each screen's layouts are saved separately:
```
User's Saved Layouts:
├── main_screen/
│   ├── "Trading Setup"
│   ├── "Research Mode"
│   └── "Market Overview"
├── ticker_detail/
│   ├── "Quick Analysis"
│   └── "Deep Dive"
├── screener/
│   ├── "Wide Results"
│   └── "Compact View"
└── ...
```

Users can customize each screen independently!

#### 5. **Same User Experience, Everywhere**

Wherever users see customizable widgets:
- Same drag & drop behavior
- Same resize handles
- Same edit mode
- Same widget library panel
- Same save/load workflow

Consistent experience = easier to learn!

---

## 📊 Implementation Priority (Which Screens First?)

### Phase 1: MVP - Main Dashboard Only
- Start with main dashboard screen
- Test the system thoroughly
- Get user feedback

### Phase 2: Expand to Key Screens
- Ticker Detail Screen (high value for users)
- Screener Screen (frequently used)

### Phase 3: Complete Coverage
- All remaining screens
- Portfolio screens
- Sector/ETF detail screens

### Phase 4: Advanced Features
- Cross-screen widget sharing
- Widget templates
- Shared layouts across screen types

---

## 🎯 Benefits of App-Wide Approach

### For Users
✅ **Consistent Experience**: Same customization everywhere they go
✅ **Personal Workspace**: Every screen customized to their needs
✅ **Productivity**: Faster workflows with custom layouts
✅ **Flexibility**: Different layouts for different tasks

### For Developers
✅ **Reusable Code**: Write wrapper once, use everywhere
✅ **Easy to Maintain**: Fix bugs in one place, applies everywhere
✅ **Scalable**: Add new screens easily without new customization code
✅ **Clean Architecture**: Separation of concerns, easy to test

---

## ❓ FAQ

### Q: Do we need to modify existing widgets?
**A**: No! All existing widgets stay exactly the same. We wrap them.

### Q: What if a widget doesn't support resizing?
**A**: The wrapper handles resizing by changing container size. Most widgets will work fine. The wrapper system ensures all widgets can be resized regardless of their internal implementation.

### Q: Can I make the watchlist sidebar wider?
**A**: Yes! You can expand the watchlist from its default narrow width (2-3 columns) to any width up to 6+ columns, depending on your screen size and other widgets. Just drag the right edge handle in edit mode.

### Q: Are there limits to how big/small I can make widgets?
**A**: Yes, each widget type has minimum and maximum size constraints to ensure usability. For example, watchlist minimum is 2 columns, charts minimum is 4 columns. These prevent widgets from becoming unusable.

### Q: Can users break the layout?
**A**: We'll add validation to prevent overlapping and maintain minimum sizes.

### Q: What about mobile?
**A**: This feature is designed for desktop/macOS (terminal app). Mobile can use simplified version later.

### Q: How do we handle widget errors?
**A**: Widget factory can return error widget if creation fails. Wrapper shows error state.

### Q: Can widgets communicate with each other?
**A**: Through GetX controllers (already in use). Widgets can listen to shared state.

### Q: Do I need to implement this on all screens at once?
**A**: No! Start with one screen (main dashboard), then gradually add to other screens. The system is designed to work incrementally.

### Q: Can users have different layouts on different screens?
**A**: Yes! Each screen type has its own set of saved layouts. A user can have "Trading Setup" on main screen and "Quick Analysis" on ticker detail screen - completely independent!

### Q: What if a screen doesn't need customization?
**A**: That's fine! The system is optional. If a screen doesn't use the customizable layout component, it works normally with fixed layout.

### Q: Can I customize only specific parts of a screen?
**A**: Yes! You can make only certain sections customizable. For example, keep the header fixed but make the content area customizable.

### Q: How do widget libraries work for different screens?
**A**: Each screen type has its own widget registry. The widget factory service knows which widgets are available for each screen and only shows relevant ones.

---

## 🚦 Next Steps

1. **Review this plan** with team
2. **Create models** first (data structure)
3. **Build wrapper** component (test with one widget)
4. **Create controller** (manage widget state)
5. **Integrate** with main screen
6. **Test** thoroughly
7. **Deploy** to users

---

## 📞 Questions?

If you have questions about any part of this plan, just ask! The key takeaway is:

**Build wrapper system once → Use on ALL screens → Wrap existing widgets → No changes to widget files**

---

## 🎯 Summary: App-Wide Customization

This plan enables **full customization across your entire application**:

✅ **One Wrapper System** - Works on every screen
✅ **Screen-Specific Layouts** - Each screen can have multiple saved layouts
✅ **Independent Customization** - Users customize each screen separately
✅ **Full Resizing Control** - Users can resize any widget (width and height)
  - Expand watchlist sidebar from narrow to wide
  - Resize charts, tables, and all widgets to any desired size
  - Independent width and height adjustments
✅ **No Widget Changes** - All existing widgets stay untouched
✅ **Scalable** - Easy to add new screens with customization
✅ **Consistent UX** - Same experience everywhere

### The Magic Formula:
```
Wrapper System (write once)
  ↓
Use on ANY screen
  ↓
Wrap existing widgets (no changes)
  ↓
Users customize everything!
```

---

**Last Updated**: [Current Date]
**Status**: Planning Phase - App-Wide Customization
**Estimated Completion**: 
- MVP (Main Dashboard): 7-10 days
- Full App Coverage: 2-3 weeks (gradual rollout)

