import 'package:sst/models/auth.dart';

class UserModuleProgress {
  final UserSummary user;
  final int completedLessons;
  final int totalLessons;
  final bool quizCompleted;
  final int? lastScore;
  final DateTime? lastAttemptAt;

  UserModuleProgress({
    required this.user,
    required this.completedLessons,
    required this.totalLessons,
    required this.quizCompleted,
    this.lastScore,
    this.lastAttemptAt,
  });

  factory UserModuleProgress.fromJson(Map<String, dynamic> json) {
    return UserModuleProgress(
      user: UserSummary.fromJson(json['user'] as Map<String, dynamic>),
      completedLessons: json['completed_lessons'] ?? 0,
      totalLessons: json['total_lessons'] ?? 0,
      quizCompleted: json['quiz_completed'] ?? false,
      lastScore: json['last_score'],
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'] as String)
          : null,
    );
  }
}

class ModuleProgress {
  final int moduleId;
  final String moduleTitle;
  final List<UserModuleProgress> users;

  ModuleProgress({
    required this.moduleId,
    required this.moduleTitle,
    required this.users,
  });

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    final usersJson = json['users'] as List<dynamic>? ?? [];
    return ModuleProgress(
      moduleId: json['module_id'] as int,
      moduleTitle: json['module_title'] as String,
      users: usersJson.map((e) => UserModuleProgress.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
