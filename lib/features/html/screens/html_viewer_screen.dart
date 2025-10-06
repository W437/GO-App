import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:godelivery_user/common/widgets/circular_back_button_widget.dart';
import 'package:godelivery_user/features/html/controllers/html_controller.dart';
import 'package:godelivery_user/features/html/enums/html_type.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_app_bar_widget.dart';
import 'package:godelivery_user/common/widgets/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/menu_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HtmlViewerScreen extends StatefulWidget {
  final HtmlType htmlType;
  const HtmlViewerScreen({super.key, required this.htmlType});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  final ScrollController scrollController = ScrollController();
  bool _isAboutUsLoading = true;
  static const String _aboutUsUrl = 'https://go-delivery.net';

  @override
  void initState() {
    super.initState();

    if(widget.htmlType != HtmlType.aboutUs) {
      Get.find<HtmlController>().getHtmlText(widget.htmlType);
    }
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAboutUs = widget.htmlType == HtmlType.aboutUs;
    return Scaffold(
      extendBodyBehindAppBar: isAboutUs,
      appBar: isAboutUs ? null : CustomAppBarWidget(title: widget.htmlType == HtmlType.termsAndCondition ? 'terms_conditions'.tr
          : widget.htmlType == HtmlType.aboutUs ? 'about_us'.tr : widget.htmlType == HtmlType.privacyPolicy
          ? 'privacy_policy'.tr :  widget.htmlType == HtmlType.shippingPolicy ? 'shipping_policy'.tr
          : widget.htmlType == HtmlType.refund ? 'refund_policy'.tr :  widget.htmlType == HtmlType.cancellation
          ? 'cancellation_policy'.tr  : 'no_data_found'.tr),
      endDrawer: isAboutUs ? null : const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: isAboutUs ? Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Dimensions.radiusExtraLarge),
                ),
                child: Container(
                  color: Theme.of(context).cardColor,
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_aboutUsUrl)),
                    initialSettings: InAppWebViewSettings(useHybridComposition: true),
                    onLoadStart: (_, __) {
                      if(mounted) {
                        setState(() {
                          _isAboutUsLoading = true;
                        });
                      }
                    },
                    onLoadStop: (_, __) async {
                      if(mounted) {
                        setState(() {
                          _isAboutUsLoading = false;
                        });
                      }
                    },
                    onProgressChanged: (_, progress) {
                      if(progress == 100 && mounted) {
                        setState(() {
                          _isAboutUsLoading = false;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          if(_isAboutUsLoading)
            Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
            ),
          Positioned(
            left: Dimensions.paddingSizeDefault,
            bottom: MediaQuery.of(context).padding.bottom + Dimensions.paddingSizeDefault,
            child: CircularBackButtonWidget(
              showText: true,
              onPressed: () => Navigator.pop(context),
              backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.8),
              iconColor: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ) : GetBuilder<HtmlController>(builder: (htmlController) {
        return htmlController.htmlText != null ? Center(
          child: Container(
            height: MediaQuery.of(context).size.height,
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault,
                vertical: ResponsiveHelper.isDesktop(context) ? 0 : Dimensions.paddingSizeDefault,
              ),
              child: FooterViewWidget(
                child: SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.isDesktop(context) ?  Dimensions.paddingSizeLarge : 0),
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [

                      ResponsiveHelper.isDesktop(context) ? Container(
                        height: 50, alignment: Alignment.center, color: Theme.of(context).cardColor, width: Dimensions.webMaxWidth,
                        child: SelectableText(widget.htmlType == HtmlType.termsAndCondition ? 'terms_conditions'.tr
                            : widget.htmlType == HtmlType.aboutUs ? 'about_us'.tr : widget.htmlType == HtmlType.privacyPolicy
                            ? 'privacy_policy'.tr : widget.htmlType == HtmlType.shippingPolicy ? 'shipping_policy'.tr
                            : widget.htmlType == HtmlType.refund ? 'refund_policy'.tr :  widget.htmlType == HtmlType.cancellation
                            ? 'cancellation_policy'.tr : 'no_data_found'.tr,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).hintColor),
                        ),
                      ) : const SizedBox(),

                      HtmlWidget(
                        htmlController.htmlText ?? '',
                        key: Key(widget.htmlType.toString()),
                        textStyle: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6)),
                        onTapUrl: (String url){
                          return launchUrlString(url);
                        },
                      ),

                    ]),
                  ),
                ),
              ),
            ),
          ),
        ) : Center(child: CircularProgressIndicator());
      }),
    );
  }
}
