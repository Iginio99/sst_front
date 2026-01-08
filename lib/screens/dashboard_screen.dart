import 'package:flutter/material.dart';
import '../models/module.dart';
import '../models/checklist_section.dart';
import '../services/training_service.dart';
import '../services/checklist_service.dart';
import '../utils/colors.dart';
import '../services/session_service.dart';
import '../models/auth.dart';
import 'checklist_screen.dart';
import 'modules_screen.dart';
import 'module_admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _trainingService = TrainingService();
  final _checklistService = ChecklistService();

  late Future<List<Module>> _modulesFuture;
  late Future<List<ChecklistSection>> _sectionsFuture;
  UserProfile? get _user => SessionManager.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _trainingService.fetchModules(onError: _showApiError);
    _sectionsFuture = _checklistService.fetchSections(onError: _showApiError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: FutureBuilder<List<Module>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar modulos: ${snapshot.error}'));
                }
                final modules = snapshot.data ?? Module.getSampleData();
                final requiredModules = modules.where((m) => m.dueToChecklist && !m.quizCompleted).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChecklistSummary(),
                      const SizedBox(height: 24),
                      const Text(
                        'Acceso Rapido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickAccessGrid(context),
                      const SizedBox(height: 24),
                      const Text(
                        'Capacitaciones Requeridas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGray900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (requiredModules.isEmpty)
                        const Text(
                          'No hay capacitaciones obligatorias pendientes.',
                          style: TextStyle(color: AppColors.textGray600),
                        )
                      else
                        ...requiredModules.map((m) => _buildRequiredModule(context, m)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF2563EB),
            Color(0xFF0891B2),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFF67E8F9), size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sistema SST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _user?.email ?? 'Gestion Integral',
                            style: const TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Usuario',
                              style: TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _user?.name ?? 'Invitado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              (_user?.roles ?? []).join(', '),
                              style: const TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderCard(
                      title: 'Checklist Completado',
                      child: FutureBuilder<List<ChecklistSection>>(
                        future: _sectionsFuture,
                        builder: (context, snapshot) {
                          final sections = snapshot.data;
                          final percent = _calcChecklistPercent(sections);
                          return Text(
                            '$percent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHeaderCard(
                      title: 'Modulos Aprobados',
                      child: FutureBuilder<List<Module>>(
                        future: _modulesFuture,
                        builder: (context, snapshot) {
                          final modules = snapshot.data ?? [];
                          final approved = modules.where((m) => m.quizCompleted).length;
                          return Text(
                            '$approved/${modules.isEmpty ? 6 : modules.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildChecklistSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgRed50,
        border: Border.all(color: AppColors.borderRed300, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: AppColors.statusRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Accion Requerida',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Consulta las secciones con deficiencias y asigna capacitaciones.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChecklistScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusRed,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver Checklist',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    final items = <Widget>[];
    if (SessionManager.instance.hasPermission('checklist.view')) {
      items.add(
        _buildQuickAccessCard(
          context,
          icon: Icons.checklist,
          color: AppColors.primaryBlue,
          title: 'Checklist',
          subtitle: 'Estado actual',
          onTap: () {
            _guardPermission(
              'checklist.view',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChecklistScreen(),
                ),
              ),
            );
          },
        ),
      );
    }
    if (SessionManager.instance.hasPermission('training.view')) {
      items.add(
        _buildQuickAccessCard(
          context,
          icon: Icons.school,
          color: AppColors.statusGreen,
          title: 'Capacitacion',
          subtitle: 'Modulos asignados',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModulesScreen(),
              ),
            );
          },
        ),
      );
    }
    if (SessionManager.instance.hasPermission('training.manage') ||
        SessionManager.instance.hasPermission('training.assign') ||
        SessionManager.instance.hasPermission('training.monitor')) {
      items.add(
        _buildQuickAccessCard(
          context,
          icon: Icons.dashboard_customize,
          color: AppColors.modulePurple,
          title: 'Admin Modulos',
          subtitle: 'Crear, asignar, monitorear',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ModuleAdminScreen(),
              ),
            );
          },
        ),
      );
    }
    if (items.isEmpty) {
      return const Text('No hay accesos rapidos para este rol');
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items,
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textGray900,
              ),
            ),
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
    );
  }

  Widget _buildRequiredModule(BuildContext context, Module module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.statusRed, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModulesScreen(selectedModule: module),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: module.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  module.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textGray900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.bgRed50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Obligatorio',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
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
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textGray400),
          ],
        ),
      ),
    );
  }

  int _calcChecklistPercent(List<ChecklistSection>? sections) {
    if (sections == null || sections.isEmpty) return 0;
    final total = sections.fold<int>(0, (sum, s) => sum + s.percentage);
    return (total / sections.length).round();
  }

  void _showApiError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocurrio un fallo al cargar la API'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _guardPermission(String permission, VoidCallback onAllowed) {
    if (SessionManager.instance.hasPermission(permission)) {
      onAllowed();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tienes permiso para esta accion ($permission)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
