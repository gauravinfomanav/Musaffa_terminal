import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/recommendation_widget.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';

class RecommendationExample extends StatelessWidget {
  const RecommendationExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyst Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RecommendationWidget(
                symbol: 'AAPL',
                controller: RecommendationController(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example of how to integrate into existing screens:
/*
// In your existing screen, add this import:
import 'package:musaffa_terminal/Components/recommendation_widget.dart';
import 'package:musaffa_terminal/Controllers/recommendation_controller.dart';

// In your screen's state class, add:
late RecommendationController _recommendationController;

@override
void initState() {
  super.initState();
  _recommendationController = RecommendationController();
}

// In your build method, add the widget:
RecommendationWidget(
  symbol: 'AAPL', // or whatever symbol you want
  controller: _recommendationController,
),

// Don't forget to dispose:
@override
void dispose() {
  _recommendationController.dispose();
  super.dispose();
}
*/
