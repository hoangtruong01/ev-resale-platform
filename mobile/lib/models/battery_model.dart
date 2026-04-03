import 'user_model.dart';

class BatteryModel {
  final String id;
  final String name;
  final String type;
  final double capacity; // kWh
  final double? voltage;
  final int condition; // 0-100
  final double price;
  final String? description;
  final List<String> images;
  final String location;
  final bool isActive;
  final String status;
  final String approvalStatus;
  final String sellerId;
  final UserModel? seller;
  final String createdAt;
  final String updatedAt;

  const BatteryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    this.voltage,
    required this.condition,
    required this.price,
    this.description,
    required this.images,
    required this.location,
    required this.isActive,
    required this.status,
    required this.approvalStatus,
    required this.sellerId,
    this.seller,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BatteryModel.fromJson(Map<String, dynamic> json) => BatteryModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? 'LITHIUM_ION',
        capacity: double.tryParse(json['capacity']?.toString() ?? '0') ?? 0,
        voltage: json['voltage'] != null
            ? double.tryParse(json['voltage'].toString())
            : null,
        condition: json['condition'] ?? 0,
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        description: json['description'],
        images: List<String>.from(json['images'] ?? []),
        location: json['location'] ?? '',
        isActive: json['isActive'] ?? true,
        status: json['status'] ?? 'AVAILABLE',
        approvalStatus: json['approvalStatus'] ?? 'PENDING',
        sellerId: json['sellerId'] ?? '',
        seller: json['seller'] != null
            ? UserModel.fromJson(json['seller'])
            : null,
        createdAt: json['createdAt'] ?? '',
        updatedAt: json['updatedAt'] ?? '',
      );

  String get typeLabel {
    const labels = {
      'LITHIUM_ION': 'Lithium-Ion',
      'LITHIUM_POLYMER': 'Lithium Polymer',
      'NICKEL_METAL_HYDRIDE': 'NiMH',
      'LEAD_ACID': 'Chì-Axit',
    };
    return labels[type] ?? type;
  }

  String get statusLabel {
    const labels = {
      'AVAILABLE': 'Còn hàng',
      'SOLD': 'Đã bán',
      'AUCTION': 'Đấu giá',
      'RESERVED': 'Đã đặt cọc',
    };
    return labels[status] ?? status;
  }

  bool get isAvailable => status == 'AVAILABLE' && isActive;
  String? get thumbnailUrl => images.isNotEmpty ? images.first : null;
}

class BatteryListResponse {
  final List<BatteryModel> data;
  final int total;
  final int page;
  final int limit;

  const BatteryListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory BatteryListResponse.fromJson(Map<String, dynamic> json) =>
      BatteryListResponse(
        data: (json['data'] as List? ?? [])
            .map((e) => BatteryModel.fromJson(e))
            .toList(),
        total: json['total'] ?? 0,
        page: json['page'] ?? 1,
        limit: json['limit'] ?? 10,
      );

  bool get hasMore => data.length < total;
}
