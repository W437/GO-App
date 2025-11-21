import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/models/restaurant_model.dart';
import 'package:godelivery_user/features/address/controllers/address_controller.dart';
import 'package:godelivery_user/features/address/domain/models/address_model.dart';
import 'package:godelivery_user/features/auth/controllers/auth_controller.dart';
import 'package:godelivery_user/helper/navigation/route_helper.dart';
import 'package:godelivery_user/helper/converters/date_converter.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:godelivery_user/features/checkout/controllers/checkout_controller.dart';
import 'package:godelivery_user/features/restaurant/controllers/restaurant_controller.dart';

/// Bottom sheet surfaced from restaurant details to let users pick
/// delivery/pickup, address, and scheduled time before ordering.
class OrderDetailsBottomSheet extends StatefulWidget {
  final Restaurant restaurant;
  const OrderDetailsBottomSheet({super.key, required this.restaurant});

  @override
  State<OrderDetailsBottomSheet> createState() => _OrderDetailsBottomSheetState();
}

class _OrderDetailsBottomSheetState extends State<OrderDetailsBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedAddressIndex = 0;
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedAddressIndex = Get.find<CheckoutController>().addressIndex;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openSchedulePicker() async {
    if (!(widget.restaurant.scheduleOrder ?? false)) {
      Get.snackbar('',
          'Scheduling is not available for this restaurant',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
          colorText: Colors.redAccent);
      return;
    }
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SchedulePickerSheet(restaurant: widget.restaurant),
    );
    if (picked != null) {
      setState(() {
        _isScheduled = true;
        _scheduledDateTime = picked;
      });
    }
  }

  void _onConfirm() {
    final checkoutController = Get.find<CheckoutController>();
    final orderType = _tabController.index == 0 ? 'delivery' : 'take_away';

    if (orderType == 'delivery' &&
        (Get.find<AddressController>().addressList == null ||
            Get.find<AddressController>().addressList!.isEmpty)) {
      Get.snackbar('', 'Please add a delivery address first',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    checkoutController.setOrderType(orderType);
    if (orderType == 'delivery') {
      checkoutController.setAddressIndex(_selectedAddressIndex);
    }
    checkoutController.setPreselectedScheduleAt(_isScheduled ? _scheduledDateTime : null);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: context.width,
      constraints: BoxConstraints(maxHeight: context.height * 0.9),
      margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Container(
                height: 4,
                width: 45,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order details', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Delivery'),
                Tab(text: 'Pickup'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDeliveryTab(isDesktop),
                  _buildPickupTab(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                    child: Text('Confirm', style: robotoBold.copyWith(color: Theme.of(context).cardColor)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTab(bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where?', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _buildAddressSelector(),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _buildWhenSection(showAddress: true),
        ],
      ),
    );
  }

  Widget _buildPickupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWhenSection(showAddress: false),
        ],
      ),
    );
  }

  Widget _buildAddressSelector() {
    return GetBuilder<AddressController>(builder: (addressController) {
      final addresses = addressController.addressList ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addresses.isEmpty)
            OutlinedButton(
              onPressed: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, null)),
              child: Text('Add delivery address', style: robotoMedium),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: addresses.length,
              itemBuilder: (_, index) {
                final AddressModel address = addresses[index];
                return RadioListTile<int>(
                  value: index,
                  groupValue: _selectedAddressIndex,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedAddressIndex = val);
                    }
                  },
                  title: Text(address.address ?? '', style: robotoMedium),
                  subtitle: Text(address.contactPersonNumber ?? '', style: robotoRegular.copyWith(color: Theme.of(context).hintColor)),
                );
              },
            ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          TextButton.icon(
            onPressed: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, null)),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text('Add new address', style: robotoMedium),
          ),
        ],
      );
    });
  }

  Widget _buildWhenSection({required bool showAddress}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When?', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Wrap(
          spacing: Dimensions.paddingSizeSmall,
          children: [
            ChoiceChip(
              label: const Text('Normal'),
              selected: !_isScheduled,
              onSelected: (_) {
                setState(() {
                  _isScheduled = false;
                  _scheduledDateTime = null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Schedule'),
              selected: _isScheduled,
              onSelected: (_) => _openSchedulePicker(),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        if (_isScheduled && _scheduledDateTime != null)
          Row(
            children: [
              const Icon(Icons.schedule),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                '${DateConverter.onlyDate(_scheduledDateTime!)} at ${DateConverter.dateToTimeOnly(_scheduledDateTime!)}',
                style: robotoMedium,
              ),
            ],
          ),
      ],
    );
  }
}

class _SchedulePickerSheet extends StatefulWidget {
  final Restaurant restaurant;
  const _SchedulePickerSheet({required this.restaurant});

  @override
  State<_SchedulePickerSheet> createState() => _SchedulePickerSheetState();
}

class _SchedulePickerSheetState extends State<_SchedulePickerSheet> {
  int _selectedDayIndex = 0;
  int _selectedTimeIndex = 0;
  late List<DateTime> _days;
  late List<List<DateTime>> _timeSlotsPerDay;

  @override
  void initState() {
    super.initState();
    _days = _buildNextDays();
    _timeSlotsPerDay = _days.map((d) => _buildSlotsForDate(d)).toList();
    _normalizeSelection();
  }

  void _normalizeSelection() {
    // Ensure there is an available time slot for the selected day
    if (_timeSlotsPerDay[_selectedDayIndex].isEmpty) {
      final idx = _timeSlotsPerDay.indexWhere((list) => list.isNotEmpty);
      if (idx != -1) {
        _selectedDayIndex = idx;
      }
    }
    if (_timeSlotsPerDay[_selectedDayIndex].isNotEmpty) {
      _selectedTimeIndex = 0;
    }
  }

  List<DateTime> _buildNextDays() {
    final now = DateTime.now();
    final List<DateTime> days = [];
    for (int i = 0; i < 4; i++) {
      days.add(DateTime(now.year, now.month, now.day).add(Duration(days: i)));
    }
    return days;
  }

  List<DateTime> _buildSlotsForDate(DateTime date) {
    final restaurantController = Get.find<RestaurantController>();
    if (restaurantController.isRestaurantClosed(date, widget.restaurant.active!, widget.restaurant.schedules)) {
      return [];
    }

    final int weekdayZeroBased = date.weekday % 7; // Sunday -> 0
    final schedules = widget.restaurant.schedules?.where((s) => s.day == weekdayZeroBased).toList() ?? [];
    if (schedules.isEmpty) return [];

    final now = DateTime.now();
    final List<DateTime> slots = [];

    for (final schedule in schedules) {
      final openTime = DateConverter.convertStringTimeToDate(schedule.openingTime!);
      final closeTime = DateConverter.convertStringTimeToDate(schedule.closingTime!);
      DateTime cursor = DateTime(date.year, date.month, date.day, openTime.hour, openTime.minute);
      final end = DateTime(date.year, date.month, date.day, closeTime.hour, closeTime.minute);

      if (date.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
        final roundedNow = _roundUpToNearestTen(now);
        if (roundedNow.isAfter(cursor)) {
          cursor = roundedNow;
        }
      }

      while (cursor.isBefore(end) || cursor.isAtSameMomentAs(end)) {
        slots.add(cursor);
        cursor = cursor.add(const Duration(minutes: 10));
      }
    }

    return slots;
  }

  DateTime _roundUpToNearestTen(DateTime time) {
    final minutesToAdd = (10 - time.minute % 10) % 10;
    final adjusted = time.add(Duration(minutes: minutesToAdd == 0 ? 10 : minutesToAdd));
    return DateTime(adjusted.year, adjusted.month, adjusted.day, adjusted.hour, adjusted.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      constraints: BoxConstraints(maxHeight: context.height * 0.85),
      margin: EdgeInsets.only(top: GetPlatform.isWeb ? 0 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Dimensions.radiusExtraLarge)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Text('Select date & time', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            ),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: ListView.builder(
                      itemCount: _days.length,
                      itemBuilder: (_, index) {
                        final day = _days[index];
                        final hasSlots = _timeSlotsPerDay[index].isNotEmpty;
                        return ListTile(
                          onTap: hasSlots
                              ? () {
                                  setState(() {
                                    _selectedDayIndex = index;
                                    _selectedTimeIndex = 0;
                                  });
                                }
                              : null,
                          selected: _selectedDayIndex == index,
                          title: Text(
                            DateConverter.onlyDate(day),
                            style: robotoMedium.copyWith(
                              color: hasSlots ? null : Theme.of(context).disabledColor,
                            ),
                          ),
                          subtitle: Text(
                            hasSlots ? '${_timeSlotsPerDay[index].length} slots' : 'Closed',
                            style: robotoRegular.copyWith(
                              color: hasSlots ? Theme.of(context).hintColor : Theme.of(context).disabledColor,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: _timeSlotsPerDay[_selectedDayIndex].isEmpty
                        ? Center(
                            child: Text('No available slots', style: robotoMedium),
                          )
                        : ListView.builder(
                            itemCount: _timeSlotsPerDay[_selectedDayIndex].length,
                            itemBuilder: (_, index) {
                              final slot = _timeSlotsPerDay[_selectedDayIndex][index];
                              return RadioListTile<int>(
                                value: index,
                                groupValue: _selectedTimeIndex,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedTimeIndex = val);
                                  }
                                },
                                title: Text(DateConverter.dateToTime(slot), style: robotoMedium),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _timeSlotsPerDay[_selectedDayIndex].isEmpty
                      ? null
                      : () {
                          final selectedSlot = _timeSlotsPerDay[_selectedDayIndex][_selectedTimeIndex];
                          Navigator.of(context).pop(selectedSlot);
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                    child: Text('Set schedule', style: robotoBold.copyWith(color: Theme.of(context).cardColor)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
