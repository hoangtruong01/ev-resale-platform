import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/vehicle_service.dart';
import '../../../services/battery_service.dart';
import '../../../services/accessory_service.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/battery_model.dart';
import '../../../models/accessory_model.dart';
import '../widgets/home_widgets.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<VehicleModel> _vehicles = [];
  List<BatteryModel> _batteries = [];
  List<AccessoryModel> _accessories = [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(text);
    });
  }

  Future<void> _performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _vehicles = [];
        _batteries = [];
        _accessories = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _query = trimmed;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        ref.read(vehicleServiceProvider).getVehicles(search: trimmed, limit: 30),
        ref.read(batteryServiceProvider).getBatteries(search: trimmed, limit: 30),
        ref.read(accessoryServiceProvider).getAccessories(search: trimmed, limit: 30),
      ]);

      if (!mounted) return;

      setState(() {
        _vehicles = (futures[0] as VehicleListResponse).data;
        _batteries = (futures[1] as BatteryListResponse).data;
        _accessories = (futures[2] as AccessoryListResponse).data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi khi tìm kiếm: $e';
      });
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.grey400.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.grey600,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent<T>({
    required List<T> items,
    required IconData placeholderIcon,
    required String Function(T) getImageUrl,
    required String Function(T) getTitle,
    required double Function(T) getPrice,
    required String? Function(T) getSellerName,
    required String Function(T) getLocation,
    required String Function(T) getCreatedAt,
    required String Function(T) getDetailRoute,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_query.isEmpty) {
      return _buildEmptyState(
        'Nhập từ khóa ở ô tìm kiếm trên để tìm kiếm xe điện, pin điện, và phụ kiện...',
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        'Không tìm thấy kết quả phù hợp cho "$_query". Hãy thử tìm kiếm bằng từ khóa khác.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ProductGridCard(
          imageUrl: getImageUrl(item),
          title: getTitle(item),
          price: getPrice(item),
          sellerName: getSellerName(item),
          location: getLocation(item),
          timeAgo: formatTimeAgo(getCreatedAt(item)),
          placeholderIcon: placeholderIcon,
          onTap: () {
            context.push(getDetailRoute(item));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: Container(
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : AppTheme.grey100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tất cả mọi thứ...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.grey400, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          bottom: TabBar(
            labelColor: AppTheme.primaryGreen,
            unselectedLabelColor: isDark ? Colors.white60 : AppTheme.grey500,
            indicatorColor: AppTheme.primaryGreen,
            tabs: [
              Tab(text: 'Xe điện (${_vehicles.length})'),
              Tab(text: 'Pin điện (${_batteries.length})'),
              Tab(text: 'Phụ kiện (${_accessories.length})'),
            ],
          ),
        ),
        body: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : TabBarView(
                children: [
                  _buildTabContent<VehicleModel>(
                    items: _vehicles,
                    placeholderIcon: Icons.electric_moped_rounded,
                    getImageUrl: (v) => v.thumbnailUrl ?? '',
                    getTitle: (v) => v.name,
                    getPrice: (v) => v.price,
                    getSellerName: (v) => v.seller?.displayName,
                    getLocation: (v) => v.location,
                    getCreatedAt: (v) => v.createdAt,
                    getDetailRoute: (v) => '/vehicles/${v.id}',
                  ),
                  _buildTabContent<BatteryModel>(
                    items: _batteries,
                    placeholderIcon: Icons.battery_charging_full_rounded,
                    getImageUrl: (b) => b.thumbnailUrl ?? '',
                    getTitle: (b) => b.name,
                    getPrice: (b) => b.price,
                    getSellerName: (b) => b.seller?.displayName,
                    getLocation: (b) => b.location,
                    getCreatedAt: (b) => b.createdAt,
                    getDetailRoute: (b) => '/batteries/${b.id}',
                  ),
                  _buildTabContent<AccessoryModel>(
                    items: _accessories,
                    placeholderIcon: Icons.extension_rounded,
                    getImageUrl: (a) => a.thumbnailUrl ?? '',
                    getTitle: (a) => a.name,
                    getPrice: (a) => a.price,
                    getSellerName: (a) => a.seller?.displayName,
                    getLocation: (a) => a.location,
                    getCreatedAt: (a) => a.createdAt,
                    getDetailRoute: (a) => '/accessories/${a.id}',
                  ),
                ],
              ),
      ),
    );
  }
}
