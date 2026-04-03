import 'user_model.dart';

class AuctionModel {
  final String id;
  final String title;
  final String? description;
  final String itemType;
  final int lotQuantity;
  final String? itemBrand;
  final String? itemModel;
  final int? itemYear;
  final int? itemCapacity;
  final int? itemCondition;
  final String? location;
  final String? contactPhone;
  final double? buyNowPrice;
  final double startingPrice;
  final double currentPrice;
  final double bidStep;
  final String startTime;
  final String endTime;
  final String status;
  final String approvalStatus;
  final String sellerId;
  final UserModel? seller;
  final List<AuctionMedia> media;
  final int? bidCount;
  final String createdAt;

  const AuctionModel({
    required this.id,
    required this.title,
    this.description,
    required this.itemType,
    required this.lotQuantity,
    this.itemBrand,
    this.itemModel,
    this.itemYear,
    this.itemCapacity,
    this.itemCondition,
    this.location,
    this.contactPhone,
    this.buyNowPrice,
    required this.startingPrice,
    required this.currentPrice,
    required this.bidStep,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.approvalStatus,
    required this.sellerId,
    this.seller,
    required this.media,
    this.bidCount,
    required this.createdAt,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) => AuctionModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'],
        itemType: json['itemType'] ?? 'OTHER',
        lotQuantity: json['lotQuantity'] ?? 1,
        itemBrand: json['itemBrand'],
        itemModel: json['itemModel'],
        itemYear: json['itemYear'],
        itemCapacity: json['itemCapacity'],
        itemCondition: json['itemCondition'],
        location: json['location'],
        contactPhone: json['contactPhone'],
        buyNowPrice: json['buyNowPrice'] != null
            ? double.tryParse(json['buyNowPrice'].toString())
            : null,
        startingPrice:
            double.tryParse(json['startingPrice']?.toString() ?? '0') ?? 0,
        currentPrice:
            double.tryParse(json['currentPrice']?.toString() ?? '0') ?? 0,
        bidStep: double.tryParse(json['bidStep']?.toString() ?? '1000000') ??
            1000000,
        startTime: json['startTime'] ?? '',
        endTime: json['endTime'] ?? '',
        status: json['status'] ?? 'PENDING',
        approvalStatus: json['approvalStatus'] ?? 'PENDING',
        sellerId: json['sellerId'] ?? '',
        seller: json['seller'] != null
            ? UserModel.fromJson(json['seller'])
            : null,
        media: (json['media'] as List? ?? [])
            .map((e) => AuctionMedia.fromJson(e))
            .toList(),
        bidCount: json['_count']?['bids'] ?? json['bidCount'],
        createdAt: json['createdAt'] ?? '',
      );

  String? get thumbnailUrl => media.isNotEmpty ? media.first.url : null;

  DateTime get endDateTime => DateTime.tryParse(endTime) ?? DateTime.now();
  DateTime get startDateTime => DateTime.tryParse(startTime) ?? DateTime.now();

  bool get isActive => status == 'ACTIVE';
  bool get isEnded => status == 'ENDED' || DateTime.now().isAfter(endDateTime);

  String get statusLabel {
    const labels = {
      'PENDING': 'Sắp diễn ra',
      'ACTIVE': 'Đang đấu giá',
      'ENDED': 'Đã kết thúc',
      'CANCELLED': 'Đã huỷ',
    };
    return labels[status] ?? status;
  }

  String get itemTypeLabel {
    const labels = {
      'VEHICLE': 'Xe điện',
      'BATTERY': 'Pin điện',
      'OTHER': 'Khác',
    };
    return labels[itemType] ?? itemType;
  }
}

class AuctionMedia {
  final String id;
  final String url;
  final int sortOrder;

  const AuctionMedia({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  factory AuctionMedia.fromJson(Map<String, dynamic> json) => AuctionMedia(
        id: json['id'] ?? '',
        url: json['url'] ?? '',
        sortOrder: json['sortOrder'] ?? 0,
      );
}

class BidModel {
  final String id;
  final double amount;
  final String bidderId;
  final UserModel? bidder;
  final String auctionId;
  final String createdAt;

  const BidModel({
    required this.id,
    required this.amount,
    required this.bidderId,
    this.bidder,
    required this.auctionId,
    required this.createdAt,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) => BidModel(
        id: json['id'] ?? '',
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
        bidderId: json['bidderId'] ?? '',
        bidder: json['bidder'] != null
            ? UserModel.fromJson(json['bidder'])
            : null,
        auctionId: json['auctionId'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}
