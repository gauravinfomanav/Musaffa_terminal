import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global service to manage search field focus across the entire app
class GlobalSearchService extends GetxService {
  FocusNode? _searchFocusNode;
  
  /// Register the search field's FocusNode
  void registerSearchFocusNode(FocusNode focusNode) {
    _searchFocusNode = focusNode;
  }
  
  /// Unregister the search field's FocusNode
  void unregisterSearchFocusNode() {
    _searchFocusNode = null;
  }
  
  /// Focus the search field from anywhere in the app
  void focusSearchField() {
    if (_searchFocusNode != null && _searchFocusNode!.canRequestFocus) {
      _searchFocusNode!.requestFocus();
    }
  }
  
  /// Check if search field is registered
  bool get isSearchFieldRegistered => _searchFocusNode != null;
}

