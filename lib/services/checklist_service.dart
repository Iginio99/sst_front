import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/checklist_item.dart';
import '../models/checklist_section.dart';
import 'api_client.dart';

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
      return ChecklistSection.getSampleData();
    } catch (_) {
      onError?.call();
      return ChecklistSection.getSampleData();
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
      final section = ChecklistSection.getSampleData().firstWhere(
        (s) => s.id == sectionId,
        orElse: () => ChecklistSection.getSampleData().first,
      );
      return ChecklistDetailResponse(section: section, items: ChecklistItem.getSampleData());
    } catch (_) {
      onError?.call();
      final section = ChecklistSection.getSampleData().firstWhere(
        (s) => s.id == sectionId,
        orElse: () => ChecklistSection.getSampleData().first,
      );
      return ChecklistDetailResponse(section: section, items: ChecklistItem.getSampleData());
    }
  }
}

class ChecklistDetailResponse {
  final ChecklistSection section;
  final List<ChecklistItem> items;

  ChecklistDetailResponse({required this.section, required this.items});
}
