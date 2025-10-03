import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:godelivery_user/features/cart/screens/cart_screen.dart';
import 'package:godelivery_user/features/checkout/widgets/congratulation_dialogue.dart';
import 'package:godelivery_user/features/dashboard/widgets/registration_success_bottom_sheet.dart';
import 'package:godelivery_user/features/home/screens/home_screen.dart';
import 'package:godelivery_user/features/menu/screens/menu_screen.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/features/order/screens/order_screen.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/order/domain/models/order_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/dashboard/controllers/dashboard_controller.dart';
import 'package:godelivery_user/features/dashboard/widgets/address_bottom_sheet.dart';
import 'package:godelivery_user/features/dashboard/widgets/bottom_nav_item.dart';
import 'package:godelivery_user/features/dashboard/widgets/circular_reveal_clipper.dart';
import 'package:godelivery_user/features/dashboard/widgets/running_order_view_widget.dart';
import 'package:godelivery_user/features/favourite/screens/favourite_screen.dart';
import 'package:godelivery_user/features/loyalty/controllers/loyalty_controller.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/common/widgets/cart_widget.dart';
import 'package:godelivery_user/common/widgets/custom_dialog_widget.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardScreen extends StatefulWidget {
  final int pageIndex;
  final bool fromSplash;
  const DashboardScreen({super.key, required this.pageIndex, this.fromSplash = false});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  PageController? _pageController;
  int _pageIndex = 0;
  int _previousPageIndex = 0;
  late List<Widget> _screens;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();
  bool _canExit = GetPlatform.isWeb ? true : false;
  late bool _isLogin;
  bool active = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = 1.0;

    _isLogin = Get.find<AuthController>().isLoggedIn();

    _showRegistrationSuccessBottomSheet();

    if(_isLogin){
      if(Get.find<SplashController>().configModel!.loyaltyPointStatus == 1 && Get.find<LoyaltyController>().getEarningPint().isNotEmpty && !ResponsiveHelper.isDesktop(Get.context)){
        Future.delayed(const Duration(seconds: 1), () => showAnimatedDialog(Get.context!, const CongratulationDialogue()));
      }
      _suggestAddressBottomSheet();
      Get.find<OrderController>().getRunningOrders(1, notify: false);
    }

    _pageIndex = widget.pageIndex;

    _pageController = PageController(initialPage: widget.pageIndex);

    _screens = [
      const HomeScreen(),
      const FavouriteScreen(),
      const CartScreen(fromNav: true),
      const OrderScreen(),
      const MenuScreen()
    ];

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {});
    });

  }

  _showRegistrationSuccessBottomSheet() {
    bool canShowBottomSheet = Get.find<DashboardController>().getRegistrationSuccessfulSharedPref();
    if(canShowBottomSheet) {
      Future.delayed(const Duration(seconds: 1), () {
        ResponsiveHelper.isDesktop(Get.context) ? Get.dialog(const Dialog(child: RegistrationSuccessBottomSheet())).then((value) {
          Get.find<DashboardController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<DashboardController>().saveIsRestaurantRegistrationSharedPref(false);
          setState(() {});
        }) : showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const RegistrationSuccessBottomSheet(),
        ).then((value) {
          Get.find<DashboardController>().saveRegistrationSuccessfulSharedPref(false);
          Get.find<DashboardController>().saveIsRestaurantRegistrationSharedPref(false);
          setState(() {});
        });
      });
    }
  }

  Future<void> _suggestAddressBottomSheet() async {
    active = await Get.find<DashboardController>().checkLocationActive();
    if(widget.fromSplash && Get.find<DashboardController>().showLocationSuggestion && active){
      Future.delayed(const Duration(seconds: 1), () {
        showModalBottomSheet(
          context: Get.context!, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (con) => const AddressBottomSheet(),
        ).then((value) {
          Get.find<DashboardController>().hideSuggestedLocation();
          setState(() {});
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async{
        debugPrint('$_canExit');
        if (_pageIndex != 0) {
          _setPage(0);
        } else {
          if(_canExit) {
            if (GetPlatform.isAndroid) {
              SystemNavigator.pop();
            } else if (GetPlatform.isIOS) {
              exit(0);
            }
          }
          if(!ResponsiveHelper.isDesktop(context)) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('back_press_again_to_exit'.tr, style: const TextStyle(color: Colors.white)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
            ));
          }
          _canExit = true;

          Timer(const Duration(seconds: 2), () {
            _canExit = false;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,


        extendBody: true,
        bottomNavigationBar: ResponsiveHelper.isDesktop(context) ? const SizedBox() : GetBuilder<OrderController>(builder: (orderController) {

            return (orderController.showBottomSheet && (orderController.runningOrderList != null && orderController.runningOrderList!.isNotEmpty && _isLogin))
            ? const SizedBox() : Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 65,
                child: Row(
                children: [
                  BottomNavItem(
                    iconData: Icons.home,
                    label: 'Home',
                    isSelected: _pageIndex == 0,
                    onTap: (details) => _setPage(0, details.globalPosition),
                  ),
                  BottomNavItem(
                    iconData: Icons.favorite,
                    label: 'Favorites',
                    isSelected: _pageIndex == 1,
                    onTap: (details) => _setPage(1, details.globalPosition),
                  ),
                  BottomNavItem(
                    iconData: Icons.shopping_cart,
                    label: 'Cart',
                    isSelected: _pageIndex == 2,
                    onTap: (details) => _setPage(2, details.globalPosition),
                  ),
                  BottomNavItem(
                    iconData: Icons.shopping_bag,
                    label: 'Orders',
                    isSelected: _pageIndex == 3,
                    onTap: (details) => _setPage(3, details.globalPosition),
                  ),
                  BottomNavItem(
                    iconData: Icons.menu,
                    label: 'Menu',
                    isSelected: _pageIndex == 4,
                    onTap: (details) => _setPage(4, details.globalPosition),
                  ),
                ],
                ),
              ),
            );
          }
        ),
        body: GetBuilder<OrderController>(
          builder: (orderController) {
            List<OrderModel> runningOrder = orderController.runningOrderList != null ? orderController.runningOrderList! : [];

            List<OrderModel> reversOrder =  List.from(runningOrder.reversed);
            return ExpandableBottomSheet(
              background: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Previous screen
                      if (_previousPageIndex != _pageIndex)
                        _screens[_previousPageIndex],
                      // New screen with circular reveal
                      ClipPath(
                        clipper: CircularRevealClipper(
                          fraction: _animation.value,
                          centerOffset: _tapPosition,
                        ),
                        child: _screens[_pageIndex],
                      ),
                    ],
                  );
                },
              ),
              persistentContentHeight: 100,

              onIsContractedCallback: () {
                if(!orderController.showOneOrder) {
                  orderController.showOrders();
                }
              },
              onIsExtendedCallback: () {
                if(orderController.showOneOrder) {
                  orderController.showOrders();
                }
              },

              enableToggle: true,

              expandableContent: (ResponsiveHelper.isDesktop(context) || !_isLogin || orderController.runningOrderList == null
                  || orderController.runningOrderList!.isEmpty || !orderController.showBottomSheet) ? const SizedBox()
                  : Dismissible(
                    key: UniqueKey(),
                    onDismissed: (direction) {
                      if(orderController.showBottomSheet){
                        orderController.showRunningOrders();
                      }
                    },
                    child: RunningOrderViewWidget(reversOrder: reversOrder, onMoreClick: () {
                      if(orderController.showBottomSheet){
                        orderController.showRunningOrders();
                      }
                      _setPage(3);
                    }),
              ),

            );
          }
        ),
      ),
    );
  }

  void _setPage(int pageIndex, [Offset? tapPosition]) {
    if (pageIndex == _pageIndex) return;

    setState(() {
      _previousPageIndex = _pageIndex;
      _pageIndex = pageIndex;
      _tapPosition = tapPosition;
    });

    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
