import 'package:flutter/material.dart';
import '../models/checklist_section.dart';
import '../models/module.dart';
import '../services/checklist_service.dart';
import '../services/training_service.dart';
import '../utils/colors.dart';
import 'checklist_detail_screen.dart';
import 'modules_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({Key? key}) : super(key: key);

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _checklistService = ChecklistService();
  final _trainingService = TrainingService();

  late Future<List<ChecklistSection>> _sectionsFuture;
  late Future<List<Module>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _checklistService.fetchSections(onError: _showApiError);
    _modulesFuture = _trainingService.fetchModules(onError: _showApiError);
  }

  @override
  Widget build(BuildContext context) {
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
                  child: FutureBuilder<List<ChecklistSection>>(
                    future: _sectionsFuture,
                    builder: (context, sectionSnap) {
                      if (sectionSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (sectionSnap.hasError) {
                        return Center(child: Text('Error al cargar checklist: ${sectionSnap.error}'));
                      }
                      final sections = sectionSnap.data ?? ChecklistSection.getSampleData();

                      return FutureBuilder<List<Module>>(
                        future: _modulesFuture,
                        builder: (context, moduleSnap) {
                          final modules = moduleSnap.data ?? Module.getSampleData();
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoBox(),
                                const SizedBox(height: 16),
                                ...sections.map((section) {
                                  final module = modules.firstWhere(
                                    (m) => section.moduleId != null
                                        ? m.id == section.moduleId
                                        : m.checklistSectionId == section.id,
                                    orElse: () => modules.first,
                                  );
                                  return _buildSectionCard(context, section, module);
                                }).toList(),
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
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF1E40AF),
              ),
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
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, ChecklistSection section, Module module) {
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
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
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
              builder: (context) => ChecklistDetailScreen(section: section, module: module),
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
                  const Icon(Icons.chevron_right, color: AppColors.textGray400),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
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
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ModulesScreen(selectedModule: module),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Ver Capacitacion',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
