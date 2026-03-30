import 'package:flutter/material.dart';

import '../models/module.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/app_navigation.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/app_shell.dart';
import '../widgets/desktop_content_scaffold.dart';
import 'chat_list_screen.dart';

class LearnerDashboardScreen extends StatefulWidget {
  const LearnerDashboardScreen({super.key});

  @override
  State<LearnerDashboardScreen> createState() => _LearnerDashboardScreenState();
}

class _LearnerDashboardScreenState extends State<LearnerDashboardScreen> {
  final _trainingService = TrainingService();

  late Future<List<Module>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _trainingService.fetchModules(onError: _showApiError);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1100;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final contentWidth = isWide ? 980.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;
    final user = SessionManager.instance.currentUser;

    if (isDesktop) {
      return AppShell(
        title: 'Tu aprendizaje SST',
        subtitle: 'Ruta de aprendizaje y capacitaciones obligatorias',
        items: _buildShellItems(context),
        body: DesktopContentScaffold(
          sidePanel: _LearnerDesktopPanel(
            userName: user?.name ?? 'Invitado',
            email: user?.email ?? '',
            modulesFuture: _modulesFuture,
          ),
          child: _LearnerDashboardBody(
            modulesFuture: _modulesFuture,
            sidePadding: 0,
            onOpenTraining: () => openTrainingExperience(context),
            onOpenChat: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
            dense: true,
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _LearnerHeader(
            userName: user?.name ?? 'Invitado',
            email: user?.email ?? '',
          ),
          Expanded(
            child: Container(
              color: AppColors.bgSlate100,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: _LearnerDashboardBody(
                    modulesFuture: _modulesFuture,
                    sidePadding: sidePadding,
                    onOpenTraining: () => openTrainingExperience(context),
                    onOpenChat: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudieron cargar tus modulos')),
    );
  }

  List<AppShellItem> _buildShellItems(BuildContext context) {
    return [
      AppShellItem(
        label: 'Resumen',
        icon: Icons.home_outlined,
        isSelected: true,
        onTap: () {},
      ),
      AppShellItem(
        label: 'Mis modulos',
        icon: Icons.school_outlined,
        onTap: () => openTrainingExperience(context),
      ),
      AppShellItem(
        label: 'Mensajes',
        icon: Icons.forum_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatListScreen()),
          );
        },
      ),
    ];
  }
}

class _LearnerDashboardBody extends StatelessWidget {
  const _LearnerDashboardBody({
    required this.modulesFuture,
    required this.sidePadding,
    required this.onOpenTraining,
    required this.onOpenChat,
    this.dense = false,
  });

  final Future<List<Module>> modulesFuture;
  final double sidePadding;
  final VoidCallback onOpenTraining;
  final VoidCallback onOpenChat;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Module>>(
      future: modulesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar modulos: ${snapshot.error}'),
          );
        }

        final modules = snapshot.data ?? [];
        final requiredModules = modules
            .where((m) => m.dueToChecklist && !m.quizCompleted)
            .toList();
        final approved = modules.where((m) => m.quizCompleted).length;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Modulos asignados',
                      value: '${modules.length}',
                      subtitle: 'Ruta de aprendizaje activa',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Modulos aprobados',
                      value: '$approved/${modules.length}',
                      subtitle: 'Quizzes aprobados',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Accesos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionCard(
                    icon: Icons.school,
                    color: AppColors.statusGreen,
                    title: 'Mis modulos',
                    subtitle: 'Capacitaciones asignadas',
                    onTap: onOpenTraining,
                  ),
                  _ActionCard(
                    icon: Icons.forum,
                    color: AppColors.primaryBlue,
                    title: 'Mensajes',
                    subtitle: 'Chat interno',
                    onTap: onOpenChat,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Capacitaciones obligatorias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray900,
                ),
              ),
              const SizedBox(height: 12),
              if (requiredModules.isEmpty)
                const Text(
                  'No tienes capacitaciones obligatorias pendientes.',
                  style: TextStyle(color: AppColors.textGray600),
                )
              else
                ...requiredModules.map(
                  (module) => _RequiredModuleCard(module: module),
                ),
              if (dense) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGray200),
                  ),
                  child: const Text(
                    'Consulta tu ruta, revisa pendientes y continua tu avance.',
                    style: TextStyle(color: AppColors.textGray600, height: 1.5),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LearnerDesktopPanel extends StatelessWidget {
  const _LearnerDesktopPanel({
    required this.userName,
    required this.email,
    required this.modulesFuture,
  });

  final String userName;
  final String email;
  final Future<List<Module>> modulesFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0E7490)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aprendizaje activo',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userName,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                email,
                style: const TextStyle(color: AppColors.textOnDarkMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray200),
          ),
          child: FutureBuilder<List<Module>>(
            future: modulesFuture,
            builder: (context, snapshot) {
              final modules = snapshot.data ?? const <Module>[];
              final pending = modules.where((m) => !m.quizCompleted).length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado rapido',
                    style: TextStyle(
                      color: AppColors.textGray900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LearnerPanelStat(label: 'Pendientes', value: '$pending'),
                  const SizedBox(height: 8),
                  _LearnerPanelStat(
                    label: 'Total asignados',
                    value: '${modules.length}',
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LearnerPanelStat extends StatelessWidget {
  const _LearnerPanelStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGray600)),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textGray900,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LearnerHeader extends StatelessWidget {
  const _LearnerHeader({required this.userName, required this.email});

  final String userName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0E7490)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu aprendizaje SST',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(color: AppColors.textOnDarkMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Usuario',
                        style: TextStyle(
                          color: AppColors.textOnDarkMuted,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () async {
                      await SessionManager.instance.clearSession();
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Cerrar sesion',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textGray600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textGray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textGray500),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredModuleCard extends StatelessWidget {
  const _RequiredModuleCard({required this.module});

  final Module module;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.statusRed, width: 4),
        ),
      ),
      child: InkWell(
        onTap: () => openTrainingExperience(context, selectedModule: module),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: module.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  module.icon,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGray400),
          ],
        ),
      ),
    );
  }
}
