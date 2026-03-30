import 'package:flutter/material.dart';

import '../models/module.dart';
import '../services/checklist_service.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/app_navigation.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/app_shell.dart';
import '../widgets/desktop_content_scaffold.dart';
import 'chat_list_screen.dart';
import 'module_admin_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final _trainingService = TrainingService();
  final _checklistService = ChecklistService();

  late Future<List<Module>> _modulesFuture;
  late Future<int> _checklistAverageFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _trainingService.fetchModules(onError: _showApiError);
    _checklistAverageFuture = _loadChecklistAverage();
  }

  Future<int> _loadChecklistAverage() async {
    final sections = await _checklistService.fetchSections(
      onError: _showApiError,
    );
    if (sections.isEmpty) return 0;
    final total = sections.fold<int>(
      0,
      (sum, section) => sum + section.percentage,
    );
    return (total / sections.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.instance.currentUser;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return AppShell(
        title: 'Panel de gestion',
        subtitle: 'Gestion operativa de SST para escritorio',
        items: _buildShellItems(context),
        body: DesktopContentScaffold(
          sidePanel: _ManagerInsightsPanel(
            userName: user?.name ?? 'Invitado',
            email: user?.email ?? '',
            checklistAverageFuture: _checklistAverageFuture,
            modulesFuture: _modulesFuture,
          ),
          child: _ManagerDashboardBody(
            modulesFuture: _modulesFuture,
            checklistAverageFuture: _checklistAverageFuture,
            onOpenChecklist: () => openChecklistExperience(context),
            onOpenModules: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModuleAdminScreen(),
                ),
              );
            },
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
          _RoleHeader(
            title: 'Panel de gestion',
            subtitle: 'Gestion operativa de SST',
            userName: user?.name ?? 'Invitado',
            email: user?.email ?? '',
          ),
          Expanded(
            child: Container(
              color: AppColors.bgSlate100,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: _ManagerDashboardBody(
                    modulesFuture: _modulesFuture,
                    checklistAverageFuture: _checklistAverageFuture,
                    onOpenChecklist: () => openChecklistExperience(context),
                    onOpenModules: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModuleAdminScreen(),
                        ),
                      );
                    },
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
      const SnackBar(
        content: Text('No se pudieron cargar los datos de gestion'),
      ),
    );
  }

  List<AppShellItem> _buildShellItems(BuildContext context) {
    return [
      AppShellItem(
        label: 'Resumen',
        icon: Icons.dashboard_outlined,
        isSelected: true,
        onTap: () {},
      ),
      AppShellItem(
        label: 'Checklist',
        icon: Icons.checklist_outlined,
        onTap: () => openChecklistExperience(context),
      ),
      AppShellItem(
        label: 'Modulos',
        icon: Icons.dashboard_customize_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ModuleAdminScreen()),
          );
        },
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

class _ManagerDashboardBody extends StatelessWidget {
  const _ManagerDashboardBody({
    required this.modulesFuture,
    required this.checklistAverageFuture,
    required this.onOpenChecklist,
    required this.onOpenModules,
    required this.onOpenChat,
    this.dense = false,
  });

  final Future<List<Module>> modulesFuture;
  final Future<int> checklistAverageFuture;
  final VoidCallback onOpenChecklist;
  final VoidCallback onOpenModules;
  final VoidCallback onOpenChat;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spacing = dense ? 20.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(dense ? 0 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: checklistAverageFuture,
                  builder: (context, snapshot) => _MetricCard(
                    title: 'Checklist promedio',
                    value: '${snapshot.data ?? 0}%',
                    subtitle: 'Estado general del sistema',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<List<Module>>(
                  future: modulesFuture,
                  builder: (context, snapshot) => _MetricCard(
                    title: 'Modulos visibles',
                    value: '${snapshot.data?.length ?? 0}',
                    subtitle: 'Base para gestion y asignacion',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          const Text(
            'Acciones principales',
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
              _DashboardAction(
                icon: Icons.checklist,
                color: AppColors.primaryBlue,
                title: 'Checklist',
                subtitle: 'Revisar cumplimiento',
                onTap: onOpenChecklist,
              ),
              _DashboardAction(
                icon: Icons.dashboard_customize,
                color: AppColors.modulePurple,
                title: 'Gestion de modulos',
                subtitle: 'Crear y asignar',
                onTap: onOpenModules,
              ),
              _DashboardAction(
                icon: Icons.forum,
                color: AppColors.statusGreen,
                title: 'Mensajes',
                subtitle: 'Chat interno',
                onTap: onOpenChat,
              ),
            ],
          ),
          SizedBox(height: spacing),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderGray200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contexto del rol',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGray900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Esta vista prioriza gestion y asignacion. No muestra experiencia de alumno ni accesos para rendir evaluaciones.',
                  style: TextStyle(color: AppColors.textGray600, height: 1.5),
                ),
              ],
            ),
          ),
          if (dense) ...[
            const SizedBox(height: 20),
            FutureBuilder<List<Module>>(
              future: modulesFuture,
              builder: (context, snapshot) {
                final modules = snapshot.data ?? const <Module>[];
                final highlighted = modules.take(3).toList();
                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderGray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modulos con visibilidad inmediata',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (highlighted.isEmpty)
                        const Text(
                          'No hay modulos disponibles todavia.',
                          style: TextStyle(color: AppColors.textGray600),
                        )
                      else
                        ...highlighted.map(
                          (module) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: module.color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      module.icon,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    module.title,
                                    style: const TextStyle(
                                      color: AppColors.textGray900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagerInsightsPanel extends StatelessWidget {
  const _ManagerInsightsPanel({
    required this.userName,
    required this.email,
    required this.checklistAverageFuture,
    required this.modulesFuture,
  });

  final String userName;
  final String email;
  final Future<int> checklistAverageFuture;
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
                'Resumen ejecutivo',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Indicadores clave para gestion y seguimiento del sistema.',
                style: TextStyle(color: AppColors.textOnDarkMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen rapido',
                style: TextStyle(
                  color: AppColors.textGray900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<int>(
                future: checklistAverageFuture,
                builder: (context, snapshot) => _PanelStat(
                  label: 'Checklist promedio',
                  value: '${snapshot.data ?? 0}%',
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Module>>(
                future: modulesFuture,
                builder: (context, snapshot) => _PanelStat(
                  label: 'Modulos visibles',
                  value: '${snapshot.data?.length ?? 0}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelStat extends StatelessWidget {
  const _PanelStat({required this.label, required this.value});

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

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.email,
  });

  final String title;
  final String subtitle;
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textOnDarkMuted),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
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
