import 'package:godelivery_user/common/widgets/web_screen_title_widget.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/features/favourite/controllers/favourite_controller.dart';
import 'package:godelivery_user/features/favourite/widgets/fav_item_view_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/unified_header_widget.dart';
import 'package:godelivery_user/common/widgets/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/not_logged_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  FavouriteScreenState createState() => FavouriteScreenState();
}

class FavouriteScreenState extends State<FavouriteScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    _initCall();
  }

  void _initCall(){
    if(Get.find<AuthController>().isLoggedIn()) {
      Get.find<FavouriteController>().getFavouriteList(fromFavScreen: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UnifiedHeaderWidget(
        title: 'favourite'.tr,
        showBackButton: true,
        showBorder: true,
      ),
      endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
      body: Get.find<AuthController>().isLoggedIn() ? SafeArea(child: Column(children: [

        WebScreenTitleWidget(title: 'favourite'.tr),

        Container(
          width: Dimensions.webMaxWidth,
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).disabledColor,
            unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
            labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
            tabs: [
              Tab(text: 'food'.tr),
              Tab(text: 'restaurants'.tr),
            ],
          ),
        ),

        Expanded(child: TabBarView(
          controller: _tabController,
          children: const [
            FavItemViewWidget(isRestaurant: false),
            FavItemViewWidget(isRestaurant: true),
          ],
        )),

      ])) : NotLoggedInScreen(callBack: (value){
        _initCall();
        setState(() {});
      }),
    );
  }
}
