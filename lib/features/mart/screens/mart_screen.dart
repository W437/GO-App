import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class MartScreen extends StatelessWidget {
  const MartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 80,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                'Hopa!mart',
                style: robotoBold.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                'Coming Soon',
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'We\'re working on something amazing!\nStay tuned for updates.',
                style: robotoRegular.copyWith(
                  color: Theme.of(context).disabledColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
