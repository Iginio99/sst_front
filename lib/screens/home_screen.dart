import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../services/session_service.dart';
import '../utils/user_access.dart';
import 'learner_dashboard_screen.dart';
import 'login_screen.dart';
import 'manager_dashboard_screen.dart';
import 'monitor_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: SessionManager.instance.userNotifier,
      builder: (context, user, _) {
        if (user == null) {
          return const LoginScreen();
        }

        final access = UserAccess(user);
        final experience = access.primaryExperience;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(experience),
            child: _buildExperience(experience),
          ),
        );
      },
    );
  }

  Widget _buildExperience(HomeExperience experience) {
    switch (experience) {
      case HomeExperience.manager:
        return const ManagerDashboardScreen();
      case HomeExperience.monitor:
        return const MonitorDashboardScreen();
      case HomeExperience.learner:
        return const LearnerDashboardScreen();
    }
  }
}
