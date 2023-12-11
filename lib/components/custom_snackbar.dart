import 'package:get/get.dart';

getSnackbar(String description) {
  Get.snackbar(
    animationDuration: const Duration(milliseconds: 500),
    duration: const Duration(seconds: 2),
    "Issue Found",
    description,
  );
}
