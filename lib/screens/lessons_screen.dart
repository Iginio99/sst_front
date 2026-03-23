import 'package:flutter/material.dart';
import '../models/module.dart';
import '../models/lesson.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import 'lesson_detail_screen.dart';
import 'quiz_screen.dart';
import '../services/session_service.dart';

class LessonsScreen extends StatefulWidget {
  final Module module;

  const LessonsScreen({Key? key, required this.module}) : super(key: key);

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _trainingService = TrainingService();
  late Future<ModuleLessonsResponse> _lessonsFuture;

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
    final isWide = MediaQuery.of(context).size.width >= 1000;
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
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error al cargar lecciones: ${snapshot.error}'));
                      }

                      final module = snapshot.data?.module ?? widget.module;
                      final lessons = snapshot.data?.lessons ?? Lesson.getSampleData();

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
                        child: Column(
                          children: [
                            if (module.dueToChecklist)
                              Container(
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
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ...lessons.asMap().entries.map((entry) {
                              final index = entry.key;
                              final lesson = entry.value;
                              return _buildLessonCard(context, lesson, index + 1, module);
                            }).toList(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!SessionManager.instance.hasPermission('training.quiz')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No tienes permiso para realizar quizzes')),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizScreen(module: module),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.moduleAmber,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildHeader() {
    final module = widget.module;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF0E7490),
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
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Volver a modulos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: module.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: module.color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        module.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: const TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          module.description,
                          style: const TextStyle(
                            color: AppColors.textOnDarkMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${module.lessons} lecciones',
                          style: const TextStyle(
                            color: AppColors.textOnDarkMuted,
                            fontSize: 12,
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
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, int number, Module module) {
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
        border: Border.all(color: AppColors.borderGray200),
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
              builder: (context) => LessonDetailScreen(lesson: lesson, module: module),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    lesson.image ?? '',
                    width: double.infinity,
                    height: 144,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 144,
                        color: AppColors.bgGray100,
                        child: const Icon(Icons.image, size: 48, color: AppColors.textGray400),
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
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, color: Colors.white, size: 14),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      color: lesson.completed ? AppColors.statusGreen : AppColors.bgGray100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: lesson.completed
                          ? [
                              BoxShadow(
                                color: AppColors.statusGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: lesson.completed
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
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
                  const Icon(Icons.chevron_right, color: AppColors.textGray400, size: 18),
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
}
