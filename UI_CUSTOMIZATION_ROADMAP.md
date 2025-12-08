# UI Customization Roadmap - Next Steps

## 🎯 Current State (What We Have)
✅ **Completed:**
- Resizable watchlist sidebar (works globally across all screens)
- Resizable table/chart divider on main screen (50-50 split)
- Floating Action Buttons (FABs) from tabbar icons
- Table columns expand when resized wider

---

## 🚀 Suggested Next Features (Priority Order)

### **Phase 1: Main Screen Enhancements** (Quick Wins - 1-2 days)

#### 1.1 **Resizable Heatmap Section**
**What:** Make the heatmap section resizable (height)
- Add drag handle at bottom of heatmap
- Allow users to adjust height (min: 400px, max: 800px)
- Save height preference

**Why:** Users might want more/less heatmap visibility

**Implementation:**
- Similar to table/chart divider
- Add vertical drag handle
- Store height in state/local storage

---

#### 1.2 **Draggable Widget Reordering**
**What:** Allow users to drag widgets to reorder them
- Drag MiniWidgetsRow to different positions
- Drag heatmap above/below table+chart
- Visual feedback during drag

**Why:** Users have different workflow preferences

**Implementation:**
- Wrap widgets in `Draggable`/`DragTarget`
- Use `ReorderableListView` or custom drag system
- Save order preference

---

#### 1.3 **Collapsible Sections**
**What:** Add collapse/expand buttons to sections
- Collapse heatmap section
- Collapse mini widgets row
- Save collapsed state

**Why:** More screen space when needed

**Implementation:**
- Add toggle buttons
- Use `AnimatedSize` for smooth transitions
- Store state in controller

---

### **Phase 2: Multi-Screen Customization** (Medium Priority - 3-5 days)

#### 2.1 **Ticker Detail Screen - Resizable Panels**
**What:** Make panels resizable on ticker detail screen
- Trading Chart vs News Feed divider (vertical)
- Recommendations panel (horizontal)
- Financial data tables

**Why:** Different users need different focus areas

**Screens to customize:**
- `ticker_detail_screen.dart` - Chart, News, Recommendations, Financials
- Similar to main screen table/chart divider

---

#### 2.2 **Screener Screen - Resizable Filter Panel**
**What:** Make filter panel resizable
- Left filter panel width adjustable
- Results table takes remaining space
- Save width preference

**Why:** Some users need wider filters, others need more table space

**Implementation:**
- Add drag handle between filter panel and results
- Similar to watchlist sidebar resize

---

#### 2.3 **Portfolio Screen - Customizable Layout**
**What:** Allow rearrangement of portfolio widgets
- Portfolio builder form sections
- Performance charts
- Position tables
- Drag to reorder

**Why:** Different portfolio analysis workflows

---

### **Phase 3: Advanced Customization** (Higher Priority - 1 week)

#### 3.1 **Widget Library & Add/Remove System**
**What:** Users can add/remove widgets from a library
- Widget picker panel (slide-in from side)
- Add: News feed, Top movers, Custom charts
- Remove: Any widget they don't need
- Save widget configuration per screen

**Why:** Ultimate customization - users build their own dashboard

**Widgets to support:**
- Market Summary Table
- Trading Chart
- Heatmap
- News Feed
- Top Movers
- Market Indices
- Custom watchlists
- Alerts panel

---

#### 3.2 **Save/Load Layout Presets**
**What:** Save multiple layout configurations
- "Trading Mode" - Wide chart, small table
- "Research Mode" - Wide table, small chart
- "Overview Mode" - Balanced layout
- Quick switch between presets

**Why:** Users switch between different workflows

**Implementation:**
- Layout controller with GetX
- Save to local storage (shared_preferences)
- UI: Dropdown/popup to select preset
- "Save Current Layout" button

---

#### 3.3 **Grid-Based Layout System**
**What:** Snap widgets to a grid system
- 12-column grid (like Bootstrap)
- Widgets snap to grid positions
- Drag widgets to grid cells
- Auto-adjust on resize

**Why:** Professional, organized layouts

**Implementation:**
- Custom grid layout widget
- Calculate grid positions from drag
- Store grid coordinates

---

### **Phase 4: Screen-Specific Features** (Lower Priority)

#### 4.1 **Ticker Detail Screen - Tab Customization**
**What:** Customize which tabs are visible
- Show/hide: Overview, Financials, News, etc.
- Reorder tabs
- Save per-user preferences

---

#### 4.2 **Screener Screen - Filter Panel Customization**
**What:** Customize filter panel layout
- Collapse filter categories
- Reorder filter groups
- Save filter panel state

---

#### 4.3 **ETF Details Screen - Panel Resizing**
**What:** Resizable panels for ETF data
- Holdings table vs Performance chart
- Allocation widgets
- Similar to main screen approach

---

## 🎨 UI/UX Enhancements

### **Visual Feedback**
- Hover effects on draggable widgets
- Drop zones highlight when dragging
- Smooth animations for all resizing
- Loading states when saving layouts

### **Keyboard Shortcuts**
- `Ctrl/Cmd + S` - Save current layout
- `Ctrl/Cmd + R` - Reset to default
- `Ctrl/Cmd + E` - Enter edit mode
- Arrow keys to nudge widget positions

### **Layout Templates**
- Pre-built templates:
  - "Day Trader" - Charts focused
  - "Analyst" - Data tables focused
  - "News Reader" - News feed focused
  - "Balanced" - Everything visible

---

## 📊 Implementation Priority Matrix

| Feature | Impact | Effort | Priority |
|---------|--------|--------|----------|
| Resizable Heatmap | High | Low | ⭐⭐⭐ |
| Collapsible Sections | Medium | Low | ⭐⭐ |
| Ticker Detail Resizing | High | Medium | ⭐⭐⭐ |
| Screener Filter Resize | Medium | Medium | ⭐⭐ |
| Widget Add/Remove | Very High | High | ⭐⭐⭐ |
| Save/Load Presets | Very High | Medium | ⭐⭐⭐ |
| Grid System | High | High | ⭐⭐ |
| Tab Customization | Low | Medium | ⭐ |

---

## 🛠️ Technical Approach

### **State Management**
- Use GetX controllers for layout state
- `LayoutController` - Manages widget positions, sizes, visibility
- `LayoutPresetController` - Manages saved layouts
- Local storage for persistence

### **Reusable Components**
- `ResizableWidget` - Wrapper for any resizable widget
- `DraggableWidget` - Wrapper for draggable widgets
- `LayoutGrid` - Grid-based layout container
- `WidgetLibrary` - Widget picker panel

### **Data Structure**
```dart
class LayoutConfig {
  String screenId; // 'main', 'ticker_detail', etc.
  List<WidgetConfig> widgets;
  Map<String, double> sizes; // widgetId -> width/height
  Map<String, Offset> positions; // widgetId -> position
  bool isCollapsed;
}

class WidgetConfig {
  String id;
  String type; // 'table', 'chart', 'heatmap', etc.
  bool isVisible;
  double width;
  double height;
  Offset position;
}
```

---

## 🎯 Recommended Next Steps (Start Here)

### **Week 1: Quick Wins**
1. ✅ Resizable heatmap height (2-3 hours)
2. ✅ Collapsible sections (2-3 hours)
3. ✅ Draggable reordering for main screen (4-6 hours)

### **Week 2: Multi-Screen**
1. ✅ Ticker detail screen resizing (1 day)
2. ✅ Screener filter panel resize (1 day)
3. ✅ Portfolio screen customization (1 day)

### **Week 3: Advanced Features**
1. ✅ Widget library system (2-3 days)
2. ✅ Save/load presets (1-2 days)
3. ✅ Grid-based layout (2-3 days)

---

## 💡 Creative Ideas

### **Smart Layouts**
- AI-suggested layouts based on usage patterns
- "Most used widgets" auto-arrangement
- Time-based layouts (morning vs evening setup)

### **Layout Sharing**
- Export/import layout configurations
- Share layouts with team members
- Community layout marketplace

### **Responsive Breakpoints**
- Different layouts for mobile/tablet/desktop
- Auto-adjust on window resize
- Remember preferences per device size

### **Widget Customization**
- Custom colors for widgets
- Font size preferences
- Data density settings (compact vs spacious)

---

## 📝 Notes

- **Start Simple:** Begin with resizable/collapsible features
- **User Testing:** Get feedback after each phase
- **Performance:** Ensure smooth animations (60fps)
- **Accessibility:** Keyboard navigation support
- **Mobile:** Consider touch gestures for mobile

---

## 🚦 Status Tracking

- [ ] Phase 1: Main Screen Enhancements
- [ ] Phase 2: Multi-Screen Customization  
- [ ] Phase 3: Advanced Customization
- [ ] Phase 4: Screen-Specific Features

---

**Last Updated:** Based on current codebase analysis
**Next Review:** After Phase 1 completion

