import 'package:dio/dio.dart';
import 'package:evn_battery_trading/core/network/dio_client.dart';
import 'package:evn_battery_trading/features/auctions/providers/auction_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _auctionId = 'auction-1';

Map<String, dynamic> _auctionJson({double currentPrice = 1_000_000}) => {
      'id': _auctionId,
      'title': 'Pin test',
      'itemType': 'BATTERY',
      'lotQuantity': 1,
      'startingPrice': 1_000_000,
      'currentPrice': currentPrice,
      'bidStep': 100_000,
      'startTime': '2026-06-07T00:00:00.000Z',
      'endTime': '2026-06-08T00:00:00.000Z',
      'status': 'ACTIVE',
      'approvalStatus': 'APPROVED',
      'sellerId': 'seller-1',
      'media': <Map<String, dynamic>>[],
      'createdAt': '2026-06-07T00:00:00.000Z',
    };

Dio _mockDio({
  required dynamic Function(String path) responder,
}) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          handler.resolve(
            Response(
              requestOptions: options,
              data: responder(options.path),
            ),
          );
        } catch (error) {
          handler.reject(
            DioException(
              requestOptions: options,
              message: error.toString(),
            ),
          );
        }
      },
    ),
  );
  return dio;
}

void main() {
  group('AuctionDetailNotifier', () {
    test('refreshSilently keeps previous data when fetch fails', () async {
      var shouldFail = false;
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            _mockDio(
              responder: (path) {
                if (path.contains('/bids')) {
                  return {'data': <Map<String, dynamic>>[]};
                }
                if (shouldFail) {
                  throw DioException(
                    requestOptions: RequestOptions(path: path),
                    message: 'network error',
                  );
                }
                return _auctionJson(currentPrice: 1_500_000);
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        auctionDetailProvider(_auctionId),
        (_, __) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(
        auctionDetailProvider(_auctionId).notifier,
      );

      await container.read(auctionDetailProvider(_auctionId).future);
      expect(container.read(auctionDetailProvider(_auctionId)).value?.currentPrice,
          1_500_000);

      shouldFail = true;
      await notifier.refreshSilently();

      expect(container.read(auctionDetailProvider(_auctionId)).isLoading, isFalse);
      expect(container.read(auctionDetailProvider(_auctionId)).value?.currentPrice,
          1_500_000);
    });

    test('refreshSilently updates data without entering loading state', () async {
      var currentPrice = 1_000_000.0;
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            _mockDio(
              responder: (path) {
                if (path.contains('/bids')) {
                  return {'data': <Map<String, dynamic>>[]};
                }
                return _auctionJson(currentPrice: currentPrice);
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        auctionDetailProvider(_auctionId),
        (_, __) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(
        auctionDetailProvider(_auctionId).notifier,
      );

      await container.read(auctionDetailProvider(_auctionId).future);
      currentPrice = 2_000_000;
      await notifier.refreshSilently();

      final state = container.read(auctionDetailProvider(_auctionId));
      expect(state.isLoading, isFalse);
      expect(state.value?.currentPrice, 2_000_000);
    });
  });

  group('AuctionBidsNotifier', () {
    test('refreshSilently keeps previous bids when fetch fails', () async {
      var shouldFail = false;
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            _mockDio(
              responder: (path) {
                if (path.contains('/bids')) {
                  if (shouldFail) {
                    throw DioException(
                      requestOptions: RequestOptions(path: path),
                      message: 'network error',
                    );
                  }
                  return {
                    'data': [
                      {
                        'id': 'bid-1',
                        'amount': 1_200_000,
                        'createdAt': '2026-06-07T01:00:00.000Z',
                      },
                    ],
                  };
                }
                return _auctionJson();
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        auctionBidsProvider(_auctionId),
        (_, __) {},
      );
      addTearDown(subscription.close);

      final notifier = container.read(
        auctionBidsProvider(_auctionId).notifier,
      );

      await container.read(auctionBidsProvider(_auctionId).future);
      expect(container.read(auctionBidsProvider(_auctionId)).value, hasLength(1));

      shouldFail = true;
      await notifier.refreshSilently();

      final state = container.read(auctionBidsProvider(_auctionId));
      expect(state.isLoading, isFalse);
      expect(state.value, hasLength(1));
    });
  });
}
