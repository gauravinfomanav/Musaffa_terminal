import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';

class CreateWatchlistDialog extends StatefulWidget {
  final bool isDarkMode;

  const CreateWatchlistDialog({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CreateWatchlistDialog> createState() => _CreateWatchlistDialogState();
}

class _CreateWatchlistDialogState extends State<CreateWatchlistDialog> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _createWatchlist() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Watchlist name cannot be empty';
      });
      return;
    }

    if (name.length > 100) {
      setState(() {
        _errorMessage = 'Watchlist name must be less than 100 characters';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final controller = Get.find<WatchlistController>();
      final success = await controller.createWatchlist(name);
      
      if (success) {
        // Close dialog and show success message
        Navigator.of(context).pop();
        _showSuccessMessage(name);
      } else {
        setState(() {
          _errorMessage = controller.errorMessage.value.isNotEmpty 
              ? controller.errorMessage.value 
              : 'Failed to create watchlist';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating watchlist: $e';
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _showSuccessMessage(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Watchlist "$name" created successfully',
          style: DashboardTextStyles.tickerSymbol.copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF374151) : const Color(0xFF6B7280),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDarkMode ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 18,
                  color: widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                ),
                const SizedBox(width: 8),
                Text(
                  'CREATE WATCHLIST',
                  style: DashboardTextStyles.columnHeader.copyWith(
                    color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: widget.isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Input field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WATCHLIST NAME',
                  style: DashboardTextStyles.columnHeader.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  focusNode: _focusNode,
                  enabled: !_isCreating,
                  maxLength: 100,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _createWatchlist(),
                  style: DashboardTextStyles.stockName.copyWith(
                    color: widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., My Tech Stocks',
                    hintStyle: DashboardTextStyles.tickerSymbol.copyWith(
                      color: widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                    counterText: '', // Hide character counter
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFF81AACE),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: Colors.red.shade400,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 14,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: DashboardTextStyles.tickerSymbol.copyWith(
                        color: Colors.red.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                GestureDetector(
                  onTap: _isCreating ? null : () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: DashboardTextStyles.columnHeader.copyWith(
                        color: _isCreating 
                            ? (widget.isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF))
                            : (widget.isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF374151)),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Create button
                GestureDetector(
                  onTap: _isCreating ? null : _createWatchlist,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isCreating 
                          ? (widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB))
                          : (widget.isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isCreating) ...[
                          Container(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          Icon(
                            Icons.add,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _isCreating ? 'CREATING...' : 'CREATE',
                          style: DashboardTextStyles.columnHeader.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
