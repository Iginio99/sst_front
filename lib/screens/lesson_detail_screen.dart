import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lesson.dart';
import '../models/module.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../services/session_service.dart';
import '../widgets/desktop_content_scaffold.dart';
import '../widgets/access_denied_view.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final Module module;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.module,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _trainingService = TrainingService();
  bool _isCompleted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.lesson.completed;
  }

  Future<void> _markCompleted() async {
    if (!SessionManager.instance.access.canCompleteLessons) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para marcar lecciones'),
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    final result = await _trainingService.completeLesson(
      widget.lesson.id,
      completed: true,
    );
    setState(() {
      _saving = false;
      if (result != null) _isCompleted = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null
              ? 'Leccion marcada como completada'
              : 'No se pudo guardar, intenta de nuevo',
        ),
      ),
    );
  }

  Future<void> _openLessonContent() async {
    final rawLink = widget.lesson.primaryLink;
    if (rawLink == null || rawLink.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta leccion todavia no tiene contenido'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La URL del contenido no es valida')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el contenido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionManager.instance.access.canStudy) {
      return const AccessDeniedView(
        title: 'Vista no disponible',
        message:
            'Esta pantalla solo aplica para usuarios en experiencia de aprendizaje.',
      );
    }
    final canCompleteLessons =
        SessionManager.instance.access.canCompleteLessons;
    final lesson = widget.lesson;
    final module = widget.module;
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final contentWidth = isWide ? 880.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.network(
                lesson.coverUrl ?? '',
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 260,
                    color: AppColors.bgGray100,
                    child: const Icon(
                      Icons.image,
                      size: 64,
                      color: AppColors.textGray400,
                    ),
                  );
                },
              ),
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Volver',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Completada',
                                style: TextStyle(
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
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: AppColors.bgSlate50,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: sidePadding,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: isDesktop
                        ? DesktopContentScaffold(
                            padding: EdgeInsets.zero,
                            sidePanel: _buildDesktopSidePanel(
                              lesson: lesson,
                              module: module,
                              canCompleteLessons: canCompleteLessons,
                            ),
                            child: _buildMainContent(
                              lesson: lesson,
                              module: module,
                              canCompleteLessons: canCompleteLessons,
                              compactActions: true,
                            ),
                          )
                        : _buildMainContent(
                            lesson: lesson,
                            module: module,
                            canCompleteLessons: canCompleteLessons,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent({
    required Lesson lesson,
    required Module module,
    required bool canCompleteLessons,
    bool compactActions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTag(
              icon: Icons.access_time,
              label: lesson.duration,
              color: AppColors.primaryBlue,
            ),
            _buildTag(
              icon: Icons.shield,
              label: module.title,
              color: module.color,
            ),
            if ((lesson.contentMimeType ?? '').isNotEmpty)
              _buildTag(
                icon: Icons.insert_drive_file_outlined,
                label: lesson.contentMimeType!,
                color: AppColors.modulePurple,
              ),
            if (lesson.contentSizeBytes != null)
              _buildTag(
                icon: Icons.data_usage,
                label: _formatFileSize(lesson.contentSizeBytes!),
                color: AppColors.textGray600,
              ),
            _buildTag(
              icon: lesson.contentMode == 'external_url'
                  ? Icons.link
                  : Icons.cloud_done_outlined,
              label: lesson.contentMode == 'external_url'
                  ? 'URL externa'
                  : 'Archivo en storage',
              color: AppColors.statusGreen,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textGray900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          (lesson.description ?? '').trim().isNotEmpty
              ? lesson.description!
              : 'Esta leccion ya puede consumir contenido real desde storage o una URL externa.',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textGray700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgBlue50,
            border: const Border(
              left: BorderSide(color: AppColors.primaryBlue, width: 4),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lesson.hasContent
                      ? 'El contenido principal ya esta vinculado a esta leccion y se puede abrir desde el boton inferior.'
                      : 'Esta leccion todavia no tiene un archivo o URL asociado. Debe configurarse desde la consola de gestion.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: lesson.hasContent ? _openLessonContent : null,
                icon: Icon(
                  lesson.type == 'video'
                      ? Icons.play_circle_outline
                      : Icons.open_in_new,
                ),
                label: Text(
                  lesson.type == 'document'
                      ? 'Ver documento'
                      : lesson.type == 'video'
                      ? 'Abrir video'
                      : 'Abrir contenido',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving || _isCompleted || !canCompleteLessons
                    ? null
                    : _markCompleted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            compactActions
                                ? 'Completar leccion'
                                : 'Marcar como completada',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        if (!canCompleteLessons)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Tu rol puede ver esta leccion, pero no marcarla como completada.',
              style: TextStyle(fontSize: 12, color: AppColors.textGray600),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopSidePanel({
    required Lesson lesson,
    required Module module,
    required bool canCompleteLessons,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            module.title,
            style: const TextStyle(
              color: AppColors.textGray900,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: const TextStyle(color: AppColors.textGray600, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Duracion', lesson.duration),
          const SizedBox(height: 8),
          _buildInfoRow('Estado', _isCompleted ? 'Completada' : 'Pendiente'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Quiz del modulo',
            module.quizRequired ? 'Requerido' : 'No requerido',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgBlue50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderBlue200),
            ),
            child: const Text(
              'Consulta el contexto del modulo y el estado actual de la leccion.',
              style: TextStyle(color: AppColors.textGray700, height: 1.4),
            ),
          ),
          if (!canCompleteLessons) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgAmber50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderAmber300),
              ),
              child: const Text(
                'Tu rol solo tiene acceso de lectura en esta leccion.',
                style: TextStyle(color: AppColors.textGray700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGray600)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textGray900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
