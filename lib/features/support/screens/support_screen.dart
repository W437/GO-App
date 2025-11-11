import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/support/widgets/quick_action_button_widget.dart';
import 'package:godelivery_user/features/support/widgets/faq_item_widget.dart';
import 'package:godelivery_user/features/support/widgets/contact_list_item_widget.dart';
import 'package:godelivery_user/features/support/widgets/web_support_widget.dart';
import 'package:godelivery_user/helper/responsive_helper.dart';
import 'package:godelivery_user/helper/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/footer_view_widget.dart';
import 'package:godelivery_user/common/widgets/menu_drawer_widget.dart';
import 'package:godelivery_user/common/widgets/unified_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final ScrollController scrollController = ScrollController();

  // FAQ data - can be moved to a controller or fetched from backend
  final List<Map<String, String>> _faqs = [
    {
      'question': 'how_do_i_track_my_order',
      'answer': 'you_can_track_your_order_by_going_to_the_orders_section',
    },
    {
      'question': 'how_do_i_cancel_my_order',
      'answer': 'you_can_cancel_your_order_from_the_order_details_screen',
    },
    {
      'question': 'what_payment_methods_are_accepted',
      'answer': 'we_accept_various_payment_methods_including_credit_cards',
    },
    {
      'question': 'how_long_does_delivery_take',
      'answer': 'delivery_time_varies_based_on_your_location_and_restaurant',
    },
    {
      'question': 'can_i_change_my_delivery_address',
      'answer': 'you_can_change_your_delivery_address_before_order_confirmation',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context)
          ? null
          : UnifiedHeaderWidget(
              title: 'help_support'.tr,
              showBackButton: true,
              showBorder: true,
            ),
      endDrawer: const MenuDrawerWidget(),
      endDrawerEnableOpenDragGesture: false,
      body: Center(
        child: ResponsiveHelper.isDesktop(context)
            ? SingleChildScrollView(
                controller: scrollController,
                child: const FooterViewWidget(
                  child: SizedBox(
                    width: double.infinity,
                    height: 650,
                    child: WebSupportScreen(),
                  ),
                ),
              )
            : SizedBox(
                width: Dimensions.webMaxWidth,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        _buildSectionHeader(
                          context,
                          icon: Icons.support_agent,
                          title: 'how_can_we_help'.tr,
                          subtitle: 'choose_an_option_below_or_contact_us_directly'.tr,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // Quick Actions Section
                        _buildQuickActionsSection(context),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                        // Contact Us Section
                        _buildContactSection(context),
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                        // FAQ Section
                        _buildFaqSection(context),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            subtitle,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            title,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'quick_actions'.tr, Icons.flash_on),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Dimensions.paddingSizeDefault,
          crossAxisSpacing: Dimensions.paddingSizeDefault,
          childAspectRatio: 1.1,
          children: [
            QuickActionButtonWidget(
              icon: Icons.chat_bubble_outline,
              title: 'live_chat'.tr,
              onTap: () {
                Get.toNamed(RouteHelper.getConversationRoute());
              },
            ),
            QuickActionButtonWidget(
              icon: Icons.local_shipping_outlined,
              title: 'track_order'.tr,
              iconColor: Colors.orange,
              onTap: () {
                Get.toNamed(RouteHelper.getOrderRoute());
              },
            ),
            QuickActionButtonWidget(
              icon: Icons.report_problem_outlined,
              title: 'report_issue'.tr,
              iconColor: Colors.red,
              onTap: () {
                // Navigate to report issue or open email
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: Get.find<SplashController>().configModel!.email,
                  queryParameters: {'subject': 'Issue Report'},
                );
                launchUrlString(
                  emailLaunchUri.toString(),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            QuickActionButtonWidget(
              icon: Icons.help_outline,
              title: 'view_faqs'.tr,
              iconColor: Colors.green,
              onTap: () {
                // Scroll to FAQ section
                scrollController.animateTo(
                  scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    final config = Get.find<SplashController>().configModel!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'contact_us'.tr, Icons.contacts_outlined),
        ContactListItemWidget(
          icon: Icons.phone_outlined,
          title: 'call'.tr,
          subtitle: config.phone ?? '',
          iconColor: Colors.green,
          onTap: () async {
            if (await canLaunchUrlString('tel:${config.phone}')) {
              launchUrlString(
                'tel:${config.phone}',
                mode: LaunchMode.externalApplication,
              );
            } else {
              showCustomSnackBar('${'can_not_launch'.tr} ${config.phone}');
            }
          },
        ),
        ContactListItemWidget(
          icon: Icons.email_outlined,
          title: 'email_us'.tr,
          subtitle: config.email ?? '',
          iconColor: Colors.blue,
          onTap: () {
            final Uri emailLaunchUri = Uri(
              scheme: 'mailto',
              path: config.email,
            );
            launchUrlString(
              emailLaunchUri.toString(),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        ContactListItemWidget(
          icon: Icons.location_on_outlined,
          title: 'address'.tr,
          subtitle: config.address ?? '',
          iconColor: Colors.red,
          showChevron: true,
          onTap: () async {
            // Open in maps
            final address = Uri.encodeComponent(config.address ?? '');
            final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$address';
            if (await canLaunchUrlString(mapsUrl)) {
              launchUrlString(mapsUrl, mode: LaunchMode.externalApplication);
            } else {
              showCustomSnackBar('can_not_launch'.tr);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          'frequently_asked_questions'.tr,
          Icons.quiz_outlined,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _faqs.length,
          itemBuilder: (context, index) {
            final faq = _faqs[index];
            return FaqItemWidget(
              question: faq['question']!.tr,
              answer: faq['answer']!.tr,
              initiallyExpanded: index == 0,
            );
          },
        ),
      ],
    );
  }
}
