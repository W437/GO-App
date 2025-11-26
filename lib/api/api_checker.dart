/// API response validator and error handler
/// Manages authentication errors (401) by clearing user data and redirecting to login
/// Also handles general API errors by displaying snackbar notifications
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:get/get.dart';

class ApiChecker {
  static Future<void> checkApi(Response response, {bool showToaster = false}) async {
    if(response.statusCode == 401) {
      // Session expired - clear auth token but preserve guest data and cart
      // This allows guests to continue using the app even when hitting endpoints that require real auth
      await Get.find<AuthController>().clearSharedData(removeToken: false, clearGuestData: false);
      Get.find<FavouriteController>().removeFavourites();
      // DON'T navigate - respect user's current context (modals, screens, etc.)
    } else if(response.statusCode != 500) {
      // Don't show toast for 500 errors - these are server-side issues that should be silent
      showCustomSnackBar(response.statusText);
    }
  }
}
