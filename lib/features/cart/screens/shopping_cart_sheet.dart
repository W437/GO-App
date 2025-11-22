import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/shared/buttons/circular_back_button_widget.dart';
import 'package:godelivery_user/features/cart/controllers/cart_controller.dart';
import 'package:godelivery_user/features/cart/widgets/order_details_sheet.dart';
import 'package:godelivery_user/features/cart/widgets/order_again_view.dart';
import 'package:godelivery_user/features/cart/widgets/shopping_carts_view.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class ShoppingCartSheet extends StatefulWidget {
  final bool fromNav;
  final bool fromReorder;
  final bool fromDineIn;
  const ShoppingCartSheet({super.key, required this.fromNav, this.fromReorder = false, this.fromDineIn = false});

  @override
  State<ShoppingCartSheet> createState() => _ShoppingCartSheetState();
}

class _ShoppingCartSheetState extends State<ShoppingCartSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initCall();
  }

  Future<void> initCall() async {
    Get.find<RestaurantController>().makeEmptyRestaurant(willUpdate: false);
    Get.find<CartController>().setAvailableIndex(-1, willUpdate: false);
    Get.find<CheckoutController>().setInstruction(-1, willUpdate: false);
    await Get.find<CartController>().getCartDataOnline();

    // Fetch history for "Order again"
    Get.find<OrderController>().getHistoryOrders(1, notify: false);

    if(Get.find<CartController>().cartList.isNotEmpty){
      await Get.find<RestaurantController>().getRestaurantDetails(Restaurant(id: Get.find<CartController>().cartList[0].product!.restaurantId, name: null), fromCart: true);
      Get.find<CartController>().calculationCart();
      if(Get.find<CartController>().addCutlery){
        Get.find<CartController>().updateCutlery(isUpdate: false);
      }
      if(Get.find<CartController>().needExtraPackage){
        Get.find<CartController>().toggleExtraPackage(willUpdate: false);
      }
      Get.find<RestaurantController>().getCartRestaurantSuggestedItemList(Get.find<CartController>().cartList[0].product!.restaurantId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isDesktop ? CustomAppBarWidget(title: 'my_cart'.tr, isBackButtonExist: true) : null,
      endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button with down arrow to close sheet
                  widget.fromNav ? const SizedBox(width: 44) : CircularBackButtonWidget(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onPressed: () => Get.back(),
                  ),
                  Text(
                    'Your orders',
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                  ),
                  TextButton(
                    onPressed: () {
                      // Edit functionality placeholder
                    },
                    child: Text('Edit', style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
                  ),
                ],
              ),
            ),

            // Segmented Control
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              height: 45,
              decoration: BoxDecoration(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Theme.of(context).textTheme.bodyLarge!.color,
                unselectedLabelColor: Theme.of(context).disabledColor,
                labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: const [
                  Tab(text: 'Shopping carts'),
                  Tab(text: 'Order again'),
                ],
              ),
            ),
            
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Shopping Carts View
                  ShoppingCartsView(onViewCart: () {
                    // Open OrderDetailsSheet as a separate sheet on top
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (context) => Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: const OrderDetailsSheet(),
                      ),
                    );
                  }),
                  
                  const OrderAgainView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}