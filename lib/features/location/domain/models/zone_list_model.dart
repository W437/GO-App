class ZoneListModel {
  int? id;
  String? name;
  String? displayName;
  ZoneCoordinates? coordinates;
  int? status;
  String? createdAt;
  String? updatedAt;
  String? restaurantWiseTopic;
  String? customerWiseTopic;
  String? deliverymanWiseTopic;
  double? minimumShippingCharge;
  double? perKmShippingCharge;
  double? maximumShippingCharge;
  double? maxCodOrderAmount;
  double? increasedDeliveryFee;
  int? increasedDeliveryFeeStatus;
  String? increaseDeliveryChargeMessage;
  List<FormattedCoordinates>? formattedCoordinates;
  List<ZoneTranslation>? translations;

  ZoneListModel({
    this.id,
    this.name,
    this.displayName,
    this.coordinates,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.restaurantWiseTopic,
    this.customerWiseTopic,
    this.deliverymanWiseTopic,
    this.minimumShippingCharge,
    this.perKmShippingCharge,
    this.maximumShippingCharge,
    this.maxCodOrderAmount,
    this.increasedDeliveryFee,
    this.increasedDeliveryFeeStatus,
    this.increaseDeliveryChargeMessage,
    this.formattedCoordinates,
    this.translations,
  });

  ZoneListModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    displayName = json['display_name'];
    coordinates = json['coordinates'] != null ? ZoneCoordinates.fromJson(json['coordinates']) : null;
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    restaurantWiseTopic = json['restaurant_wise_topic'];
    customerWiseTopic = json['customer_wise_topic'];
    deliverymanWiseTopic = json['deliveryman_wise_topic'];
    minimumShippingCharge = json['minimum_shipping_charge']?.toDouble();
    perKmShippingCharge = json['per_km_shipping_charge']?.toDouble();
    maximumShippingCharge = json['maximum_shipping_charge']?.toDouble();
    maxCodOrderAmount = json['max_cod_order_amount']?.toDouble();
    increasedDeliveryFee = json['increased_delivery_fee']?.toDouble();
    increasedDeliveryFeeStatus = json['increased_delivery_fee_status'];
    increaseDeliveryChargeMessage = json['increase_delivery_charge_message'];

    if (json['formated_coordinates'] != null) {
      formattedCoordinates = <FormattedCoordinates>[];
      json['formated_coordinates'].forEach((v) {
        formattedCoordinates!.add(FormattedCoordinates.fromJson(v));
      });
    }

    if (json['translations'] != null) {
      translations = <ZoneTranslation>[];
      json['translations'].forEach((v) {
        translations!.add(ZoneTranslation.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['display_name'] = displayName;
    if (coordinates != null) {
      data['coordinates'] = coordinates!.toJson();
    }
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['restaurant_wise_topic'] = restaurantWiseTopic;
    data['customer_wise_topic'] = customerWiseTopic;
    data['deliveryman_wise_topic'] = deliverymanWiseTopic;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['maximum_shipping_charge'] = maximumShippingCharge;
    data['max_cod_order_amount'] = maxCodOrderAmount;
    data['increased_delivery_fee'] = increasedDeliveryFee;
    data['increased_delivery_fee_status'] = increasedDeliveryFeeStatus;
    data['increase_delivery_charge_message'] = increaseDeliveryChargeMessage;

    if (formattedCoordinates != null) {
      data['formated_coordinates'] = formattedCoordinates!.map((v) => v.toJson()).toList();
    }

    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }

    return data;
  }

  String get shippingInfo {
    String info = 'Min: \$${minimumShippingCharge?.toStringAsFixed(0)} • \$${perKmShippingCharge?.toStringAsFixed(0)}/km';
    if (maximumShippingCharge != null) {
      info += ' • Max: \$${maximumShippingCharge?.toStringAsFixed(0)}';
    }
    return info;
  }
}

class ZoneCoordinates {
  String? type;
  List<List<List<double>>>? coordinates;

  ZoneCoordinates({this.type, this.coordinates});

  ZoneCoordinates.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    if (json['coordinates'] != null) {
      coordinates = <List<List<double>>>[];
      json['coordinates'].forEach((v) {
        List<List<double>> coordGroup = <List<double>>[];
        v.forEach((coord) {
          coordGroup.add(List<double>.from(coord));
        });
        coordinates!.add(coordGroup);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    if (coordinates != null) {
      data['coordinates'] = coordinates;
    }
    return data;
  }
}

class FormattedCoordinates {
  double? lat;
  double? lng;

  FormattedCoordinates({this.lat, this.lng});

  FormattedCoordinates.fromJson(Map<String, dynamic> json) {
    lat = json['lat']?.toDouble();
    lng = json['lng']?.toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}

class ZoneTranslation {
  int? id;
  String? translatableType;
  int? translatableId;
  String? locale;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  ZoneTranslation({
    this.id,
    this.translatableType,
    this.translatableId,
    this.locale,
    this.key,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  ZoneTranslation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    translatableType = json['translationable_type'];
    translatableId = json['translationable_id'];
    locale = json['locale'];
    key = json['key'];
    value = json['value'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translationable_type'] = translatableType;
    data['translationable_id'] = translatableId;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}