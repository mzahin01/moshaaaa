import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://rifath1729-mosquito-breeding-spot-detection.hf.space';
  static const String _apiPrefix = 'gradio_api';

  final http.Client _client;

  Future<Map<String, dynamic>> analyzeImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final String filePath = await _uploadImage(imageBytes, fileName);
    final String eventId = await _triggerAnalysis(
      filePath: filePath,
      fileName: fileName,
    );
    return _fetchResult(eventId, fallbackImageBytes: imageBytes);
  }

  Future<String> _uploadImage(Uint8List imageBytes, String fileName) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/$_apiPrefix/upload'))
          ..files.add(
            http.MultipartFile.fromBytes(
              'files',
              imageBytes,
              filename: fileName,
            ),
          );

    final http.StreamedResponse streamedResponse = await request.send();
    final http.Response response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw const FormatException(
        'Upload response was not a non-empty JSON array.',
      );
    }

    final dynamic filePath = decoded[0];
    if (filePath is! String || filePath.isEmpty) {
      throw const FormatException(
        'Upload response did not contain a valid file path at index 0.',
      );
    }

    return filePath;
  }

  Future<String> _triggerAnalysis({
    required String filePath,
    required String fileName,
  }) async {
    final String mimeType = _guessMimeType(fileName);

    final http.Response response = await _client.post(
      Uri.parse('$_baseUrl/$_apiPrefix/call/analyze'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'path': filePath,
            'meta': <String, String>{'_type': 'gradio.FileData'},
            'orig_name': fileName,
            'mime_type': mimeType,
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Analyze trigger failed (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Analyze trigger response was not JSON map.');
    }

    final dynamic eventId = decoded['event_id'];
    if (eventId is! String || eventId.isEmpty) {
      throw const FormatException('Analyze trigger response missing event_id.');
    }

    return eventId;
  }

  Future<Map<String, dynamic>> _fetchResult(
    String eventId, {
    required Uint8List fallbackImageBytes,
  }) async {
    final http.Response response = await _client
        .get(Uri.parse('$_baseUrl/$_apiPrefix/call/analyze/$eventId'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Analyze result failed (${response.statusCode}): ${response.body}',
      );
    }

    final List<Map<String, dynamic>> events = _parseSseEvents(response.body);
    String? latestError;

    for (final Map<String, dynamic> event in events) {
      final dynamic payload = event['payload'];
      final String type = event['event']?.toString() ?? '';

      final Map<String, dynamic>? result = _extractResultMap(payload);
      if (result != null) {
        return _normalizeResult(result, fallbackImageBytes: fallbackImageBytes);
      }

      if (type == 'error') {
        latestError = _extractErrorMessage(payload);
      }
    }

    if (latestError != null && latestError.isNotEmpty) {
      throw Exception('Analysis failed: $latestError');
    }

    throw const FormatException(
      'Could not parse result payload from SSE stream.',
    );
  }

  List<Map<String, dynamic>> _parseSseEvents(String body) {
    final List<Map<String, dynamic>> parsedEvents = <Map<String, dynamic>>[];
    final List<String> blocks = body.split(RegExp(r'\n\n+'));

    for (final String block in blocks) {
      if (block.trim().isEmpty) {
        continue;
      }

      String eventType = 'message';
      final StringBuffer dataBuffer = StringBuffer();

      for (final String line in block.split('\n')) {
        if (line.startsWith('event:')) {
          eventType = line.substring('event:'.length).trim();
          continue;
        }

        if (line.startsWith('data:')) {
          if (dataBuffer.isNotEmpty) {
            dataBuffer.write('\n');
          }
          dataBuffer.write(line.substring('data:'.length).trim());
        }
      }

      if (dataBuffer.isEmpty) {
        continue;
      }

      dynamic payload;
      try {
        payload = jsonDecode(dataBuffer.toString());
      } catch (_) {
        payload = dataBuffer.toString();
      }

      parsedEvents.add(<String, dynamic>{
        'event': eventType,
        'payload': payload,
      });
    }

    return parsedEvents;
  }

  Map<String, dynamic>? _extractResultMap(dynamic payload) {
    if (payload is List && payload.isNotEmpty && payload.first is Map) {
      return Map<String, dynamic>.from(payload.first as Map);
    }

    if (payload is Map) {
      final Map<String, dynamic> payloadMap = Map<String, dynamic>.from(
        payload,
      );
      final dynamic data = payloadMap['data'];
      if (data is List && data.isNotEmpty && data.first is Map) {
        return Map<String, dynamic>.from(data.first as Map);
      }

      if (payloadMap.containsKey('water_coverage_percent') ||
          payloadMap.containsKey('total_detections') ||
          payloadMap.containsKey('gps')) {
        return payloadMap;
      }
    }

    return null;
  }

  String _extractErrorMessage(dynamic payload) {
    if (payload is Map) {
      final dynamic error = payload['error'];
      if (error == null) {
        return 'Unknown server error.';
      }
      return error.toString();
    }
    return payload?.toString() ?? 'Unknown server error.';
  }

  Map<String, dynamic> _normalizeResult(
    Map<String, dynamic> input, {
    required Uint8List fallbackImageBytes,
  }) {
    final Map<String, dynamic> result = Map<String, dynamic>.from(input);

    final double waterCoverage =
        _toDouble(result['water_coverage_percent']) ?? 0;
    final int detections = _toInt(result['total_detections']) ?? 0;

    result['water_coverage_percent'] = waterCoverage;
    result['total_detections'] = detections;
    result['gps'] = result['gps'] is Map
        ? Map<String, dynamic>.from(result['gps'] as Map)
        : <String, dynamic>{'latitude': null, 'longitude': null};

    result.putIfAbsent(
      'risk_level',
      () => _deriveRiskLevel(waterCoverage, detections),
    );
    result.putIfAbsent(
      'recommendations',
      () => _defaultRecommendations(waterCoverage, detections),
    );

    final dynamic annotated = result['annotated_image_base64'];
    if (annotated == null || annotated.toString().trim().isEmpty) {
      result['annotated_image_base64'] = base64Encode(fallbackImageBytes);
    }

    return result;
  }

  String _deriveRiskLevel(double waterCoverage, int detections) {
    final double score = waterCoverage + (detections * 3.0);
    if (score >= 30) {
      return 'Critical';
    }
    if (score >= 15) {
      return 'High';
    }
    if (score >= 5) {
      return 'Medium';
    }
    return 'Low';
  }

  List<String> _defaultRecommendations(double waterCoverage, int detections) {
    if (waterCoverage <= 0 && detections == 0) {
      return <String>[
        'No obvious breeding spot detected. Continue regular monitoring.',
        'Remove standing water after rain to prevent larvae growth.',
      ];
    }

    return <String>[
      'Drain and scrub any stagnant water containers immediately.',
      'Cover stored water and clean gutters/drains weekly.',
      'Re-scan the same area after cleanup to verify improvement.',
    ];
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString());
  }

  String _guessMimeType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
