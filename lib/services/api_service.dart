import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://rifath1729-mosquito-breeding-spot-detection.hf.space';

  final http.Client _client;

  Future<Map<String, dynamic>> analyzeImage({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final String filePath = await _uploadImage(imageBytes, fileName);
    final String eventId = await _triggerAnalysis(filePath);
    return _fetchResult(eventId);
  }

  Future<String> _uploadImage(Uint8List imageBytes, String fileName) async {
    final http.MultipartRequest request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'))
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

  Future<String> _triggerAnalysis(String filePath) async {
    final http.Response response = await _client.post(
      Uri.parse('$_baseUrl/call/analyze'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'data': <Map<String, String>>[
          <String, String>{'path': filePath},
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

  Future<Map<String, dynamic>> _fetchResult(String eventId) async {
    final http.Response response = await _client
        .get(Uri.parse('$_baseUrl/call/analyze/$eventId'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Analyze result failed (${response.statusCode}): ${response.body}',
      );
    }

    final List<String> chunks = response.body.split('data: ');
    if (chunks.length < 2) {
      throw const FormatException(
        'SSE response did not include the expected second data chunk.',
      );
    }

    final String secondChunk = chunks[1].trim();
    final String jsonChunk = secondChunk.split('\n').first.trim();

    final dynamic parsed = jsonDecode(jsonChunk);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException(
        'Second SSE chunk was not valid JSON object.',
      );
    }

    final dynamic data = parsed['data'];
    if (data is! List || data.isEmpty || data[0] is! Map) {
      throw const FormatException('Result payload missing data[0] map.');
    }

    return Map<String, dynamic>.from(data[0] as Map);
  }
}
