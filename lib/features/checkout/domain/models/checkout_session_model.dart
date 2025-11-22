/// Model representing a checkout session for a specific restaurant cart
/// Manages all checkout-related state for a single restaurant order
class CheckoutSession {
  final int restaurantId;
  String mode; // 'delivery', 'take_away', 'dine_in'
  int? selectedAddressId;
  String timeOption; // 'standard', 'scheduled'
  DateTime? scheduledTime;
  double tipAmount;
  String? paymentMethod;
  bool leaveAtDoor;
  bool isGift;
  Map<String, String>? giftInfo; // {name, phone, message}
  String? orderNote; // Special instructions/message to restaurant

  CheckoutSession({
    required this.restaurantId,
    this.mode = 'delivery',
    this.selectedAddressId,
    this.timeOption = 'standard',
    this.scheduledTime,
    this.tipAmount = 0,
    this.paymentMethod,
    this.leaveAtDoor = false,
    this.isGift = false,
    this.giftInfo,
    this.orderNote,
  });

  /// Check if address is required based on mode
  bool get requiresAddress => mode == 'delivery';

  /// Check if session is ready for checkout
  bool get isReadyForCheckout {
    if (requiresAddress && selectedAddressId == null) {
      return false;
    }
    if (timeOption == 'scheduled' && scheduledTime == null) {
      return false;
    }
    if (isGift && (giftInfo == null || giftInfo!.isEmpty)) {
      return false;
    }
    return true;
  }

  /// Create a copy with updated fields
  CheckoutSession copyWith({
    int? restaurantId,
    String? mode,
    int? selectedAddressId,
    bool clearAddress = false,
    String? timeOption,
    DateTime? scheduledTime,
    bool clearScheduledTime = false,
    double? tipAmount,
    String? paymentMethod,
    bool? leaveAtDoor,
    bool? isGift,
    Map<String, String>? giftInfo,
    bool clearGiftInfo = false,
    String? orderNote,
    bool clearOrderNote = false,
  }) {
    return CheckoutSession(
      restaurantId: restaurantId ?? this.restaurantId,
      mode: mode ?? this.mode,
      selectedAddressId: clearAddress ? null : (selectedAddressId ?? this.selectedAddressId),
      timeOption: timeOption ?? this.timeOption,
      scheduledTime: clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
      tipAmount: tipAmount ?? this.tipAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      leaveAtDoor: leaveAtDoor ?? this.leaveAtDoor,
      isGift: isGift ?? this.isGift,
      giftInfo: clearGiftInfo ? null : (giftInfo ?? this.giftInfo),
      orderNote: clearOrderNote ? null : (orderNote ?? this.orderNote),
    );
  }

  /// Reset session to defaults
  CheckoutSession reset() {
    return CheckoutSession(
      restaurantId: restaurantId,
      mode: 'delivery',
      selectedAddressId: null,
      timeOption: 'standard',
      scheduledTime: null,
      tipAmount: 0,
      paymentMethod: null,
      leaveAtDoor: false,
      isGift: false,
      giftInfo: null,
      orderNote: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutSession &&
          runtimeType == other.runtimeType &&
          restaurantId == other.restaurantId;

  @override
  int get hashCode => restaurantId.hashCode;
}
