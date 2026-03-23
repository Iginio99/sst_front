import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../models/auth.dart';
import '../models/module.dart';
import '../models/progress.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';

class ModuleAdminScreen extends StatefulWidget {
  const ModuleAdminScreen({super.key});

  @override
  State<ModuleAdminScreen> createState() => _ModuleAdminScreenState();
}

class _ModuleAdminScreenState extends State<ModuleAdminScreen> {
  final _trainingService = TrainingService();
  late Future<List<Module>> _modulesFuture;

  bool get _canManage => SessionManager.instance.hasPermission('training.manage');
  bool get _canAssign => SessionManager.instance.hasPermission('training.assign');
  bool get _canMonitor => SessionManager.instance.hasPermission('training.monitor');

  @override
  void initState() {
    super.initState();
    _modulesFuture = _trainingService.fetchModules(onError: _showError);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1100;
    final contentWidth = isWide ? 980.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de modulos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryBlue,
              onPressed: () => _openModuleForm(context),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Container(
        color: AppColors.bgSlate100,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: FutureBuilder<List<Module>>(
              future: _modulesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final modules = snapshot.data ?? [];
                if (modules.isEmpty) {
                  return const Center(child: Text('No hay modulos asignados para este rol.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _modulesFuture = _trainingService.fetchModules(onError: _showError);
                    });
                    await _modulesFuture;
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
                    itemCount: modules.length,
                    itemBuilder: (context, index) => _ModuleTile(
                      module: modules[index],
                      onEdit: _canManage ? () => _openModuleForm(context, module: modules[index]) : null,
                      onDelete: _canManage ? () => _confirmDelete(modules[index]) : null,
                      onAssign: _canAssign ? () => _openAssignment(modules[index]) : null,
                      onProgress: _canMonitor ? () => _openProgress(modules[index]) : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openModuleForm(BuildContext context, {Module? module}) {
    final titleCtrl = TextEditingController(text: module?.title ?? '');
    final descCtrl = TextEditingController(text: module?.description ?? '');
    final iconCtrl = TextEditingController(text: module?.icon ?? '');
    final colorCtrl = TextEditingController(text: module != null ? _colorToHex(module.color) : '#2563EB');
    final checklistCtrl =
        TextEditingController(text: module?.checklistSectionId != null ? module!.checklistSectionId.toString() : '');
    bool dueToChecklist = module?.dueToChecklist ?? false;
    bool quizRequired = module?.quizRequired ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(module == null ? 'Nuevo modulo' : 'Editar modulo'),
          content: StatefulBuilder(
            builder: (context, setInnerState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Titulo'),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Descripcion'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: iconCtrl,
                      decoration: const InputDecoration(labelText: 'Icono'),
                    ),
                    TextField(
                      controller: colorCtrl,
                      decoration: const InputDecoration(labelText: 'Color (hex #RRGGBB)'),
                    ),
                    TextField(
                      controller: checklistCtrl,
                      decoration: const InputDecoration(labelText: 'Checklist section ID (opcional)'),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text('Debido a checklist'),
                      value: dueToChecklist,
                      onChanged: (v) => setInnerState(() => dueToChecklist = v),
                    ),
                    SwitchListTile(
                      title: const Text('Quiz requerido'),
                      value: quizRequired,
                      onChanged: (v) => setInnerState(() => quizRequired = v),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final payload = ModulePayload(
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  icon: iconCtrl.text.trim(),
                  color: colorCtrl.text.trim().isEmpty ? '#2563EB' : colorCtrl.text.trim(),
                  dueToChecklist: dueToChecklist,
                  checklistSectionId: checklistCtrl.text.isEmpty ? null : int.tryParse(checklistCtrl.text),
                  quizRequired: quizRequired,
                );
                Navigator.pop(context);
                if (module == null) {
                  await _trainingService.createModule(payload);
                } else {
                  await _trainingService.updateModule(module.id, payload);
                }
                setState(() {
                  _modulesFuture = _trainingService.fetchModules(onError: _showError);
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(Module module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar modulo'),
        content: Text('Seguro que deseas eliminar "${module.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () async {
              Navigator.pop(context);
              await _trainingService.deleteModule(module.id);
              setState(() {
                _modulesFuture = _trainingService.fetchModules(onError: _showError);
              });
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAssignment(Module module) async {
    final assignable = await _trainingService.fetchAssignableUsers();
    final progress = await _trainingService.fetchModuleProgress(module.id);
    final current = progress?.users.map((p) => p.user.id).toSet() ?? <int>{};
    final selected = {...current};

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setInner) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Asignar modulo: ${module.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: ListView(
                    children: assignable
                        .map(
                          (u) => CheckboxListTile(
                            value: selected.contains(u.id),
                            title: Text(u.name),
                            subtitle: Text('${u.email} (${u.roles.join(", ")})'),
                            onChanged: (checked) {
                              setInner(() {
                                if (checked == true) {
                                  selected.add(u.id);
                                } else {
                                  selected.remove(u.id);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _trainingService.assignModule(module.id, selected.toList());
                    setState(() {
                      _modulesFuture = _trainingService.fetchModules(onError: _showError);
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  child: const Text('Guardar asignaciones'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _openProgress(Module module) async {
    final progress = await _trainingService.fetchModuleProgress(module.id);
    if (!mounted) return;
    if (progress == null || progress.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay asignaciones registradas para este modulo')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Progreso: ${progress.moduleTitle}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: progress.users
                .map(
                  (u) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.bgGray100,
                      child: Text(u.user.name.characters.first.toUpperCase()),
                    ),
                    title: Text(u.user.name),
                    subtitle: Text('${u.completedLessons}/${u.totalLessons} lecciones'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(u.quizCompleted ? 'Quiz aprobado' : 'Quiz pendiente',
                            style: TextStyle(
                              color: u.quizCompleted ? AppColors.statusGreen : AppColors.textGray600,
                              fontWeight: FontWeight.bold,
                            )),
                        if (u.lastScore != null) Text('Ultimo puntaje: ${u.lastScore}%'),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo cargar la informacion')),
    );
  }

  String _colorToHex(Color color) {
    final value = color.value.toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    this.onEdit,
    this.onDelete,
    this.onAssign,
    this.onProgress,
  });

  final Module module;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAssign;
  final VoidCallback? onProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(module.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _ActionChip(icon: Icons.edit, label: 'Editar', onTap: onEdit),
                _ActionChip(icon: Icons.people, label: 'Asignar', onTap: onAssign),
                _ActionChip(icon: Icons.analytics, label: 'Progreso', onTap: onProgress),
                _ActionChip(
                  icon: Icons.delete,
                  label: 'Eliminar',
                  onTap: onDelete,
                  color: AppColors.statusRed,
                ),
              ].where((chip) => chip.onTap != null).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color ?? AppColors.primaryBlue),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: (color ?? AppColors.primaryBlue).withOpacity(0.08),
      side: BorderSide(color: (color ?? AppColors.primaryBlue).withOpacity(0.4)),
      labelStyle: TextStyle(color: color ?? AppColors.primaryBlue, fontWeight: FontWeight.w600),
    );
  }
}
