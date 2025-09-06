/// API response validator and error handler
/// Manages authentication errors (401) by clearing user data and redirecting to login
/// Also handles general API errors by displaying snackbar notifications
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:get/get.dart';

class ApiChecker {
  static Future<void> checkApi(Response response, {bool showToaster = false}) async {
    if(response.statusCode == 401) {
      await Get.find<AuthController>().clearSharedData(removeToken: false).then((value) {
        Get.find<FavouriteController>().removeFavourites();
        Get.offAllNamed(RouteHelper.getInitialRoute());
      });
    } else {
      showCustomSnackBar(response.statusText);
    }
  }
}
