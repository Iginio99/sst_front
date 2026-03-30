import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../utils/colors.dart';

class AppShellItem {
  const AppShellItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
}

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.items,
    this.headerActions,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final List<AppShellItem> items;
  final List<Widget>? headerActions;

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;

    return Scaffold(
      body: Row(
        children: [
          _AppSidebar(items: items),
          Expanded(
            child: Column(
              children: [
                _AppTopBar(
                  title: title,
                  subtitle: subtitle,
                  userName: user?.name ?? 'Invitado',
                  email: user?.email ?? '',
                  actions: headerActions,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSidebar extends StatelessWidget {
  const _AppSidebar({required this.items});

  final List<AppShellItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF172554)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SST Workspace',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Navegacion persistente para escritorio',
                      style: TextStyle(
                        color: AppColors.textOnDarkMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              for (final item in items) ...[
                _SidebarButton(item: item),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  await SessionManager.instance.clearSession();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Cerrar sesion',
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Color(0x33475569)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({required this.item});

  final AppShellItem item;

  @override
  Widget build(BuildContext context) {
    final isSelected = item.isSelected;
    return Material(
      color: isSelected ? const Color(0x332563EB) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected ? Colors.white : AppColors.textOnDarkMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textOnDarkMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTopBar extends StatelessWidget {
  const _AppTopBar({
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.email,
    this.actions,
  });

  final String title;
  final String subtitle;
  final String userName;
  final String email;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textGray900,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textGray600),
                ),
              ],
            ),
          ),
          if (actions != null) ...[...actions!, const SizedBox(width: 16)],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSlate50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: AppColors.textGray900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.textGray500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
