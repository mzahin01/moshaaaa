import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/api_service.dart';
import '../../../routes/app_pages.dart';

class AnalysisController extends GetxController {
  final ApiService _apiService = ApiService();
  final RxBool isAnalyzing = false.obs;

  Uint8List imageBytes = Uint8List(0);
  String fileName = 'scan_image.jpg';
  double? metadataLatitude;
  double? metadataLongitude;
  bool _started = false;

  @override
  void onInit() {
    super.onInit();
    _readArguments();
  }

  @override
  void onReady() {
    super.onReady();
    if (!_started) {
      _started = true;
      unawaited(startAnalysis());
    }
  }

  Future<void> startAnalysis() async {
    if (isAnalyzing.value) {
      return;
    }

    if (imageBytes.isEmpty) {
      _showRetrySnackbar('No image found to analyze.');
      return;
    }

    isAnalyzing.value = true;
    try {
      final Map<String, dynamic> result = await _apiService.analyzeImage(
        imageBytes: imageBytes,
        fileName: fileName,
      );

      await Get.offNamed(Routes.result, arguments: _mergeMetadataGps(result));
    } on TimeoutException {
      _showRetrySnackbar('Analysis timed out after 60 seconds.');
    } catch (error) {
      _showRetrySnackbar('Analysis failed: $error');
    } finally {
      isAnalyzing.value = false;
    }
  }

  void _readArguments() {
    final dynamic args = Get.arguments;
    if (args is! Map) {
      return;
    }

    final dynamic rawBytes = args['imageBytes'];
    if (rawBytes is Uint8List) {
      imageBytes = rawBytes;
    } else if (rawBytes is List<int>) {
      imageBytes = Uint8List.fromList(rawBytes);
    }

    final dynamic rawName = args['fileName'];
    if (rawName is String && rawName.trim().isNotEmpty) {
      fileName = rawName;
    }

    final dynamic rawMetadataGps = args['metadataGps'];
    if (rawMetadataGps is Map) {
      metadataLatitude = _toDouble(rawMetadataGps['latitude']);
      metadataLongitude = _toDouble(rawMetadataGps['longitude']);
    }
  }

  Map<String, dynamic> _mergeMetadataGps(Map<String, dynamic> result) {
    if (metadataLatitude == null || metadataLongitude == null) {
      return result;
    }

    final Map<String, dynamic> merged = Map<String, dynamic>.from(result);
    final Map<String, dynamic> gps = merged['gps'] is Map
        ? Map<String, dynamic>.from(merged['gps'] as Map)
        : <String, dynamic>{};

    gps['latitude'] = metadataLatitude;
    gps['longitude'] = metadataLongitude;
    merged['gps'] = gps;

    return merged;
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

  void _showRetrySnackbar(String message) {
    Get.closeCurrentSnackbar();
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
        mainButton: TextButton(
          onPressed: () {
            Get.closeCurrentSnackbar();
            unawaited(startAnalysis());
          },
          child: const Text('Retry'),
        ),
      ),
    );
  }
}
