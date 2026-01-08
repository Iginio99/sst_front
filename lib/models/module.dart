import 'package:flutter/material.dart';
import '../utils/colors.dart';

class Module {
  final int id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final int lessons;
  final int completedLessons;
  final bool dueToChecklist;
  final bool quizCompleted;
  final bool quizRequired;
  final int? checklistSectionId;
  final int? ownerId;

  const Module({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.lessons,
    required this.completedLessons,
    required this.dueToChecklist,
    required this.quizCompleted,
    required this.quizRequired,
    required this.checklistSectionId,
    required this.ownerId,
  });

  double get progress => lessons == 0 ? 0 : completedLessons / lessons;

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      color: _colorFromHex(json['color'] ?? '#2563EB'),
      lessons: json['lessons'] ?? 0,
      completedLessons: json['completed_lessons'] ?? 0,
      dueToChecklist: json['due_to_checklist'] ?? false,
      quizCompleted: json['quiz_completed'] ?? false,
      quizRequired: json['quiz_required'] ?? true,
      checklistSectionId: json['checklist_section_id'],
      ownerId: json['owner_id'],
    );
  }

  static Color _colorFromHex(String hex) {
    var cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    return Color(int.parse(cleaned, radix: 16));
  }

  static List<Module> getSampleData() {
    return [
      Module(
        id: 1,
        title: 'Liderazgo en SST',
        description: 'Rol de la gerencia y comunicacion efectiva en seguridad',
        icon: 'S1',
        color: AppColors.primaryBlue,
        lessons: 4,
        completedLessons: 2,
        dueToChecklist: true,
        quizCompleted: false,
        quizRequired: true,
        checklistSectionId: 1,
        ownerId: 1,
      ),
      Module(
        id: 2,
        title: 'Participacion de trabajadores',
        description: 'Derechos, consultas y comite de SST',
        icon: 'S2',
        color: AppColors.statusGreen,
        lessons: 5,
        completedLessons: 3,
        dueToChecklist: true,
        quizCompleted: false,
        quizRequired: true,
        checklistSectionId: 2,
        ownerId: 1,
      ),
      Module(
        id: 3,
        title: 'Investigacion de incidentes',
        description: 'Reporte, investigacion y acciones correctivas',
        icon: 'S3',
        color: AppColors.moduleOrange,
        lessons: 3,
        completedLessons: 1,
        dueToChecklist: true,
        quizCompleted: false,
        quizRequired: true,
        checklistSectionId: 3,
        ownerId: 1,
      ),
      Module(
        id: 4,
        title: 'Capacitacion anual',
        description: 'Planificacion y registro de capacitaciones',
        icon: 'S4',
        color: AppColors.moduleAmber,
        lessons: 6,
        completedLessons: 6,
        dueToChecklist: false,
        quizCompleted: true,
        quizRequired: true,
        checklistSectionId: 4,
        ownerId: 1,
      ),
      Module(
        id: 5,
        title: 'Auditorias internas',
        description: 'Plan, ejecucion y seguimiento de auditorias',
        icon: 'S5',
        color: AppColors.modulePurple,
        lessons: 4,
        completedLessons: 2,
        dueToChecklist: false,
        quizCompleted: false,
        quizRequired: true,
        checklistSectionId: 5,
        ownerId: 1,
      ),
      Module(
        id: 6,
        title: 'Gestion documental',
        description: 'Politicas, procedimientos y registros clave',
        icon: 'S6',
        color: AppColors.textGray600,
        lessons: 2,
        completedLessons: 1,
        dueToChecklist: false,
        quizCompleted: false,
        quizRequired: true,
        checklistSectionId: 6,
        ownerId: 1,
      ),
    ];
  }
}
