import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../models/module.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../services/session_service.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final Module module;

  const LessonDetailScreen({
    Key? key,
    required this.lesson,
    required this.module,
  }) : super(key: key);

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
    if (!SessionManager.instance.hasPermission('training.complete')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes permiso para marcar lecciones')),
      );
      return;
    }
    setState(() {
      _saving = true;
    });
    final result = await _trainingService.completeLesson(widget.lesson.id, completed: true);
    setState(() {
      _saving = false;
      if (result != null) _isCompleted = true;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result != null ? 'Leccion marcada como completada' : 'No se pudo guardar, intenta de nuevo'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final module = widget.module;
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final contentWidth = isWide ? 880.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Image.network(
                lesson.image ?? '',
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 260,
                    color: AppColors.bgGray100,
                    child: const Icon(Icons.image, size: 64, color: AppColors.textGray400),
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
                      Colors.black.withOpacity(0.6),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.arrow_back, color: Colors.white, size: 18),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
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
                        const Text(
                          'El liderazgo visible en seguridad y salud en el trabajo es fundamental para crear una cultura preventiva efectiva. Los lideres deben demostrar compromiso real con la SST mediante acciones concretas y participacion activa.',
                          style: TextStyle(
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
                            children: const [
                              Icon(Icons.lightbulb, color: AppColors.primaryBlue, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Concepto clave: el liderazgo en SST no es solo cumplir con requisitos legales, sino inspirar y motivar a todo el equipo a trabajar de forma segura.',
                                  style: TextStyle(
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
                              child: ElevatedButton(
                                onPressed: _saving || _isCompleted ? null : _markCompleted,
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
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.check, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Marcar como completada',
                                            style: TextStyle(
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
                      ],
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

  Widget _buildTag({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
}
