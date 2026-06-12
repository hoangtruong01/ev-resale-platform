import 'dart:async';

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

const auctionPollInterval = Duration(seconds: 15);

Future<AuctionModel> _fetchAuctionDetail(
  Ref ref,
  String auctionId,
) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/auctions/$auctionId');
  final data = response.data;

  if (data is! Map) {
    throw const FormatException('Auction detail response is invalid.');
  }

  return AuctionModel.fromJson(Map<String, dynamic>.from(data));
}

Future<List<BidModel>> _fetchAuctionBids(
  Ref ref,
  String auctionId, {
  bool swallowErrors = false,
}) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get(
      '/auctions/$auctionId/bids',
      queryParameters: {
        'page': 1,
        'limit': 20,
      },
    );
    return _parseBidList(response.data);
  } catch (_) {
    if (swallowErrors) {
      return const [];
    }
    rethrow;
  }
}

class AuctionDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<AuctionModel, String> {
  Timer? _pollTimer;

  @override
  Future<AuctionModel> build(String auctionId) async {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    _pollTimer = Timer.periodic(auctionPollInterval, (_) {
      unawaited(refreshSilently());
    });

    return _fetchAuctionDetail(ref, auctionId);
  }

  Future<void> refreshSilently() async {
    final previous = state.valueOrNull;
    try {
      state = AsyncData(await _fetchAuctionDetail(ref, arg));
      await ref.read(auctionBidsProvider(arg).notifier).refreshSilently();
    } catch (_) {
      if (previous != null) {
        state = AsyncData(previous);
      }
    }
  }

  Future<void> refreshAfterBid() async {
    try {
      state = AsyncData(await _fetchAuctionDetail(ref, arg));
      await ref.read(auctionBidsProvider(arg).notifier).refreshSilently();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

class AuctionBidsNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<BidModel>, String> {
  @override
  Future<List<BidModel>> build(String auctionId) async {
    return _fetchAuctionBids(ref, auctionId, swallowErrors: true);
  }

  Future<void> refreshSilently() async {
    final previous = state.valueOrNull ?? const <BidModel>[];
    try {
      state = AsyncData(await _fetchAuctionBids(ref, arg));
    } catch (_) {
      state = AsyncData(previous);
    }
  }
}

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

final auctionDetailProvider = AsyncNotifierProvider.autoDispose
    .family<AuctionDetailNotifier, AuctionModel, String>(
  AuctionDetailNotifier.new,
);

final auctionBidsProvider = AsyncNotifierProvider.autoDispose
    .family<AuctionBidsNotifier, List<BidModel>, String>(
  AuctionBidsNotifier.new,
);
