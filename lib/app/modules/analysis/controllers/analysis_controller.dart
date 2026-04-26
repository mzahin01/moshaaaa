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

      await Get.offNamed(Routes.result, arguments: result);
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
