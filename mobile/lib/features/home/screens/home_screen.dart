import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:evn_battery_trading/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../services/battery_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../services/stats_service.dart';
import '../../../models/battery_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/stats_model.dart';
import '../../../widgets/app_network_image.dart';
import '../../../core/utils/app_utils.dart';

class _HomeFeature {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;

  const _HomeFeature({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.descKey,
  });
}

class _HomeProcessStep {
  final int step;
  final String titleKey;
  final String descKey;

  const _HomeProcessStep({
    required this.step,
    required this.titleKey,
    required this.descKey,
  });
}

const _homeFeatures = [
  _HomeFeature(
    icon: Icons.verified_user_outlined,
    color: AppTheme.info,
    titleKey: 'featureSafe',
    descKey: 'featureSafeDesc',
  ),
  _HomeFeature(
    icon: Icons.auto_graph_rounded,
    color: AppTheme.primaryGreen,
    titleKey: 'featureAi',
    descKey: 'featureAiDesc',
  ),
  _HomeFeature(
    icon: Icons.gavel_rounded,
    color: AppTheme.accentOrange,
    titleKey: 'featureAuction',
    descKey: 'featureAuctionDesc',
  ),
  _HomeFeature(
    icon: Icons.headset_mic_outlined,
    color: AppTheme.accentYellow,
    titleKey: 'featureSupport',
    descKey: 'featureSupportDesc',
  ),
];

const _homeProcessSteps = [
  _HomeProcessStep(
    step: 1,
    titleKey: 'processStep1Title',
    descKey: 'processStep1Desc',
  ),
  _HomeProcessStep(
    step: 2,
    titleKey: 'processStep2Title',
    descKey: 'processStep2Desc',
  ),
  _HomeProcessStep(
    step: 3,
    titleKey: 'processStep3Title',
    descKey: 'processStep3Desc',
  ),
  _HomeProcessStep(
    step: 4,
    titleKey: 'processStep4Title',
    descKey: 'processStep4Desc',
  ),
];

// Providers
final homeBatteriesProvider = FutureProvider<BatteryListResponse>((ref) {
  return ref.read(batteryServiceProvider).getBatteries(limit: 6);
});

final homeVehiclesProvider = FutureProvider<VehicleListResponse>((ref) {
  return ref.read(vehicleServiceProvider).getVehicles(limit: 6);
});

final homeStatsProvider = FutureProvider<StatsOverview>((ref) {
  return ref.read(statsServiceProvider).getOverview();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final batteries = ref.watch(homeBatteriesProvider);
    final vehicles = ref.watch(homeVehiclesProvider);
    final stats = ref.watch(homeStatsProvider);
    final statsData = stats.maybeWhen(
      data: (data) => data,
      orElse: () => null,
    );
    final batteryTotal = statsData?.batteriesListed ??
        batteries.maybeWhen(data: (data) => data.total, orElse: () => null);
    final vehicleTotal = statsData?.vehiclesListed ??
        vehicles.maybeWhen(data: (data) => data.total, orElse: () => null);
    final displayName = user?.displayName.split(' ').last ?? 'ban';

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        onRefresh: () async {
          ref.invalidate(homeBatteriesProvider);
          ref.invalidate(homeVehiclesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryDark,
                      AppTheme.primaryGreen.withValues(alpha: 0.95),
                      AppTheme.primaryGreen,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l10n.hello}, $displayName! 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.welcome,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push('/notifications'),
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 26),
                          ),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: user?.avatar != null
                                ? ClipOval(
                                    child: AppNetworkImage(
                                        url: user!.avatar!,
                                        width: 40,
                                        height: 40),
                                  )
                                : Text(
                                    (user?.displayName.isNotEmpty == true)
                                        ? user!.displayName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.heroSubtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.push('/batteries'),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(Icons.search, color: AppTheme.grey400),
                              const SizedBox(width: 10),
                              Text(
                                l10n.searchHint,
                                style: const TextStyle(
                                    color: AppTheme.grey400, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              onPressed: () => context.go('/vehicles'),
                              child: Text(l10n.ctaVehicles),
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: OutlinedButton(
                              onPressed: () => context.go('/auctions'),
                              child: Text(l10n.ctaAuctions),
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: OutlinedButton(
                              onPressed: () => _showSellMenu(context, l10n),
                              child: Text(l10n.ctaSell),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.statsTitle,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.battery_charging_full_rounded,
                            label: l10n.statBatteries,
                            value: _formatStatValue(batteryTotal),
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.electric_car_rounded,
                            label: l10n.statVehicles,
                            value: _formatStatValue(vehicleTotal),
                            color: AppTheme.accentOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long,
                            label: l10n.statTransactions,
                            value: _formatStatValueOrText(
                              statsData?.totalTransactions,
                              l10n.updating,
                            ),
                            color: AppTheme.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people_alt_rounded,
                            label: l10n.statUsers,
                            value: _formatStatValueOrText(
                              statsData?.totalUsers,
                              l10n.updating,
                            ),
                            color: AppTheme.accentYellow,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.categories,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _CategoryCard(
                          icon: Icons.battery_charging_full_rounded,
                          label: l10n.categoryBattery,
                          color: AppTheme.primaryGreen,
                          onTap: () => context.go('/batteries'),
                        ),
                        _CategoryCard(
                          icon: Icons.electric_car_rounded,
                          label: l10n.categoryVehicle,
                          color: AppTheme.accentOrange,
                          onTap: () => context.go('/vehicles'),
                        ),
                        _CategoryCard(
                          icon: Icons.extension_outlined,
                          label: l10n.categoryAccessory,
                          color: AppTheme.info,
                          onTap: () => context.go('/accessories'),
                        ),
                        _CategoryCard(
                          icon: Icons.gavel_rounded,
                          label: l10n.categoryAuction,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.go('/auctions'),
                        ),
                        _CategoryCard(
                          icon: Icons.message_outlined,
                          label: l10n.categoryChat,
                          color: AppTheme.info,
                          onTap: () => context.go('/chat'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Feature highlight banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentOrange.withValues(alpha: 0.9),
                      AppTheme.accentYellow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.bannerTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              l10n.bannerSubtitle,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: const Icon(Icons.battery_charging_full_rounded,
                          size: 60, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Features
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.whyChoose,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _homeFeatures
                          .map((feature) =>
                              _FeatureCard(feature: feature, l10n: l10n))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Process
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.processTitle,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ..._homeProcessSteps
                        .map((step) =>
                            _ProcessStepTile(step: step, l10n: l10n))
                        .toList(),
                  ],
                ),
              ),
            ),

            // Global network
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.primaryGreen.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.globalTitle,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.globalDesc,
                            style: const TextStyle(
                                color: AppTheme.grey600, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _LocationChip(label: 'Ha Noi'),
                              _LocationChip(label: 'Ho Chi Minh'),
                              _LocationChip(label: 'Da Nang'),
                              _LocationChip(label: 'Can Tho'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.primaryDark,
                          ],
                        ),
                      ),
                      child: const Icon(Icons.public,
                          color: Colors.white, size: 36),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Batteries
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 0, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.featuredBatteries,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.go('/batteries'),
                      child: Text(l10n.viewAll,
                          style: const TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),

            // Battery horizontal list
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: batteries.when(
                  loading: () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => const _BatteryCardSkeleton(),
                  ),
                  error: (e, _) => Center(child: Text(l10n.errorLoad('$e'))),
                  data: (data) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.data.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => BatteryCard(battery: data.data[i]),
                  ),
                ),
              ),
            ),

            // Featured Vehicles
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 0, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.featuredVehicles,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.go('/vehicles'),
                      child: Text(l10n.viewAll,
                          style: const TextStyle(color: AppTheme.primaryGreen)),
                    ),
                  ],
                ),
              ),
            ),

            // Vehicle list
            vehicles.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text(l10n.errorLoad('$e'))),
              ),
              data: (data) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => VehicleListTile(vehicle: data.data[i]),
                  childCount: data.data.length,
                ),
              ),
            ),

            // Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.footerProducts,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      children: [
                        _FooterLink(
                          label: l10n.featuredVehicles,
                          onTap: () => context.go('/vehicles'),
                        ),
                        _FooterLink(
                          label: l10n.featuredBatteries,
                          onTap: () => context.go('/batteries'),
                        ),
                        _FooterLink(
                          label: l10n.categoryAuction,
                          onTap: () => context.go('/auctions'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.footerSupport,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      children: [
                        _FooterLink(
                          label: l10n.categoryChat,
                          onTap: () => context.go('/chat'),
                        ),
                        _FooterLink(
                          label: l10n.notifications,
                          onTap: () => context.go('/notifications'),
                        ),
                        _FooterLink(
                          label: l10n.profile,
                          onTap: () => context.go('/profile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.footerRights,
                      style: const TextStyle(
                          color: AppTheme.grey500, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  void _showSellMenu(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.sellTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            _SellOption(
              icon: Icons.battery_charging_full_rounded,
              title: l10n.sellBatteryTitle,
              subtitle: l10n.sellBatterySubtitle,
              color: AppTheme.primaryGreen,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/battery');
              },
            ),
            const SizedBox(height: 12),
            _SellOption(
              icon: Icons.electric_car_rounded,
              title: l10n.sellVehicleTitle,
              subtitle: l10n.sellVehicleSubtitle,
              color: AppTheme.accentOrange,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/vehicle');
              },
            ),
            const SizedBox(height: 12),
            _SellOption(
              icon: Icons.extension_outlined,
              title: l10n.sellAccessoryTitle,
              subtitle: l10n.sellAccessorySubtitle,
              color: AppTheme.info,
              onTap: () {
                Navigator.pop(context);
                context.push('/sell/accessory');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

String _formatStatValue(int? value) {
  if (value == null || value == 0) return '--';
  return '${AppUtils.formatNumber(value)}+';
}

String _formatStatValueOrText(int? value, String fallback) {
  if (value == null || value == 0) return fallback;
  return '${AppUtils.formatNumber(value)}+';
}

String _resolveHomeText(AppLocalizations l10n, String key) {
  return switch (key) {
    'featureSafe' => l10n.featureSafe,
    'featureSafeDesc' => l10n.featureSafeDesc,
    'featureAi' => l10n.featureAi,
    'featureAiDesc' => l10n.featureAiDesc,
    'featureAuction' => l10n.featureAuction,
    'featureAuctionDesc' => l10n.featureAuctionDesc,
    'featureSupport' => l10n.featureSupport,
    'featureSupportDesc' => l10n.featureSupportDesc,
    'processStep1Title' => l10n.processStep1Title,
    'processStep1Desc' => l10n.processStep1Desc,
    'processStep2Title' => l10n.processStep2Title,
    'processStep2Desc' => l10n.processStep2Desc,
    'processStep3Title' => l10n.processStep3Title,
    'processStep3Desc' => l10n.processStep3Desc,
    'processStep4Title' => l10n.processStep4Title,
    'processStep4Desc' => l10n.processStep4Desc,
    _ => key,
  };
}

bool _isNewListing(String? createdAt) {
  if (createdAt == null || createdAt.isEmpty) return false;
  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return false;
  final diff = DateTime.now().difference(parsed.toLocal());
  return diff.inDays <= 7;
}

String _statusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'AVAILABLE' => l10n.badgeAvailable,
    'SOLD' => l10n.badgeSold,
    'AUCTION' => l10n.badgeAuction,
    'RESERVED' => l10n.badgeReserved,
    _ => status,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'AVAILABLE' => AppTheme.success,
    'SOLD' => AppTheme.grey500,
    'AUCTION' => AppTheme.accentOrange,
    'RESERVED' => AppTheme.warning,
    _ => AppTheme.grey500,
  };
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _HomeFeature feature;
  final AppLocalizations l10n;
  const _FeatureCard({required this.feature, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            _resolveHomeText(l10n, feature.titleKey),
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _resolveHomeText(l10n, feature.descKey),
            style: const TextStyle(color: AppTheme.grey500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProcessStepTile extends StatelessWidget {
  final _HomeProcessStep step;
  final AppLocalizations l10n;
  const _ProcessStepTile({required this.step, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.step}',
                style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resolveHomeText(l10n, step.titleKey),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _resolveHomeText(l10n, step.descKey),
                  style: const TextStyle(
                      color: AppTheme.grey500, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String label;
  const _LocationChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.primaryGreen,
            fontWeight: FontWeight.w600,
            fontSize: 12),
      ),
    );
  }
}

class _SellOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SellOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.grey500, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.grey400),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ListingBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool compact;

  const _ListingBadge({
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class BatteryCard extends StatelessWidget {
  final BatteryModel battery;
  const BatteryCard({super.key, required this.battery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showNew = _isNewListing(battery.createdAt);
    final statusText = _statusLabel(l10n, battery.status);
    return GestureDetector(
      onTap: () => context.push('/batteries/${battery.id}'),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  AppNetworkImage(
                    url: battery.thumbnailUrl,
                    height: 120,
                    width: double.infinity,
                    placeholderIcon: Icons.battery_charging_full_rounded,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ListingBadge(
                      label: showNew ? l10n.badgeNew : statusText,
                      color: showNew
                          ? AppTheme.primaryGreen
                          : _statusColor(battery.status),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    battery.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${battery.condition}%',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${battery.capacity}kWh',
                        style: const TextStyle(
                            color: AppTheme.grey600, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppUtils.formatCurrency(battery.price),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleListTile extends StatelessWidget {
  final VehicleModel vehicle;
  const VehicleListTile({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showNew = _isNewListing(vehicle.createdAt);
    final statusText = _statusLabel(l10n, vehicle.status);
    return GestureDetector(
      onTap: () => context.push('/vehicles/${vehicle.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: AppNetworkImage(
                url: vehicle.thumbnailUrl,
                width: 110,
                height: 90,
                placeholderIcon: Icons.electric_car_rounded,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ListingBadge(
                          label: showNew ? l10n.badgeNew : statusText,
                          color: showNew
                              ? AppTheme.primaryGreen
                              : _statusColor(vehicle.status),
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vehicle.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${vehicle.brand} • ${vehicle.year}',
                      style: const TextStyle(
                          color: AppTheme.grey600, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.grey400, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppUtils.formatCurrency(vehicle.price),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryCardSkeleton extends StatelessWidget {
  const _BatteryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
