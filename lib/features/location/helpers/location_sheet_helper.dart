import 'package:flutter/material.dart';
import 'package:godelivery_user/features/location/widgets/location_manager_sheet.dart';

/// Helper to open the location selection bottom sheet anywhere in the app.
class LocationSheetHelper {
  static void showSelectionSheet(BuildContext context) {
    LocationManagerSheet.show(context);
  }
}
