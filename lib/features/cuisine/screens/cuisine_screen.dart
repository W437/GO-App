import 'package:godelivery_user/features/home/widgets/cuisine_card_widget.dart';
import 'package:godelivery_user/features/cuisine/controllers/cuisine_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/mobile/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_page_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CuisineScreen extends StatefulWidget {
  const CuisineScreen({super.key});

  @override
  State<CuisineScreen> createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  final ScrollController scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    Get.find<CuisineController>().getCuisineList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: 'cuisines'.tr),
      backgroundColor: Theme.of(context).colorScheme.surface,
      endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(children: [

          SizedBox(height: ResponsiveHelper.isDesktop(context) ? 0: Dimensions.paddingSizeLarge),
          WebScreenTitleWidget(title: 'cuisines'.tr),

          Center(child: FooterViewWidget(
            child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Column(children: [
                RefreshIndicator(
                  onRefresh: () async {
                    await Get.find<CuisineController>().getCuisineList();
                  },
                  child: Padding(
                    padding: EdgeInsets.only(left: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault, right: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault),
                    child: GetBuilder<CuisineController>(builder: (cuisineController) {
                      return cuisineController.cuisineModel != null ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ResponsiveHelper.isMobile(context) ? 4 : ResponsiveHelper.isDesktop(context) ? 8 : 6,
                          mainAxisSpacing: Dimensions.paddingSizeDefault,
                          crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? 35 : Dimensions.paddingSizeDefault,
                          childAspectRatio: ResponsiveHelper.isDesktop(context)
                              ? 0.95
                              : ResponsiveHelper.isTab(context)
                                  ? 0.8
                                  : 0.65,
                        ),
                        shrinkWrap: true,
                        itemCount: cuisineController.cuisineModel!.cuisines!.length,
                        scrollDirection: Axis.vertical,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index){
                          return InkWell(
                            hoverColor: Colors.transparent,
                            onTap: (){
                              Get.toNamed(RouteHelper.getCuisineRestaurantRoute(cuisineController.cuisineModel!.cuisines![index].id, cuisineController.cuisineModel!.cuisines![index].name));
                            },
                            child: SizedBox(
                              height: 130,
                              child: CuisineCardWidget(
                                image: '${cuisineController.cuisineModel!.cuisines![index].imageFullUrl}',
                                name: cuisineController.cuisineModel!.cuisines![index].name!,
                                fromCuisinesPage: true,
                              ),
                            ),
                          );
                        }) : const Center(child: CircularProgressIndicator());
                    }),
                  ),
                ),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}
