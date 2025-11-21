import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/features/dine_in/controllers/dine_in_controller.dart';
import 'package:godelivery_user/features/story/controllers/story_controller.dart';
import 'package:godelivery_user/features/story/widgets/story_strip_widget.dart';
import 'package:godelivery_user/features/home/controllers/advertisement_controller.dart';
import 'package:godelivery_user/features/home/widgets/cashback_dialog_widget.dart';
import 'package:godelivery_user/features/home/widgets/cashback_logo_widget.dart';
import 'package:godelivery_user/features/home/widgets/dine_in_widget.dart';
import 'package:godelivery_user/features/home/widgets/highlight_widget_view.dart';
import 'package:godelivery_user/features/home/widgets/refer_bottom_sheet_widget.dart';
import 'package:godelivery_user/features/product/controllers/campaign_controller.dart';
import 'package:godelivery_user/features/home/controllers/home_controller.dart';
import 'package:godelivery_user/features/home/screens/web_home_screen.dart';
import 'package:godelivery_user/features/home/widgets/all_restaurant_filter_widget.dart';
import 'package:godelivery_user/features/home/widgets/all_restaurants_widget.dart';
import 'package:godelivery_user/features/home/widgets/bad_weather_widget.dart';
import 'package:godelivery_user/features/home/widgets/banner_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/best_review_item_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/cuisine_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/categories_cuisines_tabbed_widget.dart';
import 'package:godelivery_user/features/home/widgets/enjoy_off_banner_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/location_banner_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/new_on_go_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/order_again_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/popular_foods_nearby_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/theme1/item_campaign_widget1.dart';
import 'package:godelivery_user/features/home/widgets/popular_restaurants_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/refer_banner_view_widget.dart';
import 'package:godelivery_user/features/home/screens/theme1_home_screen.dart';
import 'package:godelivery_user/features/home/screens/theme2_home_screen.dart';
import 'package:godelivery_user/features/home/widgets/simple_app_bar_widget.dart';
import 'package:godelivery_user/features/home/widgets/simple_search_location_widget.dart';
import 'package:godelivery_user/features/home/widgets/gradient_header_widget.dart';
import 'package:godelivery_user/features/home/widgets/sticky_header_delegate.dart';
import 'package:godelivery_user/features/home/widgets/header_content_widget.dart';
import 'package:godelivery_user/features/home/widgets/sticky_top_bar_widget.dart';
import 'package:godelivery_user/features/home/widgets/header_content_below_sticky.dart';
import 'package:godelivery_user/features/home/widgets/new_home_header_widget.dart';
import 'package:godelivery_user/features/home/widgets/location_bar_widget.dart';
import 'package:godelivery_user/features/home/widgets/custom_pull_refresh_widget.dart';
import 'package:godelivery_user/features/home/widgets/max_stretch_scroll_controller.dart';
import 'package:godelivery_user/features/home/widgets/today_trends_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/what_on_your_mind_view_widget.dart';
import 'package:godelivery_user/features/home/widgets/video_refresh_widget.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/order/controllers/order_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';
import 'package:godelivery_user/features/notification/controllers/notification_controller.dart';
import 'package:godelivery_user/features/profile/controllers/profile_controller.dart';
import 'package:godelivery_user/common/widgets/shared/layout/customizable_space_bar_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/splash/domain/models/config_model.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:godelivery_user/features/location/controllers/location_controller.dart';
import 'package:godelivery_user/features/product/controllers/product_controller.dart';
import 'package:godelivery_user/features/review/controllers/review_controller.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/helper/business_logic/address_helper.dart';
import 'package:godelivery_user/helper/business_logic/auth_helper.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/images.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  static Future<void> loadData(bool reload) async {
    print('🏠 [HOME] loadData called - reload: $reload');

    final splashController = Get.find<SplashController>();

    // Check if data was already loaded in splash screen
    if (!reload && splashController.dataLoadingComplete) {
      print('✅ [HOME] Data already loaded in splash - skipping load');
      // Data already loaded in splash, just verify and refresh stories/config in background
      splashController.refreshConfig(); // No await - background refresh
      Get.find<StoryController>().getStories(reload: false); // Background refresh
      return;
    }

    // User manually pulled to refresh OR data wasn't loaded in splash
    print('🔄 [HOME] Loading data - reload requested or splash data incomplete');

    // Refresh config (no await for faster perceived load)
    splashController.refreshConfig();

    Get.find<HomeController>().getBannerList(reload);
    Get.find<CategoryController>().getCategoryList(reload);
    Get.find<CuisineController>().getCuisineList();
    Get.find<AdvertisementController>().getAdvertisementList();
    Get.find<DineInController>().getDineInRestaurantList(1, reload);
    Get.find<StoryController>().getStories(reload: true); // Always fetch fresh stories from API
    Get.find<LocationController>().getZoneList();
    if(splashController.configModel!.popularRestaurant == 1) {
      Get.find<RestaurantController>().getPopularRestaurantList(reload, 'all', false);
    }
    Get.find<CampaignController>().getItemCampaignList(reload);
    if(splashController.configModel!.popularFood == 1) {
      Get.find<ProductController>().getPopularProductList(reload, 'all', false);
    }
    if(splashController.configModel!.newRestaurant == 1) {
      Get.find<RestaurantController>().getLatestRestaurantList(reload, 'all', false);
    }
    if(splashController.configModel!.mostReviewedFoods == 1) {
      Get.find<ReviewController>().getReviewedProductList(reload, 'all', false);
    }
    Get.find<RestaurantController>().getRestaurantList(1, reload);
    if(Get.find<AuthController>().isLoggedIn()) {
      await Get.find<ProfileController>().getUserInfo();
      Get.find<RestaurantController>().getRecentlyViewedRestaurantList(reload, 'all', false);
      Get.find<RestaurantController>().getOrderAgainRestaurantList(reload);
      Get.find<NotificationController>().getNotificationList(reload);
      Get.find<OrderController>().getRunningOrders(1, notify: false);
      Get.find<AddressController>().getAddressList();
      Get.find<HomeController>().getCashBackOfferList();
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {

  final MaxStretchScrollController _scrollController = MaxStretchScrollController(
    maxStretchExtent: SliverPullRefreshIndicator.maxStretchExtent,
  );
  final ConfigModel? _configModel = Get.find<SplashController>().configModel;
  bool _isLogin = false;
  double _scrollOffset = 0;

  @override
  bool get wantKeepAlive => true;

  double _headerExpandedHeight(BuildContext context) => 125;

  double _headerCollapsedHeight(BuildContext context) => 65;

  @override
  void initState() {
    super.initState();

    _isLogin = Get.find<AuthController>().isLoggedIn();

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    HomeScreen.loadData(false).then((value) {
      Get.find<SplashController>().getReferBottomSheetStatus();

      if((Get.find<ProfileController>().userInfoModel?.isValidForDiscount ?? false) && Get.find<SplashController>().showReferBottomSheet) {
        Future.delayed(const Duration(milliseconds: 500), () => _showReferBottomSheet());
      }

    });

  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showReferBottomSheet() {
    ResponsiveHelper.isDesktop(context) ? Get.dialog(Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      insetPadding: const EdgeInsets.all(22),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: const ReferBottomSheetWidget(),
    ),
      useSafeArea: false,
    ).then((value) => Get.find<SplashController>().saveReferBottomSheetStatus(false)) : showModalBottomSheet(
      isScrollControlled: true, useRootNavigator: true, context: Get.context!,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: const ReferBottomSheetWidget(),
        );
      },
    ).then((value) => Get.find<SplashController>().saveReferBottomSheetStatus(false));
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    double scrollPoint = 0.0;

    return GetBuilder<HomeController>(builder: (homeController) {
      return GetBuilder<LocalizationController>(builder: (localizationController) {
        Widget _buildStandardHomeLayout() {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  /// Sticky compact header with collapsing search bar
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: HomeLocationHeaderDelegate(
                      expandedHeight: _headerExpandedHeight(context),
                      collapsedHeight: _headerCollapsedHeight(context),
                      topPadding: MediaQuery.of(context).padding.top,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        width: Dimensions.webMaxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const StoryStripWidget(),
                            const BannerViewWidget(),
                            const BadWeatherWidget(),
                            const CategoriesCuisinesTabbedWidget(),
                            const ItemCampaignWidget1(),
                            const TodayTrendsViewWidget(),
                            const HighlightWidgetView(),
                            _isLogin ? const OrderAgainViewWidget() : const SizedBox(),
                            _configModel!.mostReviewedFoods == 1
                                ? const BestReviewItemViewWidget(isPopular: false)
                                : const SizedBox(),
                            _configModel.dineInOrderOption! ? DineInWidget() : const SizedBox(),
                            _configModel.popularRestaurant == 1
                                ? const PopularRestaurantsViewWidget()
                                : const SizedBox(),
                            const ReferBannerViewWidget(),
                            _isLogin
                                ? const PopularRestaurantsViewWidget(isRecentlyViewed: true)
                                : const SizedBox(),
                            _configModel.popularFood == 1
                                ? const PopularFoodNearbyViewWidget()
                                : const SizedBox(),
                            _configModel.newRestaurant == 1
                                ? const NewOnGOViewWidget(isLatest: true)
                                : const SizedBox(),
                            const PromotionalBannerViewWidget(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverDelegate(
                      height: 90,
                      child: const AllRestaurantFilterWidget(),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Center(
                      child: FooterViewWidget(
                        child: Padding(
                          padding: ResponsiveHelper.isDesktop(context)
                              ? EdgeInsets.zero
                              : EdgeInsets.only(
                                  bottom: 65 +
                                      MediaQuery.of(context).padding.bottom +
                                      Dimensions.paddingSizeDefault,
                                ),
                          child: AllRestaurantsWidget(scrollController: _scrollController),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SliverPullRefreshIndicator(
                scrollController: _scrollController,
                onRefresh: () async {
                  await HomeScreen.loadData(true);
                },
              ),
            ],
          );
        }

        Widget bodyContent;
        final SplashController splashController = Get.find<SplashController>();
        if (ResponsiveHelper.isDesktop(context)) {
          bodyContent = WebHomeScreen(scrollController: _scrollController);
        } else if (splashController.configModel!.theme == 3) {
          bodyContent = Theme2HomeScreen(scrollController: _scrollController);
        } else if (splashController.configModel!.theme == 2) {
          bodyContent = Theme1HomeScreen(scrollController: _scrollController);
        } else {
          bodyContent = _buildStandardHomeLayout();
        }

        return Scaffold(
          appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
          endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          extendBody: true,
          body: SafeArea(
            top: (Get.find<SplashController>().configModel!.theme == 2),
            bottom: false,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                overscroll: false, // Remove default white overscroll glow
              ),
              child: bodyContent,
            ),
          ),

          floatingActionButton: AuthHelper.isLoggedIn() && homeController.cashBackOfferList != null && homeController.cashBackOfferList!.isNotEmpty ?
          homeController.showFavButton ? Padding(
            padding: EdgeInsets.only(bottom: ResponsiveHelper.isDesktop(context) ? 50 : 0, right: ResponsiveHelper.isDesktop(context) ? 20 : 0),
            child: InkWell(
              onTap: () => Get.dialog(const CashBackDialogWidget()),
              child: const CashBackLogoWidget(),
            ),
          ) : null : null,

        );
      });
    });
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;

  SliverDelegate({required this.child, this.height = 50});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: height,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height || oldDelegate.minExtent != height || child != oldDelegate.child;
  }
}

class HomeLocationHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final double topPadding;

  HomeLocationHeaderDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.topPadding,
  });

  @override
  double get maxExtent => expandedHeight + topPadding;

  @override
  double get minExtent => collapsedHeight + topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final collapseRange = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final clampedOffset = shrinkOffset.clamp(0.0, collapseRange);
    final progress = (collapseRange == 0
            ? 0.0
            : (clampedOffset / collapseRange).clamp(0.0, 1.0))
        .toDouble();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: EdgeInsets.only(top: topPadding),
      child: Align(
        alignment: Alignment.topCenter,
        child: LocationBarWidget(collapseFactor: progress),
      ),
    );
  }

  @override
  bool shouldRebuild(HomeLocationHeaderDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        collapsedHeight != oldDelegate.collapsedHeight ||
        topPadding != oldDelegate.topPadding;
  }
}
