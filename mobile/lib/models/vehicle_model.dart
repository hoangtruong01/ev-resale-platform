import 'user_model.dart';

class VehicleModel {
  final String id;
  final String name;
  final String brand;
  final String model;
  final int year;
  final double price;
  final int? mileage;
  final String condition;
  final String? description;
  final List<String> images;
  final String location;
  final String? color;
  final String? transmission;
  final int? seatCount;
  final bool? hasWarranty;
  final bool isActive;
  final String status;
  final String approvalStatus;
  final String sellerId;
  final UserModel? seller;
  final String createdAt;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    this.mileage,
    required this.condition,
    this.description,
    required this.images,
    required this.location,
    this.color,
    this.transmission,
    this.seatCount,
    this.hasWarranty,
    required this.isActive,
    required this.status,
    required this.approvalStatus,
    required this.sellerId,
    this.seller,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        brand: json['brand'] ?? '',
        model: json['model'] ?? '',
        year: json['year'] ?? 0,
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        mileage: json['mileage'],
        condition: json['condition'] ?? '',
        description: json['description'],
        images: List<String>.from(json['images'] ?? []),
        location: json['location'] ?? '',
        color: json['color'],
        transmission: json['transmission'],
        seatCount: json['seatCount'],
        hasWarranty: json['hasWarranty'],
        isActive: json['isActive'] ?? true,
        status: json['status'] ?? 'AVAILABLE',
        approvalStatus: json['approvalStatus'] ?? 'PENDING',
        sellerId: json['sellerId'] ?? '',
        seller: json['seller'] != null
            ? UserModel.fromJson(json['seller'])
            : null,
        createdAt: json['createdAt'] ?? '',
      );

  String? get thumbnailUrl => images.isNotEmpty ? images.first : null;
  bool get isAvailable => status == 'AVAILABLE' && isActive;

  String get statusLabel {
    const labels = {
      'AVAILABLE': 'Còn hàng',
      'SOLD': 'Đã bán',
      'AUCTION': 'Đấu giá',
      'RESERVED': 'Đã đặt cọc',
    };
    return labels[status] ?? status;
  }
}

class VehicleListResponse {
  final List<VehicleModel> data;
  final int total;
  final int page;
  final int limit;

  const VehicleListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory VehicleListResponse.fromJson(Map<String, dynamic> json) =>
      VehicleListResponse(
        data: (json['data'] as List? ?? [])
            .map((e) => VehicleModel.fromJson(e))
            .toList(),
        total: json['total'] ?? 0,
        page: json['page'] ?? 1,
        limit: json['limit'] ?? 10,
      );
}
