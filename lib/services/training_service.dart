import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth.dart';
import '../models/lesson.dart';
import '../models/module.dart';
import '../models/progress.dart';
import '../models/quiz.dart';
import 'api_client.dart';

class ModuleLessonsResponse {
  final Module module;
  final List<Lesson> lessons;

  ModuleLessonsResponse({
    required this.module,
    required this.lessons,
  });
}

class TrainingService {
  TrainingService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<List<Module>> fetchModules({VoidCallback? onError}) async {
    try {
      final response = await _dio.get(
        '/training/modules',
      );
      final data = response.data as List<dynamic>;
      return data.map((e) => Module.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      return Module.getSampleData();
    } catch (_) {
      onError?.call();
      return Module.getSampleData();
    }
  }

  Future<Module?> createModule(ModulePayload payload) async {
    try {
      final response = await _dio.post('/training/modules', data: payload.toJson());
      return Module.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Module?> updateModule(int moduleId, ModulePayload payload) async {
    try {
      final response = await _dio.put('/training/modules/$moduleId', data: payload.toJson());
      return Module.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteModule(int moduleId) async {
    try {
      await _dio.delete('/training/modules/$moduleId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ModuleLessonsResponse> fetchModuleLessons(int moduleId, {VoidCallback? onError}) async {
    try {
      final response = await _dio.get(
        '/training/modules/$moduleId/lessons',
      );
      final data = response.data as Map<String, dynamic>;
      final module = Module.fromJson(data['module'] as Map<String, dynamic>);
      final lessons = (data['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();
      return ModuleLessonsResponse(module: module, lessons: lessons);
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      final module = Module.getSampleData().firstWhere((m) => m.id == moduleId,
          orElse: () => Module.getSampleData().first);
      return ModuleLessonsResponse(module: module, lessons: Lesson.getSampleData());
    } catch (_) {
      onError?.call();
      final module = Module.getSampleData().firstWhere((m) => m.id == moduleId,
          orElse: () => Module.getSampleData().first);
      return ModuleLessonsResponse(module: module, lessons: Lesson.getSampleData());
    }
  }

  Future<LessonCompletionResult?> completeLesson(int lessonId, {bool completed = true}) async {
    try {
      final response = await _dio.post(
        '/training/lessons/$lessonId/complete',
        data: {'completed': completed},
      );
      final data = response.data as Map<String, dynamic>;
      return LessonCompletionResult(
        lessonId: data['lesson_id'],
        moduleId: data['module_id'],
        completed: data['completed'],
        completedLessons: data['completed_lessons'],
        totalLessons: data['total_lessons'],
        quizCompleted: data['quiz_completed'],
        progress: (data['progress'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<QuizData?> fetchQuiz(int moduleId, {VoidCallback? onError}) async {
    try {
      final response = await _dio.get('/training/modules/$moduleId/quiz');
      return QuizData.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      onError?.call();
      return null;
    }
  }

  Future<QuizResult?> submitQuiz(int moduleId, List<QuizAnswerPayload> answers) async {
    try {
      final response = await _dio.post(
        '/training/modules/$moduleId/quiz/submit',
        data: {
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );
      return QuizResult.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<ModuleAssignmentResult?> assignModule(int moduleId, List<int> userIds) async {
    try {
      final response = await _dio.post('/training/modules/$moduleId/assign', data: {'user_ids': userIds});
      final data = response.data as Map<String, dynamic>;
      return ModuleAssignmentResult(moduleId: data['module_id'] as int, userIds: List<int>.from(data['user_ids'] ?? []));
    } catch (_) {
      return null;
    }
  }

  Future<List<UserSummary>> fetchAssignableUsers() async {
    try {
      final response = await _dio.get('/training/assignable-users');
      final data = response.data as List<dynamic>;
      return data.map((e) => UserSummary.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<ModuleProgress?> fetchModuleProgress(int moduleId) async {
    try {
      final response = await _dio.get('/training/modules/$moduleId/progress');
      return ModuleProgress.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class LessonCompletionResult {
  final int lessonId;
  final int moduleId;
  final bool completed;
  final int completedLessons;
  final int totalLessons;
  final bool quizCompleted;
  final double progress;

  LessonCompletionResult({
    required this.lessonId,
    required this.moduleId,
    required this.completed,
    required this.completedLessons,
    required this.totalLessons,
    required this.quizCompleted,
    required this.progress,
  });
}

class QuizAnswerPayload {
  final int questionId;
  final int optionId;

  QuizAnswerPayload({required this.questionId, required this.optionId});

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'option_id': optionId,
      };
}

class ModulePayload {
  final String title;
  final String description;
  final String icon;
  final String color;
  final bool dueToChecklist;
  final int? checklistSectionId;
  final bool quizRequired;

  ModulePayload({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.dueToChecklist = false,
    this.checklistSectionId,
    this.quizRequired = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'icon': icon,
        'color': color,
        'due_to_checklist': dueToChecklist,
        'checklist_section_id': checklistSectionId,
        'quiz_required': quizRequired,
      };
}

class ModuleAssignmentResult {
  final int moduleId;
  final List<int> userIds;

  ModuleAssignmentResult({required this.moduleId, required this.userIds});
}
