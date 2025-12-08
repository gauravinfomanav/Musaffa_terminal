import 'package:get/get.dart';

class GlobalWatchlistService extends GetxController {
  final RxBool isWatchlistOpen = false.obs;
  
  void toggleWatchlist() {
    isWatchlistOpen.value = !isWatchlistOpen.value;
  }
  
  void openWatchlist() {
    isWatchlistOpen.value = true;
  }
  
  void closeWatchlist() {
    isWatchlistOpen.value = false;
  }
}

