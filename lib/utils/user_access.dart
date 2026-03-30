import '../models/auth.dart';

enum HomeExperience {
  learner,
  manager,
  monitor,
}

class UserAccess {
  UserAccess(this.user);

  final UserProfile? user;

  List<String> get _roles => user?.roles ?? const [];
  List<String> get _permissions => user?.permissions ?? const [];

  bool hasRole(String code) => _roles.contains(code);
  bool hasPermission(String code) => _permissions.contains(code);

  bool get isSuperadmin => hasRole('superadmin');
  bool get isAdmin => hasRole('admin');
  bool get isLeader => hasRole('leader') || hasRole('supervisor');
  bool get isCollaborator => hasRole('collaborator') || hasRole('worker');
  bool get isManagementRole => isSuperadmin || isAdmin || isLeader;
  bool get isLearnerRole =>
      !isManagementRole && (isCollaborator || (canViewTraining && (_hasStudyPermission)));

  bool get canViewChecklist => hasPermission('checklist.view');
  bool get canViewTraining => hasPermission('training.view');
  bool get canCompleteLessons => !isManagementRole && hasPermission('training.complete');
  bool get canTakeQuiz => !isManagementRole && hasPermission('training.quiz');
  bool get canManageModules => hasPermission('training.manage');
  bool get canAssignModules => hasPermission('training.assign');
  bool get canMonitorProgress => hasPermission('training.monitor');

  bool get _hasStudyPermission => hasPermission('training.complete') || hasPermission('training.quiz');

  bool get canStudy => isLearnerRole && canViewTraining && (canCompleteLessons || canTakeQuiz || isCollaborator);

  bool get canUseTrainingConsole =>
      canManageModules || canAssignModules || canMonitorProgress || isSuperadmin || isAdmin || isLeader;

  HomeExperience get primaryExperience {
    if (isSuperadmin || isAdmin || canManageModules || canAssignModules) {
      return HomeExperience.manager;
    }
    if (isLeader || canMonitorProgress) {
      return HomeExperience.monitor;
    }
    return HomeExperience.learner;
  }
}
