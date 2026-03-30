import 'dart:ui' show Color;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/auth.dart';
import '../models/lesson.dart';
import '../models/module.dart';
import '../models/progress.dart';
import '../models/quiz.dart';
import 'api_client.dart';
import '../utils/api_config.dart';

class ModuleLessonsResponse {
  final Module module;
  final List<Lesson> lessons;

  ModuleLessonsResponse({required this.module, required this.lessons});
}

class UploadFilePayload {
  final String name;
  final List<int> bytes;
  final String? path;

  UploadFilePayload({required this.name, required this.bytes, this.path});
}

class OperationResult<T> {
  final T? data;
  final String? errorMessage;

  const OperationResult._({this.data, this.errorMessage});

  bool get success => data != null && errorMessage == null;

  factory OperationResult.success(T data) => OperationResult._(data: data);

  factory OperationResult.failure(String message) =>
      OperationResult._(errorMessage: message);
}

class LessonPayload {
  final String title;
  final String duration;
  final String type;
  final String? description;
  final int displayOrder;
  final String contentMode;
  final String? externalUrl;

  LessonPayload({
    required this.title,
    required this.duration,
    required this.type,
    this.description,
    this.displayOrder = 1,
    this.contentMode = 'upload',
    this.externalUrl,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'duration': duration,
    'type': type,
    'description': description,
    'display_order': displayOrder,
    'content_mode': contentMode,
    'external_url': externalUrl,
  };
}

class TrainingService {
  TrainingService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<List<Module>> fetchModules({VoidCallback? onError}) async {
    try {
      final response = await _dio.get('/training/modules');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => Module.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      if (allowSampleFallbacks) {
        return Module.getSampleData();
      }
      return [];
    } catch (_) {
      onError?.call();
      if (allowSampleFallbacks) {
        return Module.getSampleData();
      }
      return [];
    }
  }

  Future<Module?> createModule(ModulePayload payload) async {
    try {
      final response = await _dio.post(
        '/training/modules',
        data: payload.toJson(),
      );
      return Module.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Module?> updateModule(int moduleId, ModulePayload payload) async {
    try {
      final response = await _dio.put(
        '/training/modules/$moduleId',
        data: payload.toJson(),
      );
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

  Future<ModuleLessonsResponse> fetchModuleLessons(
    int moduleId, {
    VoidCallback? onError,
  }) async {
    try {
      final response = await _dio.get('/training/modules/$moduleId/lessons');
      final data = response.data as Map<String, dynamic>;
      final module = Module.fromJson(data['module'] as Map<String, dynamic>);
      final lessons =
          (data['lessons'] as List<dynamic>)
              .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return ModuleLessonsResponse(module: module, lessons: lessons);
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      if (allowSampleFallbacks) {
        final module = Module.getSampleData().firstWhere(
          (m) => m.id == moduleId,
          orElse: () => Module.getSampleData().first,
        );
        return ModuleLessonsResponse(
          module: module,
          lessons: Lesson.getSampleData(),
        );
      }
      return ModuleLessonsResponse(
        module: _buildPlaceholderModule(moduleId),
        lessons: const [],
      );
    } catch (_) {
      onError?.call();
      if (allowSampleFallbacks) {
        final module = Module.getSampleData().firstWhere(
          (m) => m.id == moduleId,
          orElse: () => Module.getSampleData().first,
        );
        return ModuleLessonsResponse(
          module: module,
          lessons: Lesson.getSampleData(),
        );
      }
      return ModuleLessonsResponse(
        module: _buildPlaceholderModule(moduleId),
        lessons: const [],
      );
    }
  }

  Future<OperationResult<Lesson>> createLesson(
    int moduleId,
    LessonPayload payload,
  ) async {
    try {
      final response = await _dio.post(
        '/training/modules/$moduleId/lessons',
        data: payload.toJson(),
      );
      return OperationResult.success(
        Lesson.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return OperationResult.failure(_extractErrorMessage(e));
    } catch (_) {
      return OperationResult.failure('No se pudo crear la leccion.');
    }
  }

  Future<OperationResult<Lesson>> updateLesson(
    int lessonId,
    LessonPayload payload,
  ) async {
    try {
      final response = await _dio.put(
        '/training/lessons/$lessonId',
        data: payload.toJson(),
      );
      return OperationResult.success(
        Lesson.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return OperationResult.failure(_extractErrorMessage(e));
    } catch (_) {
      return OperationResult.failure('No se pudo actualizar la leccion.');
    }
  }

  Future<OperationResult<bool>> deleteLesson(int lessonId) async {
    try {
      await _dio.delete('/training/lessons/$lessonId');
      return OperationResult.success(true);
    } on DioException catch (e) {
      return OperationResult.failure(_extractErrorMessage(e));
    } catch (_) {
      return OperationResult.failure('No se pudo eliminar la leccion.');
    }
  }

  Future<OperationResult<Lesson>> uploadLessonCover(
    int lessonId,
    UploadFilePayload file,
  ) async {
    return _uploadLessonFile('/training/lessons/$lessonId/cover', file);
  }

  Future<OperationResult<Lesson>> uploadLessonContent(
    int lessonId,
    UploadFilePayload file,
  ) async {
    return _uploadLessonFile('/training/lessons/$lessonId/content', file);
  }

  Future<OperationResult<Lesson>> _uploadLessonFile(
    String path,
    UploadFilePayload file,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': file.path != null && !kIsWeb
            ? await MultipartFile.fromFile(file.path!, filename: file.name)
            : MultipartFile.fromBytes(file.bytes, filename: file.name),
      });
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return OperationResult.success(
        Lesson.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return OperationResult.failure(_extractErrorMessage(e));
    } catch (_) {
      return OperationResult.failure('No se pudo subir el archivo.');
    }
  }

  Future<LessonCompletionResult?> completeLesson(
    int lessonId, {
    bool completed = true,
  }) async {
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

  Future<QuizResult?> submitQuiz(
    int moduleId,
    List<QuizAnswerPayload> answers,
  ) async {
    try {
      final response = await _dio.post(
        '/training/modules/$moduleId/quiz/submit',
        data: {'answers': answers.map((a) => a.toJson()).toList()},
      );
      return QuizResult.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<ModuleAssignmentResult?> assignModule(
    int moduleId,
    List<int> userIds,
  ) async {
    try {
      final response = await _dio.post(
        '/training/modules/$moduleId/assign',
        data: {'user_ids': userIds},
      );
      final data = response.data as Map<String, dynamic>;
      return ModuleAssignmentResult(
        moduleId: data['module_id'] as int,
        userIds: List<int>.from(data['user_ids'] ?? []),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<UserSummary>> fetchAssignableUsers() async {
    try {
      final response = await _dio.get('/training/assignable-users');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => UserSummary.fromJson(e as Map<String, dynamic>))
          .toList();
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

  Module _buildPlaceholderModule(int moduleId) {
    return Module(
      id: moduleId,
      title: 'Modulo',
      description: 'No se pudo cargar la informacion del modulo.',
      icon: 'M',
      color: const Color(0xFF2563EB),
      lessons: 0,
      completedLessons: 0,
      dueToChecklist: false,
      quizCompleted: false,
      quizRequired: true,
      checklistSectionId: null,
      ownerId: null,
    );
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }
    return 'La solicitud fallo con codigo ${error.response?.statusCode ?? 'desconocido'}.';
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
