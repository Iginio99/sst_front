import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../models/checklist_section.dart';
import '../models/module.dart';
import '../services/checklist_service.dart';
import '../utils/colors.dart';
import 'modules_screen.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final ChecklistSection section;
  final Module module;

  const ChecklistDetailScreen({Key? key, required this.section, required this.module}) : super(key: key);

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final _checklistService = ChecklistService();
  late Future<ChecklistDetailResponse> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _checklistService.fetchSectionDetail(
      widget.section.id,
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
          _buildHeader(context),
          Expanded(
            child: Container(
              color: AppColors.bgSlate100,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: FutureBuilder<ChecklistDetailResponse>(
                    future: _detailFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error al cargar: ${snapshot.error}'));
                      }
                      final detail = snapshot.data ??
                          ChecklistDetailResponse(
                            section: widget.section,
                            items: ChecklistItem.getSampleData(),
                          );

                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProgressCard(detail.section),
                            const SizedBox(height: 16),
                            _buildModuleLink(widget.module),
                            const SizedBox(height: 16),
                            const Text(
                              'Requisitos evaluados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGray900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...detail.items.map(_buildRequirementItem).toList(),
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

  Widget _buildHeader(BuildContext context) {
    final section = widget.section;
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
                      'Volver a checklist',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: module.color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: module.color.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        module.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          module.title,
                          style: const TextStyle(
                            color: AppColors.textOnDarkMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(section.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(ChecklistSection section) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso del checklist',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textGray900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: section.percentage / 100,
                    minHeight: 10,
                    backgroundColor: AppColors.bgGray100,
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor(section.status)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${section.percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGray900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${section.itemsCompleted}/${section.itemsTotal} requisitos cumplidos',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textGray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleLink(Module module) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgBlue50,
        border: Border.all(color: AppColors.borderBlue200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Capacitacion relacionada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textGray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  module.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray600,
                  ),
                ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Abrir modulo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(ChecklistItem item) {
    final bool compliant = item.isCompliant;
    final Color color = compliant ? AppColors.statusGreen : AppColors.statusRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: compliant ? AppColors.bgGreen50 : AppColors.bgRed50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: compliant ? AppColors.borderGreen200 : AppColors.borderRed300),
            ),
            child: Icon(
              compliant ? Icons.check : Icons.close,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGray900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final Color color = _statusColor(status);
    String label;
    switch (status) {
      case 'deficiente':
        label = 'Deficiente';
        break;
      case 'aprobado':
        label = 'Aprobado';
        break;
      default:
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
