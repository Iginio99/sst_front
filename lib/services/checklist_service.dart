import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/checklist_item.dart';
import '../models/checklist_section.dart';
import 'api_client.dart';
import '../utils/api_config.dart';

class ChecklistService {
  ChecklistService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<List<ChecklistSection>> fetchSections({VoidCallback? onError}) async {
    try {
      final response = await _dio.get('/checklist/');
      final data = response.data as List<dynamic>;
      return data.map((e) => ChecklistSection.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      if (allowSampleFallbacks) {
        return ChecklistSection.getSampleData();
      }
      return [];
    } catch (_) {
      onError?.call();
      if (allowSampleFallbacks) {
        return ChecklistSection.getSampleData();
      }
      return [];
    }
  }

  Future<ChecklistDetailResponse> fetchSectionDetail(int sectionId, {VoidCallback? onError}) async {
    try {
      final response = await _dio.get('/checklist/$sectionId');
      final data = response.data as Map<String, dynamic>;
      final section = ChecklistSection.fromJson(data['section'] as Map<String, dynamic>);
      final items = (data['items'] as List<dynamic>)
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return ChecklistDetailResponse(section: section, items: items);
    } on DioException catch (e) {
      onError?.call();
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      if (allowSampleFallbacks) {
        final section = ChecklistSection.getSampleData().firstWhere(
          (s) => s.id == sectionId,
          orElse: () => ChecklistSection.getSampleData().first,
        );
        return ChecklistDetailResponse(section: section, items: ChecklistItem.getSampleData());
      }
      return ChecklistDetailResponse(
        section: ChecklistSection(
          id: sectionId,
          title: 'Seccion',
          itemsCompleted: 0,
          itemsTotal: 0,
          percentage: 0,
          status: 'pendiente',
        ),
        items: const [],
      );
    } catch (_) {
      onError?.call();
      if (allowSampleFallbacks) {
        final section = ChecklistSection.getSampleData().firstWhere(
          (s) => s.id == sectionId,
          orElse: () => ChecklistSection.getSampleData().first,
        );
        return ChecklistDetailResponse(section: section, items: ChecklistItem.getSampleData());
      }
      return ChecklistDetailResponse(
        section: ChecklistSection(
          id: sectionId,
          title: 'Seccion',
          itemsCompleted: 0,
          itemsTotal: 0,
          percentage: 0,
          status: 'pendiente',
        ),
        items: const [],
      );
    }
  }
}

class ChecklistDetailResponse {
  final ChecklistSection section;
  final List<ChecklistItem> items;

  ChecklistDetailResponse({required this.section, required this.items});
}
