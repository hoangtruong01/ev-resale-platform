import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evn_battery_trading/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/utils/app_utils.dart';
import '../../../services/dashboard_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/app_network_image.dart';
import 'kyc_verification_screen.dart';
import '../../admin/screens/kyc_management_screen.dart';
import '../../admin/screens/admin_analytics_screen.dart';
import 'payment_methods_screen.dart';
import 'terms_policy_screen.dart';
import 'change_password_screen.dart';
import '../../../core/auth/session_state_provider.dart';

final dashboardOverviewProvider = FutureProvider<DashboardOverviewData>((ref) {
  return ref.read(dashboardServiceProvider).getOverview();
});

final dashboardOrdersProvider = FutureProvider<List<DashboardOrderData>>((ref) {
  return ref.read(dashboardServiceProvider).getOrders();
});



class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final favoritesAsync = ref.watch(dashboardFavoritesProvider);

    Future<void> pickAndUploadAvatar(ImageSource source) async {
      var loadingDialogVisible = false;
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1920,
        );

        if (pickedFile == null) return;

        if (!context.mounted) return;

        const maxAvatarBytes = 5 * 1024 * 1024;
        final imageFile = File(pickedFile.path);
        if (await imageFile.length() > maxAvatarBytes) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ảnh phải có dung lượng nhỏ hơn hoặc bằng 5 MB.'),
            ),
          );
          return;
        }

        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
          );
          loadingDialogVisible = true;
        }

        await ref.read(authStateProvider.notifier).updateAvatar(imageFile);

        if (context.mounted) {
          if (loadingDialogVisible) {
            Navigator.of(context, rootNavigator: true).pop();
            loadingDialogVisible = false;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          if (loadingDialogVisible) {
            Navigator.of(context, rootNavigator: true).pop();
            loadingDialogVisible = false;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật ảnh: $e')));
        }
      }
    }

    Future<void> removeAvatar() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa ảnh đại diện?'),
          content: const Text(
            'Ảnh hiện tại sẽ bị xóa và tài khoản sẽ dùng chữ cái đại diện.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Xóa ảnh'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      try {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          ),
        );
        await ref.read(authStateProvider.notifier).removeAvatar();
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa ảnh đại diện.')));
      } catch (error) {
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xóa ảnh: $error')));
      }
    }

    Future<void> showAvatarActions() async {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              if (user?.avatar?.isNotEmpty == true)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.error,
                  ),
                  title: const Text(
                    'Xóa ảnh đại diện',
                    style: TextStyle(color: AppTheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    removeAvatar();
                  },
                ),
            ],
          ),
        ),
      );
    }

    final overview = overviewAsync.maybeWhen(
      data: (data) => data,
      orElse: () => const DashboardOverviewData(
        totalOrders: 0,
        favoriteCount: 0,
        activeListings: 0,
      ),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryDark, AppTheme.primaryGreen],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: showAvatarActions,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              child: user?.avatar != null
                                  ? ClipOval(
                                      child: AppNetworkImage(
                                        url: user!.avatar!,
                                        width: 88,
                                        height: 88,
                                      ),
                                    )
                                  : Text(
                                      user?.displayName.isNotEmpty == true
                                          ? user!.displayName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.displayName ?? l10n.profileUserDefault,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (user?.rating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppTheme.accentYellow,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user!.rating!.toStringAsFixed(1)} (${user.totalRatings} đánh giá)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Menu Items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.grey200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            label: l10n.statsSelling,
                            value: '${overview.activeListings}',
                          ),
                        ),
                        const _VertDivider(),
                        Expanded(
                          child: _StatItem(
                            label: l10n.statsBought,
                            value: '${overview.totalOrders}',
                          ),
                        ),
                        const _VertDivider(),
                        Expanded(
                          child: _StatItem(
                            label: l10n.statsSaved,
                            value: '${overview.favoriteCount}',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Menu sections
                  _MenuSection(
                    title: l10n.sectionAccount,
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        label: l10n.menuPersonalInfo,
                        onTap: () =>
                            _showProfileInfoDialog(context, ref, user, l10n),
                      ),
                      _MenuItem(
                        icon: Icons.verified_user_outlined,
                        label: l10n.menuKyc,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KycVerificationScreen(),
                          ),
                        ),
                        trailing: Consumer(
                          builder: (ctx, ref, _) {
                            final kycStatus = ref.watch(kycStatusProvider);
                            return kycStatus.when(
                              loading: () => const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (data) {
                                final status =
                                    data['kycStatus'] as String? ??
                                    'UNVERIFIED';
                                final (label, color) = switch (status) {
                                  'APPROVED' => (
                                    l10n.kycStatusApproved,
                                    AppTheme.success,
                                  ),
                                  'PENDING' => (
                                    l10n.kycStatusPending,
                                    AppTheme.warning,
                                  ),
                                  'REJECTED' => (
                                    l10n.kycStatusRejected,
                                    AppTheme.error,
                                  ),
                                  _ => (
                                    l10n.kycStatusUnverified,
                                    AppTheme.grey400,
                                  ),
                                };
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline,
                        label: l10n.menuChangePassword,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: l10n.menuNotifications,
                        onTap: () => context.push('/notifications'),
                      ),

                      _MenuItem(
                        icon: Icons.language,
                        label: l10n.language,
                        onTap: () => _showLanguageSheet(context, ref, l10n),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _MenuSection(
                    title: l10n.sectionTransactions,
                    items: [
                      _MenuItem(
                        icon: Icons.list_alt_outlined,
                        label: l10n.menuMyListings,
                        onTap: () => context.push('/profile/listings'),
                      ),
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        label: l10n.menuTransactions,
                        onTap: () => context.push('/transactions'),
                      ),
                      _MenuItem(
                        icon: Icons.favorite_outline,
                        label: l10n.menuSaved,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DashboardFavoritesScreen(
                              favoritesAsync: favoritesAsync,
                            ),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.gavel_outlined,
                        label: l10n.menuBidHistory,
                        onTap: () => context.push('/auctions'),
                      ),
                      _MenuItem(
                        icon: Icons.payment_outlined,
                        label: l10n.menuPaymentMethods,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentMethodsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _MenuSection(
                    title: l10n.sectionSupport,
                    items: [
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: l10n.menuHelpCenter,
                        onTap: () => context.push('/support'),
                      ),
                      _MenuItem(
                        icon: Icons.policy_outlined,
                        label: l10n.menuTermsPolicy,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsPolicyScreen(),
                          ),
                        ),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: l10n.menuAboutApp,
                        onTap: () => showAboutDialog(
                          context: context,
                          applicationName: 'EVN Pin Điện',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              'Nền tảng mua bán pin xe điện cũ EVN',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (user?.role == 'ADMIN' || user?.role == 'MODERATOR') ...[
                    _MenuSection(
                      title: l10n.sectionAdmin,
                      items: [
                        _MenuItem(
                          icon: Icons.dashboard_customize_outlined,
                          label: l10n.adminModeSwitch,
                          color: AppTheme.primaryGreen,
                          onTap: () {
                            ref.read(adminModeProvider.notifier).state = true;
                            context.go('/admin');
                          },
                        ),
                        _MenuItem(
                          icon: Icons.admin_panel_settings_outlined,
                          label: l10n.adminKycApprove,
                          color: AppTheme.primaryGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const KycManagementScreen(),
                            ),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.analytics_outlined,
                          label: l10n.adminSystemStats,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminAnalyticsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Logout
                  InkWell(
                    onTap: () => _showLogoutDialog(context, ref, l10n),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.menuLogout,
                            style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.menuLogout),
        content: Text(l10n.menuLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.menuCancel,
              style: const TextStyle(color: AppTheme.grey600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(l10n.menuLogout),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileInfoDialog(
    BuildContext context,
    WidgetRef ref,
    UserModel? user,
    AppLocalizations l10n,
  ) async {
    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.displayName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    var isSaving = false;
    String? errorMessage;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.menuPersonalInfo),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.infoFullName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.length < 2) {
                        return 'Họ tên phải có ít nhất 2 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.email,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.infoEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.infoPhone,
                      hintText: '0901234567',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isNotEmpty &&
                          !RegExp(r'^0\d{9,10}$').hasMatch(phone)) {
                        return 'Số điện thoại phải gồm 10-11 số và bắt đầu bằng 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.infoAddress,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppTheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: Text(l10n.menuCancel),
            ),
            FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSaving = true;
                        errorMessage = null;
                      });
                      try {
                        await ref
                            .read(authStateProvider.notifier)
                            .updateProfile(
                              fullName: fullNameController.text,
                              phone: phoneController.text,
                              address: addressController.text,
                            );
                        if (ctx.mounted) Navigator.pop(dialogContext, true);
                      } catch (error) {
                        if (!ctx.mounted) return;
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = 'Không thể cập nhật hồ sơ: $error';
                        });
                      }
                    },
              icon: isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );

    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công!')),
      );
    }
  }
}

class DashboardOrdersScreen extends StatelessWidget {
  final AsyncValue<List<DashboardOrderData>> ordersAsync;
  const DashboardOrdersScreen({super.key, required this.ordersAsync});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giao dịch')),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa có giao dịch nào',
                style: TextStyle(color: AppTheme.grey600),
              ),
            );
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final order = orders[i];
              return ListTile(
                title: Text(order.itemName),
                subtitle: Text(
                  '${order.status} • ${AppUtils.timeAgo(order.createdAt)}',
                ),
                trailing: Text(
                  AppUtils.formatCurrency(order.amount),
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DashboardFavoritesScreen extends ConsumerWidget {
  final AsyncValue<List<DashboardFavoriteData>> favoritesAsync;
  const DashboardFavoritesScreen({super.key, required this.favoritesAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm đã lưu')),
      body: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'Bạn chưa lưu sản phẩm nào',
                style: TextStyle(color: AppTheme.grey600),
              ),
            );
          }
          return ListView.separated(
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final favorite = favorites[i];
              return ListTile(
                leading: favorite.thumbnail != null && favorite.thumbnail!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppNetworkImage(
                          url: favorite.thumbnail!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(Icons.image_outlined, color: AppTheme.grey400),
                      ),
                title: Text(
                  favorite.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  favorite.location ?? 'Chưa xác định',
                  style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppUtils.formatCurrency(favorite.price),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                      onPressed: () async {
                        try {
                          await ref.read(dashboardFavoritesProvider.notifier).removeFavorite(favorite.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                  final sourceId = favorite.sourceId;
                  final itemType = favorite.itemType;
                  if (sourceId == null || sourceId.isEmpty) return;

                  if (itemType == 'VEHICLE') {
                    context.push('/vehicles/$sourceId');
                  } else if (itemType == 'BATTERY') {
                    context.push('/batteries/$sourceId');
                  } else if (itemType == 'AUCTION') {
                    context.push('/auctions/$sourceId');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

void _showLanguageSheet(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
) {
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
            l10n.language,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _LanguageOption(
            label: l10n.languageVi,
            onTap: () {
              ref.read(localeProvider.notifier).state = const Locale('vi');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _LanguageOption(
            label: l10n.languageEn,
            onTap: () {
              ref.read(localeProvider.notifier).state = const Locale('en');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _LanguageOption(
            label: l10n.languageJa,
            onTap: () {
              ref.read(localeProvider.notifier).state = const Locale('ja');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.grey200),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.grey600, fontSize: 12),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 40, width: 1, color: AppTheme.grey200);
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : AppTheme.grey400,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => item),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : AppTheme.grey800;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? defaultColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? defaultColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white30 : AppTheme.grey400,
                ),
          ],
        ),
      ),
    );
  }
}
