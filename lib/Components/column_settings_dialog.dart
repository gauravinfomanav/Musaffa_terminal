import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Dialog for customizing table columns (show/hide, reorder)
class ColumnSettingsDialog extends StatefulWidget {
  final List<SimpleColumn> columns;
  final Map<String, bool> columnVisibility;
  final Function(String, bool) onVisibilityChanged;
  final Function(List<SimpleColumn>) onColumnReordered;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const ColumnSettingsDialog({
    required this.columns,
    required this.columnVisibility,
    required this.onVisibilityChanged,
    required this.onColumnReordered,
    required this.onReset,
    required this.onSave,
  });

  @override
  State<ColumnSettingsDialog> createState() => _ColumnSettingsDialogState();
}

class _ColumnSettingsDialogState extends State<ColumnSettingsDialog> {
  late List<SimpleColumn> _reorderableColumns;
  late Map<String, bool> _localVisibility;

  @override
  void initState() {
    super.initState();
    _reorderableColumns = List.from(widget.columns);
    _localVisibility = Map.from(widget.columnVisibility);
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _reorderableColumns.removeAt(oldIndex);
      _reorderableColumns.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB);
    final textColor = isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151);
    final subTextColor = isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customize Columns',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: Constants.FONT_DEFAULT_NEW,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: subTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drag to reorder columns',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                          fontFamily: Constants.FONT_DEFAULT_NEW,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: _handleReorder,
                        children: _reorderableColumns.map((column) {
                          final isVisible = _localVisibility[column.fieldName] ?? true;
                          return _ColumnItem(
                            key: ValueKey(column.fieldName),
                            column: column,
                            isVisible: isVisible,
                            onVisibilityChanged: (value) {
                              setState(() {
                                _localVisibility[column.fieldName] = value;
                              });
                              widget.onVisibilityChanged(column.fieldName, value);
                            },
                            isDarkMode: isDarkMode,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            borderColor: borderColor,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                    },
                    child: Text(
                      'Reset to Defaults',
                      style: TextStyle(
                        color: subTextColor,
                        fontFamily: Constants.FONT_DEFAULT_NEW,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: subTextColor,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.onColumnReordered(_reorderableColumns);
                          widget.onSave();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode 
                              ? const Color(0xFF81AACE) 
                              : const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: Constants.FONT_DEFAULT_NEW,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnItem extends StatelessWidget {
  final SimpleColumn column;
  final bool isVisible;
  final Function(bool) onVisibilityChanged;
  final bool isDarkMode;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const _ColumnItem({
    Key? key,
    required this.column,
    required this.isVisible,
    required this.onVisibilityChanged,
    required this.isDarkMode,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_handle,
            size: 20,
            color: subTextColor,
          ),
          const SizedBox(width: 12),
          // Column label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  column.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
                Text(
                  column.fieldName,
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                ),
              ],
            ),
          ),
          // Visibility toggle
          Switch(
            value: isVisible,
            onChanged: onVisibilityChanged,
            activeColor: isDarkMode 
                ? const Color(0xFF81AACE) 
                : const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }
}

