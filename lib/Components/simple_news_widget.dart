import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/market_news_controller.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class SimpleNewsWidget extends StatelessWidget {
  final String symbol;

  const SimpleNewsWidget({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MarketNewsController());
    
    // Fetch news on widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMarketNews(symbol);
    });

    return Obx(() {
      if (controller.isLoading.value) {
        return _buildShimmer();
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return _buildError(controller.errorMessage.value);
      }

      final terminalNews = controller.getTerminalNews(limit: 10);
      
      if (terminalNews.isEmpty) {
        return _buildEmpty();
      }

      return _buildNewsList(terminalNews);
    });
  }

  Widget _buildShimmer() {
    return Column(
      children: List.generate(10, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerWidgets.box(
            width: double.infinity,
            height: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        'Error: $error',
        style: const TextStyle(color: Colors.red, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: const Text(
        'No news available',
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNewsList(List<Map<String, String>> newsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with better styling
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // News items
        ...newsList.map((news) => _buildNewsItem(news)).toList(),
      ],
    );
  }

  Widget _buildNewsItem(Map<String, String> news) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time on left - single line
              Container(
                 width: 70,
                child: Text(
                  news['datetime'] ?? '--',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontFamily: Constants.FONT_DEFAULT_NEW,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Summary on right - compact
              Expanded(
                child: Text(
                  news['summary'] ?? '--',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Light divider
        Container(
          height: 1,
          margin: const EdgeInsets.only(left: 82), // Align with summary text (70 + 12)
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(0.5),
          ),
        ),
      ],
    );
  }
}
