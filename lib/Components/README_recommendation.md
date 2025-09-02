# Recommendation Components

This directory contains components for displaying analyst recommendations and consensus data from Typesense.

## Files Created

### 1. `recommendation_model.dart`
- **Purpose**: Data model for recommendation data from Typesense
- **Features**:
  - Parses JSON response from Typesense API
  - Calculates weighted average recommendation score
  - Provides recommendation text and color based on consensus
  - Handles missing data gracefully

### 2. `recommendation_controller.dart`
- **Purpose**: Controller for managing recommendation data fetching and state
- **Features**:
  - Fetches data from Typesense using existing WebService
  - Manages loading states and error handling
  - Calculates percentages for each recommendation type
  - Extends ChangeNotifier for reactive UI updates

### 3. `recommendation_widget.dart`
- **Purpose**: Main UI component displaying recommendations
- **Features**:
  - Custom gauge visualization using Flutter's CustomPainter
  - Horizontal bars showing distribution of analyst ratings
  - Responsive layout with gauge on left, bars on right
  - Color-coded recommendations (green for buy, red for sell)

### 4. `recommendation_example.dart`
- **Purpose**: Example implementation and integration guide
- **Features**:
  - Standalone example screen
  - Integration instructions for existing screens
- **Usage**: Reference for developers integrating the widget

## API Endpoint

The controller fetches data from:
```
https://0bs2hegi5nmtad4op.a1.typesense.net/collections/recommendation_collection/documents/{SYMBOL}
```

## Data Structure

Expected JSON response:
```json
{
  "buy": 25,
  "hold": 14,
  "id": "AAPL",
  "period": "2025-05-01",
  "sell": 3,
  "strongBuy": 14,
  "strongSell": 0,
  "symbol": "AAPL",
  "ticker": "AAPL"
}
```

## Integration Steps

1. **Import the components**:
   ```dart
   import 'package:musaffa_terminal/Components/recommendation_widget.dart';
   import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';
   ```

2. **Initialize controller**:
   ```dart
   late RecommendationController _recommendationController;
   
   @override
   void initState() {
     super.initState();
     _recommendationController = RecommendationController();
   }
   ```

3. **Add widget to UI**:
   ```dart
   RecommendationWidget(
     symbol: 'AAPL',
     controller: _recommendationController,
   )
   ```

4. **Dispose controller**:
   ```dart
   @override
   void dispose() {
     _recommendationController.dispose();
     super.dispose();
   }
   ```

## Features

- **Real-time data**: Fetches live data from Typesense API
- **Responsive design**: Adapts to different screen sizes
- **Error handling**: Gracefully handles API errors and missing data
- **Loading states**: Shows loading indicators during data fetch
- **Custom gauge**: Built with Flutter's CustomPainter for performance
- **Color coding**: Intuitive color scheme for recommendation levels

## Customization

The widget can be customized by:
- Modifying colors in the `GaugePainter` class
- Adjusting layout proportions in the `Expanded` widgets
- Changing text styles and fonts
- Modifying the gauge dimensions and appearance
