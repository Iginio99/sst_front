import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/module.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../widgets/access_denied_view.dart';

class LessonAdminScreen extends StatefulWidget {
  const LessonAdminScreen({super.key, required this.module});

  final Module module;

  @override
  State<LessonAdminScreen> createState() => _LessonAdminScreenState();
}

enum _FeedbackTone { info, success, error }

class _LessonAdminScreenState extends State<LessonAdminScreen> {
  final _trainingService = TrainingService();
  late Future<ModuleLessonsResponse> _lessonsFuture;
  bool _busy = false;
  String? _busyLabel;
  _FeedbackTone _feedbackTone = _FeedbackTone.info;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _lessonsFuture = _trainingService.fetchModuleLessons(widget.module.id);
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionManager.instance.hasPermission('training.manage')) {
      return const AccessDeniedView(
        title: 'Gestion restringida',
        message: 'Tu rol no puede gestionar lecciones.',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Lecciones: ${widget.module.title}'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _busy
                ? null
                : () {
                    _setFeedback(
                      _FeedbackTone.info,
                      'Recargando la lista de lecciones del modulo...',
                    );
                    setState(_reload);
                  },
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _busy ? null : () => _openLessonForm(),
            icon: const Icon(Icons.add),
            tooltip: 'Nueva leccion',
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<ModuleLessonsResponse>(
            future: _lessonsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final lessons = snapshot.data?.lessons ?? const <Lesson>[];
              if (lessons.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (_feedbackMessage != null) _buildFeedbackCard(),
                    const SizedBox(height: 48),
                    const Icon(
                      Icons.library_books_outlined,
                      size: 52,
                      color: AppColors.textGray400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Este modulo todavia no tiene lecciones.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea la primera leccion y luego sube portada y contenido para confirmar el flujo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _openLessonForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Crear primera leccion'),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lessons.length + (_feedbackMessage == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (_feedbackMessage != null && index == 0) {
                    return _buildFeedbackCard();
                  }
                  final lesson =
                      lessons[_feedbackMessage == null ? index : index - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.bgBlue50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${lesson.displayOrder}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${lesson.type} · ${lesson.duration}',
                                      style: const TextStyle(
                                        color: AppColors.textGray600,
                                      ),
                                    ),
                                    if ((lesson.description ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          lesson.description!,
                                          style: const TextStyle(
                                            color: AppColors.textGray700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _MetaBadge(
                                label: lesson.coverUrl != null
                                    ? 'Portada lista'
                                    : 'Sin portada',
                                color: lesson.coverUrl != null
                                    ? AppColors.statusGreen
                                    : AppColors.textGray600,
                              ),
                              _MetaBadge(
                                label: lesson.hasContent
                                    ? (lesson.contentMode == 'external_url'
                                          ? 'URL externa'
                                          : 'Archivo cargado')
                                    : 'Sin contenido',
                                color: lesson.hasContent
                                    ? AppColors.primaryBlue
                                    : AppColors.moduleAmber,
                              ),
                              if ((lesson.contentMimeType ?? '').isNotEmpty)
                                _MetaBadge(
                                  label: lesson.contentMimeType!,
                                  color: AppColors.modulePurple,
                                ),
                              if (lesson.contentSizeBytes != null)
                                _MetaBadge(
                                  label: _formatFileSize(
                                    lesson.contentSizeBytes!,
                                  ),
                                  color: AppColors.textGray600,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                label: const Text('Editar'),
                                avatar: const Icon(Icons.edit, size: 18),
                                onPressed: _busy
                                    ? null
                                    : () => _openLessonForm(lesson: lesson),
                              ),
                              ActionChip(
                                label: const Text('Subir portada'),
                                avatar: const Icon(
                                  Icons.image_outlined,
                                  size: 18,
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => _uploadCover(lesson),
                              ),
                              ActionChip(
                                label: const Text('Subir contenido'),
                                avatar: const Icon(Icons.upload_file, size: 18),
                                onPressed: _busy
                                    ? null
                                    : () => _uploadContent(lesson),
                              ),
                              ActionChip(
                                label: const Text('Eliminar'),
                                avatar: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.statusRed,
                                ),
                                onPressed: _busy
                                    ? null
                                    : () => _deleteLesson(lesson),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.15),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          _busyLabel ?? 'Procesando...',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No cierres esta pantalla hasta que termine la operacion.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openLessonForm({Lesson? lesson}) async {
    final titleCtrl = TextEditingController(text: lesson?.title ?? '');
    final durationCtrl = TextEditingController(text: lesson?.duration ?? '');
    final descriptionCtrl = TextEditingController(
      text: lesson?.description ?? '',
    );
    final displayOrderCtrl = TextEditingController(
      text: (lesson?.displayOrder ?? 1).toString(),
    );
    final externalUrlCtrl = TextEditingController(
      text: lesson?.externalUrl ?? '',
    );

    String type = lesson?.type ?? 'video';
    String contentMode = lesson?.contentMode ?? 'upload';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(lesson == null ? 'Nueva leccion' : 'Editar leccion'),
          content: StatefulBuilder(
            builder: (context, setInner) {
              return SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Titulo'),
                      ),
                      TextField(
                        controller: durationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Duracion',
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(
                            value: 'video',
                            child: Text('Video'),
                          ),
                          DropdownMenuItem(
                            value: 'document',
                            child: Text('Documento'),
                          ),
                          DropdownMenuItem(
                            value: 'interactive',
                            child: Text('Interactivo'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setInner(() => type = value);
                          }
                        },
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: contentMode,
                        decoration: const InputDecoration(
                          labelText: 'Modo de contenido',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'upload',
                            child: Text('Archivo subido'),
                          ),
                          DropdownMenuItem(
                            value: 'external_url',
                            child: Text('URL externa'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setInner(() => contentMode = value);
                          }
                        },
                      ),
                      if (contentMode == 'external_url')
                        TextField(
                          controller: externalUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL externa',
                            hintText: 'https://...',
                          ),
                        ),
                      TextField(
                        controller: displayOrderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Orden de visualizacion',
                        ),
                      ),
                      TextField(
                        controller: descriptionCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final payload = LessonPayload(
                  title: titleCtrl.text.trim(),
                  duration: durationCtrl.text.trim(),
                  type: type,
                  description: descriptionCtrl.text.trim().isEmpty
                      ? null
                      : descriptionCtrl.text.trim(),
                  displayOrder: int.tryParse(displayOrderCtrl.text.trim()) ?? 1,
                  contentMode: contentMode,
                  externalUrl: externalUrlCtrl.text.trim().isEmpty
                      ? null
                      : externalUrlCtrl.text.trim(),
                );

                final result = await _runBusy(
                  lesson == null
                      ? 'Guardando nueva leccion...'
                      : 'Actualizando leccion...',
                  () => lesson == null
                      ? _trainingService.createLesson(widget.module.id, payload)
                      : _trainingService.updateLesson(lesson.id, payload),
                );
                if (!mounted) {
                  return;
                }
                if (!result.success) {
                  _setFeedback(
                    _FeedbackTone.error,
                    result.errorMessage ?? 'No se pudo guardar la leccion.',
                  );
                  return;
                }
                _setFeedback(
                  _FeedbackTone.success,
                  lesson == null
                      ? 'La leccion "${payload.title}" se creo correctamente. Ahora puedes subir portada y contenido.'
                      : 'La leccion "${payload.title}" se actualizo correctamente.',
                );
                Navigator.of(context).pop(true);
              },
              child: Text(lesson == null ? 'Crear' : 'Guardar cambios'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      setState(_reload);
    }
  }

  Future<void> _uploadCover(Lesson lesson) async {
    final file = await _pickFile(
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) {
      _setFeedback(
        _FeedbackTone.info,
        'No se selecciono ninguna portada. La operacion fue cancelada.',
      );
      return;
    }
    _setFeedback(
      _FeedbackTone.info,
      'Portada seleccionada: ${file.name}. Se iniciara la subida para "${lesson.title}".',
    );
    final updated = await _runBusy(
      'Subiendo portada: ${file.name}',
      () => _trainingService.uploadLessonCover(lesson.id, file),
    );
    _showResult(
      updated.success,
      updated.success
          ? 'La portada "${file.name}" se subio correctamente para "${lesson.title}".'
          : (updated.errorMessage ??
                'No se pudo subir la portada "${file.name}".'),
      updated.success ? _FeedbackTone.success : _FeedbackTone.error,
    );
    if (updated.success) {
      setState(_reload);
    }
  }

  Future<void> _uploadContent(Lesson lesson) async {
    final extensions = switch (lesson.type) {
      'video' => const ['mp4', 'webm', 'mov'],
      'document' => const ['pdf', 'docx', 'pptx', 'xlsx'],
      _ => const ['pdf', 'txt', 'json'],
    };
    final file = await _pickFile(allowedExtensions: extensions);
    if (file == null) {
      _setFeedback(
        _FeedbackTone.info,
        'No se selecciono ningun archivo de contenido. La operacion fue cancelada.',
      );
      return;
    }
    _setFeedback(
      _FeedbackTone.info,
      'Archivo seleccionado: ${file.name}. Se iniciara la subida para "${lesson.title}".',
    );
    final updated = await _runBusy(
      'Subiendo contenido: ${file.name}',
      () => _trainingService.uploadLessonContent(lesson.id, file),
    );
    _showResult(
      updated.success,
      updated.success
          ? 'El archivo "${file.name}" se subio correctamente en "${lesson.title}".'
          : (updated.errorMessage ??
                'No se pudo subir el archivo "${file.name}".'),
      updated.success ? _FeedbackTone.success : _FeedbackTone.error,
    );
    if (updated.success) {
      setState(_reload);
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar leccion'),
        content: Text(
          'Seguro que deseas eliminar "${lesson.title}"? Esta accion tambien quitara sus archivos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      _setFeedback(
        _FeedbackTone.info,
        'La eliminacion de "${lesson.title}" fue cancelada.',
      );
      return;
    }
    final deleted = await _runBusy(
      'Eliminando leccion...',
      () => _trainingService.deleteLesson(lesson.id),
    );
    _showResult(
      deleted.success,
      deleted.success
          ? 'La leccion "${lesson.title}" se elimino correctamente.'
          : (deleted.errorMessage ??
                'No se pudo eliminar la leccion "${lesson.title}".'),
      deleted.success ? _FeedbackTone.success : _FeedbackTone.error,
    );
    if (deleted.success) {
      setState(_reload);
    }
  }

  Future<UploadFilePayload?> _pickFile({
    required List<String> allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    final bytes = file.bytes ?? Uint8List(0);
    if (bytes.isEmpty) {
      _setFeedback(
        _FeedbackTone.error,
        'El archivo "${file.name}" no pudo leerse o llego vacio desde el navegador.',
      );
      return null;
    }
    return UploadFilePayload(name: file.name, bytes: bytes, path: file.path);
  }

  Future<T> _runBusy<T>(String label, Future<T> Function() action) async {
    setState(() {
      _busy = true;
      _busyLabel = label;
    });
    try {
      return await action();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyLabel = null;
        });
      }
    }
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

  Widget _buildFeedbackCard() {
    final tone = _feedbackTone;
    final bg = switch (tone) {
      _FeedbackTone.success => const Color(0xFFECFDF3),
      _FeedbackTone.error => const Color(0xFFFEF2F2),
      _FeedbackTone.info => const Color(0xFFEFF6FF),
    };
    final border = switch (tone) {
      _FeedbackTone.success => AppColors.statusGreen,
      _FeedbackTone.error => AppColors.statusRed,
      _FeedbackTone.info => AppColors.primaryBlue,
    };
    final icon = switch (tone) {
      _FeedbackTone.success => Icons.check_circle,
      _FeedbackTone.error => Icons.error_outline,
      _FeedbackTone.info => Icons.info_outline,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedbackMessage ?? '',
              style: const TextStyle(color: AppColors.textGray900, height: 1.4),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _feedbackMessage = null;
              });
            },
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _setFeedback(_FeedbackTone tone, String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _feedbackTone = tone;
      _feedbackMessage = message;
    });
  }

  void _showResult(bool success, String message, _FeedbackTone tone) {
    if (!mounted) {
      return;
    }
    _setFeedback(tone, message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.statusGreen : AppColors.statusRed,
        content: Text(message),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
