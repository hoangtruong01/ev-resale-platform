import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../models/auction_model.dart';

List<AuctionModel> _parseAuctionList(dynamic payload) {
  if (payload is List) {
    return payload
        .whereType<Map>()
        .map((item) => AuctionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => AuctionModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
  }

  return const [];
}

List<BidModel> _parseBidList(dynamic payload) {
  if (payload is List) {
    return payload
        .whereType<Map>()
        .map((item) => BidModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  if (payload is Map<String, dynamic>) {
    final data = payload['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => BidModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
  }

  return const [];
}

final auctionRealtimeTickProvider =
    StateProvider.family<int, String>((ref, auctionId) => 0);

final auctionListProvider = FutureProvider<List<AuctionModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    '/auctions',
    queryParameters: {
      'page': 1,
      'limit': 20,
    },
  );
  return _parseAuctionList(response.data);
});

final auctionDetailProvider =
    FutureProvider.autoDispose.family<AuctionModel, String>((ref, auctionId) async {
  ref.watch(auctionRealtimeTickProvider(auctionId));
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/auctions/$auctionId');
  final data = response.data;

  if (data is! Map) {
    throw const FormatException('Auction detail response is invalid.');
  }

  return AuctionModel.fromJson(Map<String, dynamic>.from(data));
});

final auctionBidsProvider =
    FutureProvider.autoDispose.family<List<BidModel>, String>((ref, auctionId) async {
  ref.watch(auctionRealtimeTickProvider(auctionId));
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    '/auctions/$auctionId/bids',
    queryParameters: {
      'page': 1,
      'limit': 20,
    },
  );

  return _parseBidList(response.data);
});
