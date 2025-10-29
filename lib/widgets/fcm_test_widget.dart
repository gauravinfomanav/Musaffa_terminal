import 'package:flutter/material.dart';
import 'package:musaffa_terminal/services/fcm_service.dart';

class FCMTestWidget extends StatelessWidget {
  const FCMTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'FCM Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Token: ${FCMService.fcmToken ?? "Not available"}',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await FCMService.reRegisterToken();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('FCM token refreshed')),
              );
            },
            child: Text('Refresh Token'),
          ),
        ],
      ),
    );
  }
}

