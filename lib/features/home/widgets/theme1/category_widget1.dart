import 'package:godelivery_user/features/home/widgets/category_pop_up_widget.dart';
import 'package:godelivery_user/features/category/controllers/category_controller.dart';
import 'package:godelivery_user/features/home/widgets/blurhash_image_widget.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/adaptive/navigation/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:get/get.dart';

class CategoryWidget1 extends StatelessWidget {
  const CategoryWidget1({super.key});

  @override
  Widget build(BuildContext context) {
    ScrollController scrollController = ScrollController();

    return GetBuilder<CategoryController>(builder: (categoryController) {
      return (categoryController.categoryList != null && categoryController.categoryList!.isEmpty) ? const SizedBox() : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: TitleWidget(title: 'categories'.tr, onTap: () => Get.toNamed(RouteHelper.getCategoryRoute())),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 65,
                  child: categoryController.categoryList != null ? ListView.builder(
                    controller: scrollController,
                    itemCount: categoryController.categoryList!.length > 15 ? 15 : categoryController.categoryList!.length,
                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: InkWell(
                          onTap: () => Get.toNamed(RouteHelper.getCategoryProductRoute(
                            categoryController.categoryList![index].id, categoryController.categoryList![index].name!,
                          )),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 75,
                            height: 65,
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : Dimensions.paddingSizeExtraSmall,
                              right: Dimensions.paddingSizeExtraSmall,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.isDarkMode
                                      ? Colors.black.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  BlurhashImageWidget(
                                    imageUrl: categoryController.categoryList![index].imageFullUrl ?? '',
                                    blurhash: categoryController.categoryList![index].imageBlurhash,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.7),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        categoryController.categoryList![index].name!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: robotoMedium.copyWith(
                                          fontSize: Dimensions.fontSizeExtraSmall,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ) : CategoryShimmer(categoryController: categoryController),
                ),
              ),

              ResponsiveHelper.isMobile(context) ? const SizedBox() : categoryController.categoryList != null ? Column(
                children: [
                  InkWell(
                    onTap: (){
                      showDialog(context: context, builder: (con) => Dialog(
                        child: SizedBox(height: 550, width: 600,
                          child: CategoryPopUpWidget(
                            categoryController: categoryController,
                          ),
                        ),
                      ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text('view_all'.tr, style: TextStyle(fontSize: Dimensions.paddingSizeDefault, color: Theme.of(context).cardColor)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10,)
                ],
              ): CategoryAllShimmer(categoryController: categoryController)
            ],
          ),

        ],
      );
    });
  }
}

class CategoryShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const CategoryShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      child: ListView.builder(
        itemCount: 14,
        padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: SizedBox(
              width: 75,
              child: Container(
                height: 65, width: 65,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : Dimensions.paddingSizeExtraSmall,
                  right: Dimensions.paddingSizeExtraSmall,
                ),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  enabled: categoryController.categoryList == null,
                  child: Container(
                    height: 65, width: 65,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CategoryAllShimmer extends StatelessWidget {
  final CategoryController categoryController;
  const CategoryAllShimmer({super.key, required this.categoryController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      child: Padding(
        padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
        child: Shimmer(
          duration: const Duration(seconds: 2),
          enabled: categoryController.categoryList == null,
          child: Column(children: [
            Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              ),
            ),
            const SizedBox(height: 5),
            Container(height: 10, width: 50, color: Colors.grey[300]),
          ]),
        ),
      ),
    );
  }
}

