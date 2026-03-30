import 'package:flutter/material.dart';

import '../models/module.dart';
import '../screens/checklist_screen.dart';
import '../screens/module_admin_screen.dart';
import '../screens/modules_screen.dart';
import '../services/session_service.dart';

void openChecklistExperience(BuildContext context) {
  final access = SessionManager.instance.access;
  if (!access.canViewChecklist) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tienes acceso al checklist')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ChecklistScreen()),
  );
}

void openTrainingExperience(BuildContext context, {Module? selectedModule}) {
  final access = SessionManager.instance.access;
  if (access.canStudy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModulesScreen(selectedModule: selectedModule),
      ),
    );
    return;
  }
  if (access.canUseTrainingConsole) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleAdminScreen(selectedModuleId: selectedModule?.id),
      ),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('No tienes acceso a esta vista de capacitacion')),
  );
}
