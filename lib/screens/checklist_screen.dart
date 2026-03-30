import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../models/checklist_section.dart';
import '../models/module.dart';
import '../services/checklist_service.dart';
import '../services/session_service.dart';
import '../services/training_service.dart';
import '../utils/app_navigation.dart';
import '../utils/colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/desktop_content_scaffold.dart';
import '../widgets/access_denied_view.dart';
import 'checklist_detail_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _checklistService = ChecklistService();
  final _trainingService = TrainingService();

  late Future<List<ChecklistSection>> _sectionsFuture;
  late Future<List<Module>> _modulesFuture;
  ChecklistSection? _selectedSection;
  Module? _selectedModule;
  Future<ChecklistDetailResponse>? _selectedDetailFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _checklistService.fetchSections(onError: _showApiError);
    _modulesFuture = _trainingService.fetchModules(onError: _showApiError);
  }

  @override
  Widget build(BuildContext context) {
    final access = SessionManager.instance.access;
    if (!access.canViewChecklist) {
      return const AccessDeniedView(
        title: 'Checklist restringido',
        message: 'Tu rol no tiene acceso a esta vista.',
      );
    }
    final isWide = MediaQuery.of(context).size.width >= 1000;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
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
                  child: FutureBuilder<List<ChecklistSection>>(
                    future: _sectionsFuture,
                    builder: (context, sectionSnap) {
                      if (sectionSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (sectionSnap.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar checklist: ${sectionSnap.error}',
                          ),
                        );
                      }
                      final sections =
                          sectionSnap.data ?? const <ChecklistSection>[];
                      if (sections.isEmpty) {
                        return _buildEmptyState(
                          title: 'Sin secciones disponibles',
                          message:
                              'No se encontraron secciones de checklist o la API no respondio con datos.',
                        );
                      }

                      return FutureBuilder<List<Module>>(
                        future: _modulesFuture,
                        builder: (context, moduleSnap) {
                          if (moduleSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final modules = moduleSnap.data ?? const <Module>[];
                          _initializeDesktopSelection(sections, modules);
                          if (isDesktop) {
                            return DesktopContentScaffold(
                              padding: const EdgeInsets.all(20),
                              sidePanel: _buildDesktopDetailPanel(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoBox(),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        ...sections.map((section) {
                                          final module = _findSectionModule(
                                            section,
                                            modules,
                                          );
                                          return _buildSectionCard(
                                            context,
                                            section,
                                            module,
                                            isDesktop: true,
                                            isSelected:
                                                _selectedSection?.id ==
                                                section.id,
                                          );
                                        }),
                                        const SizedBox(height: 16),
                                        _buildBottomInfo(),
                                      ],
                                    ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoBox(),
                                const SizedBox(height: 16),
                                ...sections.map((section) {
                                  final module = _findSectionModule(
                                    section,
                                    modules,
                                  );
                                  return _buildSectionCard(
                                    context,
                                    section,
                                    module,
                                  );
                                }),
                                const SizedBox(height: 16),
                                _buildBottomInfo(),
                              ],
                            ),
                          );
                        },
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
                      'Volver al inicio',
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
              const Text(
                'Checklist - Objetivo 2',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Evaluacion de requisitos legales SST',
                style: TextStyle(
                  color: AppColors.textOnDarkMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBlue50,
        border: Border.all(color: AppColors.borderBlue200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Linea base legal segun Ley 29783 y DS 005-2012-TR',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgAmber50,
        border: Border.all(color: AppColors.borderAmber300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Importante',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF78350F),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las secciones marcadas como "Deficiente" requieren capacitacion obligatoria del personal. Completa los modulos y aprueba las evaluaciones.',
            style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    ChecklistSection section,
    Module? module, {
    bool isDesktop = false,
    bool isSelected = false,
  }) {
    Color borderColor;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (section.status) {
      case 'deficiente':
        borderColor = AppColors.borderRed300;
        statusColor = AppColors.statusRed;
        statusText = 'Deficiente';
        statusIcon = Icons.cancel;
        break;
      case 'aprobado':
        borderColor = AppColors.borderGreen200;
        statusColor = AppColors.statusGreen;
        statusText = 'Aprobado';
        statusIcon = Icons.check_circle;
        break;
      default:
        borderColor = AppColors.borderGray200;
        statusColor = AppColors.statusGray;
        statusText = 'Pendiente';
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : borderColor,
          width: isSelected ? 2.5 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
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
              _selectedSection = section;
              _selectedModule = module;
              _selectedDetailFuture = _checklistService.fetchSectionDetail(
                section.id,
                onError: _showApiError,
              );
            });
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChecklistDetailScreen(section: section, module: module),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textGray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${section.itemsCompleted}/${section.itemsTotal} requisitos cumplidos',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isDesktop && isSelected
                        ? Icons.radio_button_checked
                        : Icons.chevron_right,
                    color: isDesktop && isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textGray400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: section.percentage / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.bgGray100,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (section.status == 'deficiente')
                    if (module != null)
                      ElevatedButton(
                        onPressed: () {
                          openTrainingExperience(
                            context,
                            selectedModule: module,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Ver Capacitacion',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Sin modulo vinculado',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textGray500,
                          fontWeight: FontWeight.w600,
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

  Module? _findSectionModule(ChecklistSection section, List<Module> modules) {
    for (final module in modules) {
      if (section.moduleId != null && module.id == section.moduleId) {
        return module;
      }
      if (section.moduleId == null && module.checklistSectionId == section.id) {
        return module;
      }
    }
    return null;
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
                Icons.fact_check_outlined,
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

  Widget _buildDesktopDetailPanel() {
    if (_selectedSection == null || _selectedDetailFuture == null) {
      return _buildEmptyState(
        title: 'Selecciona una seccion',
        message: 'Selecciona una seccion para revisar su detalle.',
      );
    }

    return FutureBuilder<ChecklistDetailResponse>(
      future: _selectedDetailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGray200),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final detail =
            snapshot.data ??
            ChecklistDetailResponse(
              section: _selectedSection!,
              items: const [],
            );

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
                Text(
                  detail.section.title,
                  style: const TextStyle(
                    color: AppColors.textGray900,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedModule?.title ?? 'Sin modulo vinculado',
                  style: const TextStyle(color: AppColors.textGray600),
                ),
                const SizedBox(height: 16),
                _buildDesktopProgressBlock(detail.section),
                const SizedBox(height: 16),
                _buildDesktopModuleBlock(_selectedModule),
                const SizedBox(height: 16),
                const Text(
                  'Requisitos evaluados',
                  style: TextStyle(
                    color: AppColors.textGray900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (detail.items.isEmpty)
                  const Text(
                    'No hay requisitos cargados para esta seccion.',
                    style: TextStyle(color: AppColors.textGray600),
                  )
                else
                  ...detail.items.map(_buildDesktopRequirementItem),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopProgressBlock(ChecklistSection section) {
    final statusColor = _statusColor(section.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSlate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso',
            style: TextStyle(
              color: AppColors.textGray900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: section.percentage / 100,
              minHeight: 9,
              backgroundColor: AppColors.bgGray100,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${section.itemsCompleted}/${section.itemsTotal} requisitos cumplidos',
            style: const TextStyle(color: AppColors.textGray600),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopModuleBlock(Module? module) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgBlue50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderBlue200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capacitacion relacionada',
            style: TextStyle(
              color: AppColors.textGray900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            module?.description ??
                'Esta seccion no tiene un modulo de capacitacion vinculado.',
            style: const TextStyle(color: AppColors.textGray600, height: 1.4),
          ),
          if (module != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () =>
                    openTrainingExperience(context, selectedModule: module),
                child: const Text('Abrir modulo'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopRequirementItem(ChecklistItem item) {
    final compliant = item.isCompliant;
    final color = compliant ? AppColors.statusGreen : AppColors.statusRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            compliant ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(color: AppColors.textGray900, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeDesktopSelection(
    List<ChecklistSection> sections,
    List<Module> modules,
  ) {
    if (!ResponsiveBreakpoints.isDesktop(context) || sections.isEmpty) return;
    if (_selectedSection != null &&
        sections.any((section) => section.id == _selectedSection!.id)) {
      _selectedModule = _findSectionModule(_selectedSection!, modules);
      return;
    }
    _selectedSection = sections.first;
    _selectedModule = _findSectionModule(_selectedSection!, modules);
    _selectedDetailFuture = _checklistService.fetchSectionDetail(
      _selectedSection!.id,
      onError: _showApiError,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'deficiente':
        return AppColors.statusRed;
      case 'aprobado':
        return AppColors.statusGreen;
      default:
        return AppColors.statusGray;
    }
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
