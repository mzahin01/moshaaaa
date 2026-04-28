import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

class ResultController extends GetxController {
  late final Map<String, dynamic> result;

  @override
  void onInit() {
    super.onInit();
    final dynamic args = Get.arguments;
    result = args is Map<String, dynamic>
        ? args
        : args is Map
        ? Map<String, dynamic>.from(args)
        : <String, dynamic>{};
  }

  String get riskLevel => result['risk_level']?.toString() ?? 'Unknown';
  double get waterCoverage => _toDouble(result['water_coverage_percent']) ?? 0;
  int get detections => _toInt(result['total_detections']) ?? 0;

  double get possibilityPercent {
    final double? explicit = _readPossibilityPercent();
    if (explicit != null) {
      return explicit;
    }

    return _derivePossibilityPercent(waterCoverage, detections);
  }

  List<String> get recommendations {
    final dynamic value = result['recommendations'];
    if (value is! List) {
      return <String>[];
    }
    return value.map((dynamic item) => item.toString()).toList();
  }

  double? get latitude {
    final Map<String, dynamic> gps = _gps;
    return _toDouble(gps['latitude']);
  }

  double? get longitude {
    final Map<String, dynamic> gps = _gps;
    return _toDouble(gps['longitude']);
  }

  Uint8List? get annotatedBytes =>
      _decodeImage(result['annotated_image_base64']?.toString());

  Map<String, dynamic> get _gps {
    final dynamic value = result['gps'];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
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

  Uint8List? _decodeImage(String? encodedImage) {
    if (encodedImage == null || encodedImage.isEmpty) {
      return null;
    }

    final String normalized = encodedImage.contains(',')
        ? encodedImage.split(',').last
        : encodedImage;

    try {
      return base64Decode(normalized);
    } on FormatException {
      return null;
    }
  }

  double? _readPossibilityPercent() {
    final dynamic raw =
        result['possibility_percent'] ??
        result['possibility'] ??
        result['probability'] ??
        result['confidence'];

    final double? value = _toDouble(raw);
    if (value == null) {
      return null;
    }

    if (value <= 1.0) {
      return (value * 100.0).clamp(0.0, 100.0).toDouble();
    }

    return value.clamp(0.0, 100.0).toDouble();
  }

  double _derivePossibilityPercent(double waterCoverage, int detections) {
    final double score = waterCoverage + (detections * 3.0);
    final double normalized = (score / 30.0).clamp(0.0, 1.0);
    return normalized * 100.0;
  }
}
