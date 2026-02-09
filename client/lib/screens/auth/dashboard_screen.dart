import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  Future<void> _showLogoutConfirm(BuildContext context) async {
    final logout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you really want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (context.mounted && logout == true) {
      await AuthController.setLoggedIn(false);
      try {
        Get.find<AuthController>().reset();
      } catch (_) {}
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _showLogoutConfirm(context);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'ADMIN Dashboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Loagma',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Handle notifications tap
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '6',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        drawer: _DashboardDrawer(onLogout: () => _showLogoutConfirm(context)),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount;
              if (width >= 900) {
                crossAxisCount = 4;
              } else if (width >= 600) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 2;
              }

              final childAspectRatio = width < 400 ? 0.95 : 1.1;

              final modules = <_ModuleCard>[
                _ModuleCard(
                  title: 'Issue to production',
                  subtitle: 'Issue materials or items to production',
                  icon: Icons.outbox_rounded,
                  onTap: () {
                    Get.toNamed(AppRoutes.issueToProduction);
                  },
                ),
                _ModuleCard(
                  title: 'Receive from production',
                  subtitle: 'Receive items or materials from production',
                  icon: Icons.inbox_rounded,
                  onTap: () {
                    Get.toNamed(AppRoutes.receiveFromProduction);
                  },
                ),
                _ModuleCard(
                  title: 'BOM',
                  subtitle: 'Create and manage bill of materials',
                  icon: Icons.list_alt_rounded,
                  onTap: () {
                    Get.toNamed(AppRoutes.bom);
                  },
                ),
              ];

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: modules.length,
                  itemBuilder: (context, index) => modules[index],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset(
                          'lib/assets/sidebarLogo.jpeg',
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loagma PMS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Production Management',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Modules',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (Get.currentRoute != AppRoutes.dashboard) {
                        Get.offAllNamed(AppRoutes.dashboard);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.outbox_rounded,
                    label: 'Issue to production',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.toNamed(AppRoutes.issueToProduction);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.inbox_rounded,
                    label: 'Receive from production',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.toNamed(AppRoutes.receiveFromProduction);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.list_alt_rounded,
                    label: 'BOM',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.toNamed(AppRoutes.bom);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                iconColor: Colors.redAccent,
                onTap: () async {
                  Navigator.of(context).pop();
                  await onLogout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.primaryLight.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
