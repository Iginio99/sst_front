import 'package:flutter/material.dart';
import '../models/module.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../widgets/app_hero_header.dart';
import '../widgets/app_state_views.dart';
import '../widgets/access_denied_view.dart';
import 'lessons_screen.dart';

class ModulesScreen extends StatefulWidget {
  final Module? selectedModule;

  const ModulesScreen({super.key, this.selectedModule});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  final _trainingService = TrainingService();
  late Future<List<Module>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _trainingService.fetchModules(onError: _showApiError);
  }

  @override
  Widget build(BuildContext context) {
    final access = SessionManager.instance.access;
    if (!access.canStudy) {
      return const AccessDeniedView(
        title: 'Vista no disponible',
        message:
            'Esta pantalla solo aplica para usuarios que cursan capacitaciones.',
      );
    }
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final contentWidth = isWide ? 920.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              color: AppColors.bgSlate100,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: FutureBuilder<List<Module>>(
                    future: _modulesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppLoadingView(label: 'Cargando modulos');
                      }
                      if (snapshot.hasError) {
                        return AppMessageCard(
                          title: 'No se pudo cargar la ruta',
                          message: 'Error al cargar modulos: ${snapshot.error}',
                          icon: Icons.menu_book_outlined,
                          iconColor: AppColors.moduleOrange,
                        );
                      }
                      final modules = snapshot.data ?? const <Module>[];
                      if (modules.isEmpty) {
                        return _buildEmptyState(
                          title: 'Sin modulos disponibles',
                          message:
                              'No tienes modulos asignados o no se pudieron cargar desde la API.',
                        );
                      }
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: sidePadding,
                          vertical: 20,
                        ),
                        child: Column(
                          children: modules
                              .map(
                                (module) => _buildModuleCard(
                                  context,
                                  module,
                                  isHighlighted:
                                      widget.selectedModule?.id == module.id,
                                ),
                              )
                              .toList(),
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

  Widget _buildHeader(BuildContext context) {
    return AppHeroHeader(
      title: 'Capacitaciones',
      subtitle: 'Completa los modulos y aprueba las evaluaciones',
      backLabel: 'Volver',
      onBack: () => Navigator.pop(context),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    Module module, {
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? AppColors.primaryBlue
              : AppColors.borderGray200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              builder: (context) => LessonsScreen(module: module),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: module.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: module.color.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        module.icon,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
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
                            fontSize: 16,
                            color: AppColors.textGray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textGray600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (module.dueToChecklist)
                        _badge('Obligatoria', AppColors.statusRed)
                      else
                        _badge('Recomendada', AppColors.primaryBlue),
                      const SizedBox(height: 8),
                      if (module.quizCompleted)
                        _badge('Quiz listo', AppColors.statusGreen),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: module.progress,
                        minHeight: 10,
                        backgroundColor: AppColors.bgGray100,
                        valueColor: AlwaysStoppedAnimation<Color>(module.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${module.completedLessons}/${module.lessons} lec.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGray700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    module.dueToChecklist
                        ? 'Requerido por checklist'
                        : 'Libre avance',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonsScreen(module: module),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text(
                      'Ver lecciones',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: AppColors.textGray500,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
