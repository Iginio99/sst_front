import 'package:flutter/material.dart';

import '../models/module.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/desktop_content_scaffold.dart';
import '../widgets/access_denied_view.dart';
import 'lesson_admin_screen.dart';

class ModuleAdminScreen extends StatefulWidget {
  const ModuleAdminScreen({super.key, this.selectedModuleId});

  final int? selectedModuleId;

  @override
  State<ModuleAdminScreen> createState() => _ModuleAdminScreenState();
}

class _ModuleAdminScreenState extends State<ModuleAdminScreen> {
  final _trainingService = TrainingService();
  late Future<List<Module>> _modulesFuture;

  bool get _canManage =>
      SessionManager.instance.hasPermission('training.manage');
  bool get _canAssign =>
      SessionManager.instance.hasPermission('training.assign');
  bool get _canMonitor =>
      SessionManager.instance.hasPermission('training.monitor');

  @override
  void initState() {
    super.initState();
    _modulesFuture = _trainingService.fetchModules(onError: _showError);
  }

  @override
  Widget build(BuildContext context) {
    final access = SessionManager.instance.access;
    if (!access.canUseTrainingConsole) {
      return const AccessDeniedView(
        title: 'Gestion restringida',
        message:
            'Tu rol no tiene acceso a la consola de gestion o monitoreo de modulos.',
      );
    }
    final isWide = MediaQuery.of(context).size.width >= 1100;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final contentWidth = isWide ? 980.0 : double.infinity;
    final sidePadding = isWide ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de modulos'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: isDesktop
            ? [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _modulesFuture = _trainingService.fetchModules(
                        onError: _showError,
                      );
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                ),
                if (_canManage)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: FilledButton.icon(
                        onPressed: () => _openModuleForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Nuevo modulo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
              ]
            : null,
      ),
      floatingActionButton: !isDesktop && _canManage
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
                  return const Center(
                    child: Text('No hay modulos asignados para este rol.'),
                  );
                }
                if (isDesktop) {
                  return DesktopContentScaffold(
                    padding: const EdgeInsets.all(20),
                    sidePanel: _ModuleAdminSidePanel(
                      canManage: _canManage,
                      canAssign: _canAssign,
                      canMonitor: _canMonitor,
                      modulesCount: modules.length,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DesktopModuleToolbar(
                          canManage: _canManage,
                          onCreate: () => _openModuleForm(context),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _ModuleListView(
                            modules: modules,
                            sidePadding: 0,
                            selectedModuleId: widget.selectedModuleId,
                            canManage: _canManage,
                            canAssign: _canAssign,
                            canMonitor: _canMonitor,
                            onRefresh: () async {
                              setState(() {
                                _modulesFuture = _trainingService.fetchModules(
                                  onError: _showError,
                                );
                              });
                              await _modulesFuture;
                            },
                            onEdit: (module) =>
                                _openModuleForm(context, module: module),
                            onDelete: _confirmDelete,
                            onLessons: _openLessonAdmin,
                            onAssign: _openAssignment,
                            onProgress: _openProgress,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _modulesFuture = _trainingService.fetchModules(
                        onError: _showError,
                      );
                    });
                    await _modulesFuture;
                  },
                  child: _ModuleListView(
                    modules: modules,
                    sidePadding: sidePadding,
                    selectedModuleId: widget.selectedModuleId,
                    canManage: _canManage,
                    canAssign: _canAssign,
                    canMonitor: _canMonitor,
                    onRefresh: () async {
                      setState(() {
                        _modulesFuture = _trainingService.fetchModules(
                          onError: _showError,
                        );
                      });
                      await _modulesFuture;
                    },
                    onEdit: (module) =>
                        _openModuleForm(context, module: module),
                    onDelete: _confirmDelete,
                    onLessons: _openLessonAdmin,
                    onAssign: _openAssignment,
                    onProgress: _openProgress,
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
    final colorCtrl = TextEditingController(
      text: module != null ? _colorToHex(module.color) : '#2563EB',
    );
    final checklistCtrl = TextEditingController(
      text: module?.checklistSectionId != null
          ? module!.checklistSectionId.toString()
          : '',
    );
    bool dueToChecklist = module?.dueToChecklist ?? false;
    bool quizRequired = module?.quizRequired ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(module == null ? 'Nuevo modulo' : 'Editar modulo'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          content: StatefulBuilder(
            builder: (context, setInnerState) {
              final isDesktop = ResponsiveBreakpoints.isDesktop(context);
              return SizedBox(
                width: isDesktop ? 640 : null,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Titulo'),
                      ),
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion',
                        ),
                        maxLines: 3,
                      ),
                      if (isDesktop)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: iconCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Icono',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: colorCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Color (hex #RRGGBB)',
                                ),
                              ),
                            ),
                          ],
                        )
                      else ...[
                        TextField(
                          controller: iconCtrl,
                          decoration: const InputDecoration(labelText: 'Icono'),
                        ),
                        TextField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Color (hex #RRGGBB)',
                          ),
                        ),
                      ],
                      TextField(
                        controller: checklistCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Checklist section ID (opcional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SwitchListTile(
                        title: const Text('Debido a checklist'),
                        value: dueToChecklist,
                        onChanged: (v) =>
                            setInnerState(() => dueToChecklist = v),
                      ),
                      SwitchListTile(
                        title: const Text('Quiz requerido'),
                        value: quizRequired,
                        onChanged: (v) => setInnerState(() => quizRequired = v),
                      ),
                    ],
                  ),
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
                  color: colorCtrl.text.trim().isEmpty
                      ? '#2563EB'
                      : colorCtrl.text.trim(),
                  dueToChecklist: dueToChecklist,
                  checklistSectionId: checklistCtrl.text.isEmpty
                      ? null
                      : int.tryParse(checklistCtrl.text),
                  quizRequired: quizRequired,
                );
                Navigator.pop(context);
                if (module == null) {
                  await _trainingService.createModule(payload);
                } else {
                  await _trainingService.updateModule(module.id, payload);
                }
                setState(() {
                  _modulesFuture = _trainingService.fetchModules(
                    onError: _showError,
                  );
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRed,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _trainingService.deleteModule(module.id);
              setState(() {
                _modulesFuture = _trainingService.fetchModules(
                  onError: _showError,
                );
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
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Asignar modulo: ${module.title}'),
            content: SizedBox(
              width: 720,
              child: StatefulBuilder(
                builder: (context, setInner) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bgBlue50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderBlue200),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryBlue,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Selecciona los usuarios que deben recibir este modulo.',
                                style: TextStyle(
                                  color: AppColors.textGray700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 360,
                        child: ListView(
                          children: assignable
                              .map(
                                (u) => CheckboxListTile(
                                  value: selected.contains(u.id),
                                  title: Text(u.name),
                                  subtitle: Text(
                                    '${u.email} (${u.roles.join(", ")})',
                                  ),
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
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _trainingService.assignModule(
                    module.id,
                    selected.toList(),
                  );
                  setState(() {
                    _modulesFuture = _trainingService.fetchModules(
                      onError: _showError,
                    );
                  });
                },
                child: const Text('Guardar asignaciones'),
              ),
            ],
          );
        },
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInner) {
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
                  Text(
                    'Asignar modulo: ${module.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: ListView(
                      children: assignable
                          .map(
                            (u) => CheckboxListTile(
                              value: selected.contains(u.id),
                              title: Text(u.name),
                              subtitle: Text(
                                '${u.email} (${u.roles.join(", ")})',
                              ),
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
                      await _trainingService.assignModule(
                        module.id,
                        selected.toList(),
                      );
                      setState(() {
                        _modulesFuture = _trainingService.fetchModules(
                          onError: _showError,
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    child: const Text('Guardar asignaciones'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openProgress(Module module) async {
    final progress = await _trainingService.fetchModuleProgress(module.id);
    if (!mounted) return;
    if (progress == null || progress.users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay asignaciones registradas para este modulo'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Progreso: ${progress.moduleTitle}'),
        content: SizedBox(
          width: ResponsiveBreakpoints.isDesktop(context)
              ? 760
              : double.maxFinite,
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
                    subtitle: Text(
                      '${u.completedLessons}/${u.totalLessons} lecciones',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          u.quizCompleted ? 'Quiz aprobado' : 'Quiz pendiente',
                          style: TextStyle(
                            color: u.quizCompleted
                                ? AppColors.statusGreen
                                : AppColors.textGray600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (u.lastScore != null)
                          Text('Ultimo puntaje: ${u.lastScore}%'),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _openLessonAdmin(Module module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonAdminScreen(module: module),
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
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    this.isHighlighted = false,
    this.onEdit,
    this.onDelete,
    this.onLessons,
    this.onAssign,
    this.onProgress,
  });

  final Module module;
  final bool isHighlighted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLessons;
  final VoidCallback? onAssign;
  final VoidCallback? onProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isHighlighted ? AppColors.bgBlue50 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighlighted
              ? AppColors.primaryBlue
              : AppColors.borderGray200,
          width: isHighlighted ? 2 : 1,
        ),
      ),
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
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        module.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                _ActionChip(
                  icon: Icons.library_books_outlined,
                  label: 'Lecciones',
                  onTap: onLessons,
                ),
                _ActionChip(
                  icon: Icons.people,
                  label: 'Asignar',
                  onTap: onAssign,
                ),
                _ActionChip(
                  icon: Icons.analytics,
                  label: 'Progreso',
                  onTap: onProgress,
                ),
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

class _DesktopModuleToolbar extends StatelessWidget {
  const _DesktopModuleToolbar({
    required this.canManage,
    required this.onCreate,
  });

  final bool canManage;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray200),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consola de gestion',
                  style: TextStyle(
                    color: AppColors.textGray900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Desde aqui puedes editar, asignar y monitorear modulos con una interfaz mas cercana a escritorio.',
                  style: TextStyle(color: AppColors.textGray600, height: 1.4),
                ),
              ],
            ),
          ),
          if (canManage)
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo modulo'),
            ),
        ],
      ),
    );
  }
}

class _ModuleListView extends StatelessWidget {
  const _ModuleListView({
    required this.modules,
    required this.sidePadding,
    required this.selectedModuleId,
    required this.canManage,
    required this.canAssign,
    required this.canMonitor,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    required this.onLessons,
    required this.onAssign,
    required this.onProgress,
  });

  final List<Module> modules;
  final double sidePadding;
  final int? selectedModuleId;
  final bool canManage;
  final bool canAssign;
  final bool canMonitor;
  final Future<void> Function() onRefresh;
  final ValueChanged<Module> onEdit;
  final ValueChanged<Module> onDelete;
  final ValueChanged<Module> onLessons;
  final ValueChanged<Module> onAssign;
  final ValueChanged<Module> onProgress;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
        itemCount: modules.length,
        itemBuilder: (context, index) => _ModuleTile(
          module: modules[index],
          isHighlighted: selectedModuleId == modules[index].id,
          onEdit: canManage ? () => onEdit(modules[index]) : null,
          onDelete: canManage ? () => onDelete(modules[index]) : null,
          onLessons: canManage ? () => onLessons(modules[index]) : null,
          onAssign: canAssign ? () => onAssign(modules[index]) : null,
          onProgress: canMonitor ? () => onProgress(modules[index]) : null,
        ),
      ),
    );
  }
}

class _ModuleAdminSidePanel extends StatelessWidget {
  const _ModuleAdminSidePanel({
    required this.canManage,
    required this.canAssign,
    required this.canMonitor,
    required this.modulesCount,
  });

  final bool canManage;
  final bool canAssign;
  final bool canMonitor;
  final int modulesCount;

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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion de modulos',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Administra modulos, asignaciones y progreso desde una sola vista.',
                style: TextStyle(color: AppColors.textOnDarkMuted, height: 1.4),
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
                'Permisos activos',
                style: TextStyle(
                  color: AppColors.textGray900,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _SideBullet(label: 'Gestionar modulos', enabled: canManage),
              _SideBullet(label: 'Asignar usuarios', enabled: canAssign),
              _SideBullet(label: 'Monitorear progreso', enabled: canMonitor),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Modulos visibles',
                    style: TextStyle(color: AppColors.textGray600),
                  ),
                  Text(
                    '$modulesCount',
                    style: const TextStyle(
                      color: AppColors.textGray900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideBullet extends StatelessWidget {
  const _SideBullet({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.remove_circle_outline,
            size: 18,
            color: enabled ? AppColors.statusGreen : AppColors.textGray400,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textGray700)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

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
      backgroundColor: (color ?? AppColors.primaryBlue).withValues(alpha: 0.08),
      side: BorderSide(
        color: (color ?? AppColors.primaryBlue).withValues(alpha: 0.4),
      ),
      labelStyle: TextStyle(
        color: color ?? AppColors.primaryBlue,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
