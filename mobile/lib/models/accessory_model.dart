import 'user_model.dart';

class AccessoryModel {
  final String id;
  final String name;
  final String category;
  final String condition;
  final double price;
  final String? description;
  final List<String> images;
  final String location;
  final String? brand;
  final String? compatibleModel;
  final bool isActive;
  final String status;
  final String approvalStatus;
  final String sellerId;
  final UserModel? seller;
  final String createdAt;

  const AccessoryModel({
    required this.id,
    required this.name,
    required this.category,
    required this.condition,
    required this.price,
    this.description,
    required this.images,
    required this.location,
    this.brand,
    this.compatibleModel,
    required this.isActive,
    required this.status,
    required this.approvalStatus,
    required this.sellerId,
    this.seller,
    required this.createdAt,
  });

  factory AccessoryModel.fromJson(Map<String, dynamic> json) => AccessoryModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        category: json['category'] ?? 'OTHER',
        condition: json['condition'] ?? '',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        description: json['description'],
        images: List<String>.from(json['images'] ?? []),
        location: json['location'] ?? '',
        brand: json['brand'],
        compatibleModel: json['compatibleModel'],
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
}

class AccessoryListResponse {
  final List<AccessoryModel> data;
  final int total;
  final int page;
  final int limit;

  const AccessoryListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory AccessoryListResponse.fromJson(Map<String, dynamic> json) =>
      AccessoryListResponse(
        data: (json['data'] as List? ?? [])
            .map((e) => AccessoryModel.fromJson(e))
            .toList(),
        total: json['total'] ?? 0,
        page: json['page'] ?? 1,
        limit: json['limit'] ?? 10,
      );
}
