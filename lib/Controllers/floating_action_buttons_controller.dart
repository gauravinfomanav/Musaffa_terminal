import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum FABType {
  screener,
  ideas,
  portfolio,
  watchlist,
}

class FloatingActionButtonItem {
  final FABType type;
  final String id;
  final Offset position; // Position on screen

  FloatingActionButtonItem({
    required this.type,
    required this.id,
    required this.position,
  });

  FloatingActionButtonItem copyWith({Offset? position}) {
    return FloatingActionButtonItem(
      type: type,
      id: id,
      position: position ?? this.position,
    );
  }
}

class FloatingActionButtonsController extends GetxController {
  final RxList<FloatingActionButtonItem> _fabs = <FloatingActionButtonItem>[].obs;
  
  List<FloatingActionButtonItem> get fabs => _fabs;
  
  // Check if a FAB type already exists
  bool hasFAB(FABType type) {
    return _fabs.any((fab) => fab.type == type);
  }
  
  // Add a new FAB (when icon is dragged from tabbar)
  void addFAB(FABType type) {
    if (hasFAB(type)) return; // Don't add duplicates
    
    final screenWidth = Get.context != null 
        ? MediaQuery.of(Get.context!).size.width 
        : 1920.0;
    final screenHeight = Get.context != null 
        ? MediaQuery.of(Get.context!).size.height 
        : 1080.0;
    
    // Position new FABs bottom-right, stacked vertically
    final existingCount = _fabs.length;
    final spacing = 70.0; // Space between FABs
    final bottomOffset = 80.0; // Distance from bottom
    final rightOffset = 24.0; // Distance from right
    
    final position = Offset(
      screenWidth - rightOffset - 56, // 56 is FAB size
      screenHeight - bottomOffset - (existingCount * spacing) - 56,
    );
    
    _fabs.add(FloatingActionButtonItem(
      type: type,
      id: '${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      position: position,
    ));
  }
  
  // Check if icon should be hidden in tabbar (because it's a FAB)
  bool shouldHideInTabbar(FABType type) {
    return hasFAB(type);
  }
  
  // Remove a FAB
  void removeFAB(String id) {
    _fabs.removeWhere((fab) => fab.id == id);
  }
  
  // Update FAB position (for dragging)
  void updateFABPosition(String id, Offset newPosition) {
    final index = _fabs.indexWhere((fab) => fab.id == id);
    if (index != -1) {
      _fabs[index] = _fabs[index].copyWith(position: newPosition);
    }
  }
  
  // Remove all FABs
  void clearAll() {
    _fabs.clear();
  }
}

