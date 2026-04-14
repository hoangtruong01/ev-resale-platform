import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/app_network_image.dart';

// ─── Provider for fetching featured vehicles (no auth needed) ───────────────
final welcomeVehiclesProvider = FutureProvider<List<VehicleModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(
    '/vehicles',
    queryParameters: {
      'page': 1,
      'limit': 6,
      'approvalStatus': 'APPROVED',
    },
  );
  final listResp = VehicleListResponse.fromJson(response.data);
  return listResp.data;
});

// ─── Welcome Screen ──────────────────────────────────────────────────────────
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heroCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ──────────────────────────────────────────────────
            _HeroSection(
              fadeIn: _fadeIn,
              slideUp: _slideUp,
              pulse: _pulse,
            ),
            // ── Stats ─────────────────────────────────────────────────
            const _StatsSection(),
            // ── Features ──────────────────────────────────────────────
            const _FeaturesSection(),
            // ── Process ───────────────────────────────────────────────
            const _ProcessSection(),
            // ── Global safety ─────────────────────────────────────────
            const _GlobalSafeSection(),
            // ── Featured Vehicles ─────────────────────────────────────
            const _FeaturedVehiclesSection(),
            // ── Footer CTA ────────────────────────────────────────────
            const _FooterCTA(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final Animation<double> fadeIn;
  final Animation<Offset> slideUp;
  final Animation<double> pulse;

  const _HeroSection({
    required this.fadeIn,
    required this.slideUp,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003D1F),
            AppTheme.primaryDark,
            AppTheme.primaryGreen,
            Color(0xFF4CAF50),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: _GlowCircle(size: 280, opacity: 0.12),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: _GlowCircle(size: 220, opacity: 0.08),
          ),
          // Grid lines decoration
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: fadeIn,
                child: SlideTransition(
                  position: slideUp,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Logo badge
                      ScaleTransition(
                        scale: pulse,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.battery_charging_full_rounded,
                            size: 50,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Nền tảng uy tín #1 Việt Nam',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'EVN Pin Điện',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppTheme.accentYellow,
                            AppTheme.accentOrange
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Mua bán pin xe điện cũ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sàn giao dịch pin xe điện đã qua sử dụng\nAn toàn · Minh bạch · Chính hãng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // CTA Buttons
                      Builder(builder: (context) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.go('/auth/register'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryDark,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.rocket_launch_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text('Bắt đầu ngay — Miễn phí'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.go('/auth/login'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      width: 1.5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Đã có tài khoản? Đăng nhập'),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Section
// ─────────────────────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData(value: '5.000+', label: 'Sản phẩm\nniêm yết',
          icon: Icons.inventory_2_rounded, color: AppTheme.primaryGreen),
      _StatData(value: '2.500+', label: 'Giao dịch\nthành công',
          icon: Icons.handshake_rounded, color: AppTheme.accentOrange),
      _StatData(value: '10K+', label: 'Khách hàng\ntin tưởng',
          icon: Icons.people_rounded, color: AppTheme.info),
      _StatData(value: '63', label: 'Tỉnh thành\ncó mặt',
          icon: Icons.location_on_rounded, color: AppTheme.warning),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          Row(
            children: stats.asMap().entries.map((entry) {
              return Expanded(
                child: _StatItem(
                  data: entry.value,
                  isLast: entry.key == stats.length - 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _StatItem extends StatelessWidget {
  final _StatData data;
  final bool isLast;
  const _StatItem({required this.data, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: !isLast
          ? BoxDecoration(
              border: Border(
                right: BorderSide(color: AppTheme.grey100, width: 1),
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.grey900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.grey500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Features Section
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.security_rounded,
        title: 'An toàn & Uy tín',
        desc: 'Mọi sản phẩm được kiểm định và xác thực bởi chuyên gia EVN.',
        gradient: [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      ),
      _FeatureData(
        icon: Icons.auto_graph_rounded,
        title: 'Định giá AI',
        desc: 'Công nghệ AI phân tích thị trường và gợi ý giá hợp lý tức thì.',
        gradient: [AppTheme.primaryGreen, const Color(0xFF059669)],
      ),
      _FeatureData(
        icon: Icons.gavel_rounded,
        title: 'Đấu giá Online',
        desc: 'Sàn đấu giá minh bạch, thời gian thực với nhiều người tham gia.',
        gradient: [AppTheme.accentOrange, const Color(0xFFEF4444)],
      ),
      _FeatureData(
        icon: Icons.headset_mic_rounded,
        title: 'Hỗ trợ 24/7',
        desc: 'Đội ngũ tư vấn chuyên nghiệp sẵn sàng hỗ trợ mọi lúc.',
        gradient: [AppTheme.accentYellow, AppTheme.accentOrange],
      ),
    ];

    return Container(
      color: AppTheme.lightBg,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tại sao chọn EVN?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.grey900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nền tảng giao dịch pin điện hàng đầu',
            style: TextStyle(fontSize: 14, color: AppTheme.grey500),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: features.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: 160,
                child: _FeatureCard(
                  feature: features[i],
                  compact: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  final List<Color> gradient;
  const _FeatureData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.gradient,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureData feature;
  final bool compact;
  const _FeatureCard({required this.feature, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 48,
            height: compact ? 36 : 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: feature.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: feature.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              feature.icon,
              color: Colors.white,
              size: compact ? 18 : 24,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            feature.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.grey900,
              height: 1.3,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            feature.desc,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 9.5 : 11.5,
              color: AppTheme.grey500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global safety section
// ─────────────────────────────────────────────────────────────────────────────
class _GlobalSafeSection extends StatelessWidget {
  const _GlobalSafeSection();

  @override
  Widget build(BuildContext context) {
    final locations = [
      'Ha Noi',
      'Ho Chi Minh',
      'Da Nang',
      'Can Tho',
      'Singapore',
      'Tokyo',
    ];

    return Container(
      color: const Color(0xFF0B1220),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giao dịch an toàn trên phạm vi toàn cầu',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống đối tác và kiểm định phủ rộng giúp giao dịch minh bạch và an toàn.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Process Section
// ─────────────────────────────────────────────────────────────────────────────
class _ProcessSection extends StatelessWidget {
  const _ProcessSection();

  @override
  Widget build(BuildContext context) {
    final steps = [
      _ProcessStep(
          num: '01',
          title: 'Đăng ký',
          desc: 'Tạo tài khoản miễn phí trong 1 phút',
          icon: Icons.person_add_rounded),
      _ProcessStep(
          num: '02',
          title: 'Xác thực',
          desc: 'Xác minh danh tính để bảo vệ giao dịch',
          icon: Icons.verified_user_rounded),
      _ProcessStep(
          num: '03',
          title: 'Giao dịch',
          desc: 'Mua bán hoặc đấu giá an toàn & minh bạch',
          icon: Icons.swap_horiz_rounded),
      _ProcessStep(
          num: '04',
          title: 'Nhận hàng',
          desc: 'Giao hàng tận nơi, bảo hành rõ ràng',
          icon: Icons.local_shipping_rounded),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quy trình giao dịch',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.grey900,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 24),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.accentYellow],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ...steps.asMap().entries.map((entry) {
            final isLast = entry.key == steps.length - 1;
            return _ProcessStepRow(step: entry.value, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _ProcessStep {
  final String num;
  final String title;
  final String desc;
  final IconData icon;
  const _ProcessStep({
    required this.num,
    required this.title,
    required this.desc,
    required this.icon,
  });
}

class _ProcessStepRow extends StatelessWidget {
  final _ProcessStep step;
  final bool isLast;
  const _ProcessStepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number + line
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      step.num,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryGreen.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.grey900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.desc,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.grey500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(step.icon, color: AppTheme.primaryGreen, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Vehicles Section
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedVehiclesSection extends ConsumerWidget {
  const _FeaturedVehiclesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(welcomeVehiclesProvider);

    return Container(
      color: AppTheme.lightBg,
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sản phẩm nổi bật',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.grey900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hàng hot đang được săn đón',
                      style: TextStyle(fontSize: 13, color: AppTheme.grey500),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => context.go('/auth/login'),
                  child: const Row(
                    children: [
                      Text(
                        'Xem thêm',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.primaryGreen, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          vehiclesAsync.when(
            loading: () => SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                itemBuilder: (_, __) => const _VehicleCardSkeleton(),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(
                child: Text(
                  'Đăng nhập để xem sản phẩm nổi bật',
                  style: TextStyle(color: AppTheme.grey500),
                ),
              ),
            ),
            data: (vehicles) {
              if (vehicles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Chưa có sản phẩm nào',
                      style: TextStyle(color: AppTheme.grey500),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: vehicles.length,
                  itemBuilder: (_, i) => _FeaturedVehicleCard(
                    vehicle: vehicles[i],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedVehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _FeaturedVehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/auth/login'),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: AppNetworkImage(
                  url: vehicle.thumbnailUrl,
                  width: double.infinity,
                  height: 130,
                  placeholderIcon: Icons.electric_car_rounded,
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: AppTheme.grey400),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            vehicle.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.grey400),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      AppUtils.formatCurrency(vehicle.price),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
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

class _VehicleCardSkeleton extends StatelessWidget {
  const _VehicleCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: const BoxDecoration(
              color: AppTheme.grey100,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(height: 12, width: 140),
                  const SizedBox(height: 8),
                  _SkeletonLine(height: 10, width: 100),
                  const Spacer(),
                  _SkeletonLine(height: 14, width: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double height;
  final double width;
  const _SkeletonLine({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer CTA
// ─────────────────────────────────────────────────────────────────────────────
class _FooterCTA extends StatelessWidget {
  const _FooterCTA();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 48),
      child: Column(
        children: [
          const Icon(
            Icons.electric_bolt_rounded,
            color: AppTheme.accentYellow,
            size: 40,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sẵn sàng bắt đầu?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng ký miễn phí và khám phá\nhàng ngàn sản phẩm pin xe điện uy tín',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/auth/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Đăng ký ngay — Miễn phí'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/auth/login'),
            child: Text(
              'Đã có tài khoản? Đăng nhập',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Copyright
          Text(
            '© 2026 EVN Market · Bảo mật · Điều khoản',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────
class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
