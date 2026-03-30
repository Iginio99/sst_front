import 'package:flutter/material.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/app_hero_header.dart';
import '../widgets/app_state_views.dart';
import '../widgets/desktop_content_scaffold.dart';
import '../widgets/access_denied_view.dart';
import 'lesson_detail_screen.dart';
import 'quiz_screen.dart';

class LessonsScreen extends StatefulWidget {
  final Module module;

  const LessonsScreen({super.key, required this.module});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _trainingService = TrainingService();
  late Future<ModuleLessonsResponse> _lessonsFuture;
  Lesson? _selectedLesson;

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _trainingService.fetchModuleLessons(
      widget.module.id,
      onError: _showApiError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = SessionManager.instance.access;
    if (!access.canStudy) {
      return const AccessDeniedView(
        title: 'Vista no disponible',
        message:
            'Las lecciones solo deben verse desde la experiencia de aprendizaje.',
      );
    }
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final contentWidth = isWide ? 920.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              color: AppColors.bgSlate100,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: FutureBuilder<ModuleLessonsResponse>(
                    future: _lessonsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const AppLoadingView(
                          label: 'Cargando lecciones',
                        );
                      }
                      if (snapshot.hasError) {
                        return AppMessageCard(
                          title: 'No se pudo cargar el modulo',
                          message:
                              'Error al cargar lecciones: ${snapshot.error}',
                          icon: Icons.menu_book_outlined,
                          iconColor: AppColors.moduleOrange,
                        );
                      }

                      final module = snapshot.data?.module ?? widget.module;
                      final lessons =
                          snapshot.data?.lessons ?? const <Lesson>[];
                      if (isDesktop && lessons.isNotEmpty) {
                        _selectedLesson ??= lessons.first;
                      }
                      final hasLessons = lessons.isNotEmpty;
                      final canTakeQuiz = access.canTakeQuiz;

                      if (isDesktop) {
                        return DesktopContentScaffold(
                          padding: const EdgeInsets.all(20),
                          sidePanel: _buildDesktopLessonPanel(
                            context,
                            module,
                            canTakeQuiz,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (module.dueToChecklist) _buildChecklistAlert(),
                              if (module.dueToChecklist)
                                const SizedBox(height: 16),
                              Expanded(
                                child: hasLessons
                                    ? ListView(
                                        children: [
                                          ...lessons.asMap().entries.map((
                                            entry,
                                          ) {
                                            final index = entry.key;
                                            final lesson = entry.value;
                                            return _buildLessonCard(
                                              context,
                                              lesson,
                                              index + 1,
                                              module,
                                              isDesktop: true,
                                              isSelected:
                                                  _selectedLesson?.id ==
                                                  lesson.id,
                                            );
                                          }),
                                        ],
                                      )
                                    : _buildEmptyLessonsState(module),
                              ),
                            ],
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: sidePadding,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            if (module.dueToChecklist) _buildChecklistAlert(),
                            if (hasLessons)
                              ...lessons.asMap().entries.map((entry) {
                                final index = entry.key;
                                final lesson = entry.value;
                                return _buildLessonCard(
                                  context,
                                  lesson,
                                  index + 1,
                                  module,
                                );
                              })
                            else
                              _buildEmptyLessonsState(module),
                            if (hasLessons && module.quizRequired) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: canTakeQuiz
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  QuizScreen(module: module),
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.moduleAmber,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.emoji_events, size: 22),
                                      SizedBox(width: 12),
                                      Text(
                                        'Realizar Evaluacion Final',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!canTakeQuiz)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Tu rol no tiene permiso para rendir quiz en este entorno.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGray600,
                                    ),
                                  ),
                                ),
                            ],
                          ],
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

  Widget _buildChecklistAlert() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgRed50,
        border: Border.all(color: AppColors.borderRed300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.warning, color: AppColors.statusRed, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este modulo es requerido por el checklist. Completa las lecciones y el quiz.',
              style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final module = widget.module;
    return AppHeroHeader(
      title: module.title,
      subtitle: '${module.description}\n${module.lessons} lecciones',
      backLabel: 'Volver a modulos',
      onBack: () => Navigator.pop(context),
      leading: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: module.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: module.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(module.icon, style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }

  Widget _buildEmptyLessonsState(Module module) {
    final message = module.lessons > 0
        ? 'No se pudieron cargar las lecciones de este modulo. Verifica la API o vuelve a intentarlo.'
        : 'Este modulo no tiene lecciones disponibles por ahora.';

    return AppMessageCard(
      title: 'Sin lecciones disponibles',
      message: message,
      icon: Icons.playlist_remove,
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    Lesson lesson,
    int number,
    Module module, {
    bool isDesktop = false,
    bool isSelected = false,
  }) {
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (lesson.type) {
      case 'video':
        typeIcon = Icons.play_circle_filled;
        typeColor = AppColors.statusRed;
        typeLabel = 'Video';
        break;
      case 'document':
        typeIcon = Icons.description;
        typeColor = AppColors.primaryBlue;
        typeLabel = 'Lectura';
        break;
      case 'interactive':
        typeIcon = Icons.touch_app;
        typeColor = AppColors.modulePurple;
        typeLabel = 'Interactivo';
        break;
      default:
        typeIcon = Icons.article;
        typeColor = AppColors.statusGray;
        typeLabel = 'Contenido';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : AppColors.borderGray200,
          width: isSelected ? 2 : 1,
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
          if (isDesktop) {
            setState(() {
              _selectedLesson = lesson;
            });
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  LessonDetailScreen(lesson: lesson, module: module),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    lesson.coverUrl ?? '',
                    width: double.infinity,
                    height: 144,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 144,
                        color: AppColors.bgGray100,
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: AppColors.textGray400,
                        ),
                      );
                    },
                  ),
                ),
                if (lesson.completed)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.statusGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lesson.duration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              typeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: lesson.completed
                          ? AppColors.statusGreen
                          : AppColors.bgGray100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: lesson.completed
                          ? [
                              BoxShadow(
                                color: AppColors.statusGreen.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: lesson.completed
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              '$number',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textGray900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textGray400,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildDesktopLessonPanel(
    BuildContext context,
    Module module,
    bool canTakeQuiz,
  ) {
    final lesson = _selectedLesson;
    if (lesson == null) {
      return _buildEmptyLessonsState(module);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray200),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                lesson.coverUrl ?? '',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: AppColors.bgGray100,
                    child: const Icon(
                      Icons.image,
                      size: 48,
                      color: AppColors.textGray400,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textGray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              module.title,
              style: const TextStyle(color: AppColors.textGray600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DesktopMetaPill(
                  icon: Icons.access_time,
                  label: lesson.duration,
                  color: AppColors.primaryBlue,
                ),
                _DesktopMetaPill(
                  icon: lesson.completed
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                  label: lesson.completed ? 'Completada' : 'Pendiente',
                  color: lesson.completed
                      ? AppColors.statusGreen
                      : AppColors.modulePurple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vista previa de contenido',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textGray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revisa la informacion principal de la leccion antes de abrir el detalle.',
              style: const TextStyle(color: AppColors.textGray600, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LessonDetailScreen(lesson: lesson, module: module),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir detalle'),
              ),
            ),
            if (module.quizRequired) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgAmber50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderAmber300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evaluacion final',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canTakeQuiz
                          ? 'Cuando termines la ruta puedes rendir el quiz del modulo.'
                          : 'Tu rol no tiene permiso para rendir quiz en este entorno.',
                      style: const TextStyle(
                        color: AppColors.textGray600,
                        height: 1.4,
                      ),
                    ),
                    if (canTakeQuiz) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(module: module),
                            ),
                          );
                        },
                        child: const Text('Ir al quiz'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopMetaPill extends StatelessWidget {
  const _DesktopMetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
