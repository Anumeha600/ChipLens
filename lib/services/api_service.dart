import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/nl_generation_result.dart';

// ─── Typed exception (never leaks socket/localhost/Dio internals) ─────────────

class ChipLensApiException implements Exception {
  final String userMessage;
  final bool isConnectionError;

  const ChipLensApiException(
    this.userMessage, {
    this.isConnectionError = false,
  });

  @override
  String toString() => userMessage;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class RtlApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout:    AppConfig.sendTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // ── Error normalisation ────────────────────────────────────────────────────

  static ChipLensApiException _wrap(Object e) {
    if (e is ChipLensApiException) return e;

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ChipLensApiException(
            'Analysis timed out. The server took too long to respond.',
          );
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return const ChipLensApiException(
            'Unable to reach the analysis engine.',
            isConnectionError: true,
          );
        default:
          // Try to extract a server-side message
          final serverMsg =
              ((e.response?.data as Map?)?['error'] as Map?)?['message']
                  as String?;
          if (serverMsg != null && serverMsg.isNotEmpty) {
            return ChipLensApiException(serverMsg);
          }
          return const ChipLensApiException(
            'An unexpected error occurred. Please try again.',
          );
      }
    }

    // Strip any raw exception text that could expose internals
    return const ChipLensApiException(
      'Something went wrong. Please try again.',
    );
  }

  static Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> analyze(String code) => _guard(() async {
        final resp = await _dio.post(
          '${AppConfig.apiBase}/analyze',
          data: {'code': code},
        );
        final body = resp.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
        throw ChipLensApiException(
          (body['error'] as Map?)?['message'] as String? ?? 'Analysis failed',
        );
      });

  static Future<Map<String, dynamic>> fetchFsm(String code) => _guard(() async {
        final resp = await _dio.post(
          '${AppConfig.apiBase}/fsm',
          data: {'code': code},
        );
        final body = resp.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
        throw ChipLensApiException(
          (body['error'] as Map?)?['message'] as String? ??
              'FSM extraction failed',
        );
      });

  static Future<Map<String, dynamic>> fetchHierarchy(
    List<Map<String, String>> files,
  ) =>
      _guard(() async {
        final resp = await _dio.post(
          '${AppConfig.apiBase}/hierarchy',
          data: {'files': files},
        );
        final body = resp.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
        throw ChipLensApiException(
          (body['error'] as Map?)?['message'] as String? ??
              'Hierarchy fetch failed',
        );
      });

  static Future<NlGenerationResult> generate(String description) =>
      _guard(() async {
        final resp = await _dio.post(
          '${AppConfig.apiBase}/generate',
          data: {'description': description},
        );
        final body = resp.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return NlGenerationResult.fromJson(body);
        }
        throw ChipLensApiException(
          (body['error'] as Map?)?['message'] as String? ??
              'Generation failed',
        );
      });

  static Future<String> explain(
    String code, {
    String? question,
    List<Map<String, dynamic>>? warnings,
    List<Map<String, dynamic>>? history,
    Map<String, dynamic>? scoreData,
  }) =>
      _guard(() async {
        final data = <String, dynamic>{'code': code};
        if (question != null) data['question'] = question;
        if (warnings != null && warnings.isNotEmpty) {
          data['warnings'] = warnings;
        }
        if (history != null && history.isNotEmpty) data['history'] = history;
        if (scoreData != null) data['scoreData'] = scoreData;

        final resp = await _dio.post(
          '${AppConfig.apiBase}/explain',
          data: data,
        );
        final body = resp.data as Map<String, dynamic>;
        if (body['success'] == true) {
          return (body['data'] as Map)['explanation'] as String;
        }
        throw ChipLensApiException(
          (body['error'] as Map?)?['message'] as String? ??
              'Explanation failed',
        );
      });
}
