import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/features/support/widgets/quick_action_button_widget.dart';
import 'package:godelivery_user/features/support/widgets/faq_item_widget.dart';
import 'package:godelivery_user/features/support/widgets/contact_list_item_widget.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_snackbar_widget.dart';
import 'package:godelivery_user/common/widgets/web/web_page_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WebSupportScreen extends StatefulWidget {
  const WebSupportScreen({super.key});

  @override
  State<WebSupportScreen> createState() => _WebSupportScreenState();
}

class _WebSupportScreenState extends State<WebSupportScreen> {
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
    return SizedBox(
      width: Dimensions.webMaxWidth,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            WebScreenTitleWidget(title: 'help_support'.tr),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
              child: _buildSectionHeader(
                context,
                icon: Icons.support_agent,
                title: 'how_can_we_help'.tr,
                subtitle: 'choose_an_option_below_or_contact_us_directly'.tr,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            // Quick Actions and Contact in Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Section (50%)
                  Expanded(
                    flex: 1,
                    child: _buildQuickActionsSection(context),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraLarge),

                  // Contact Section (50%)
                  Expanded(
                    flex: 1,
                    child: _buildContactSection(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            // FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
              child: _buildFaqSection(context),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Text(
              title,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeOverLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: robotoRegular.copyWith(
              fontSize: Dimensions.fontSizeLarge,
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
            size: 24,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Text(
            title,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
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
          childAspectRatio: 1.2,
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
