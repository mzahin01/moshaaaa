import 'dart:typed_data';

import 'package:exif/exif.dart';

class ExifGpsService {
  Future<Map<String, double>?> extractGps(Uint8List imageBytes) async {
    try {
      final Map<String, IfdTag> tags = await readExifFromBytes(
        imageBytes,
        details: false,
      );

      return _extractGps(tags);
    } catch (_) {
      return null;
    }
  }

  Map<String, double>? _extractGps(Map<String, IfdTag> tags) {
    final IfdTag? latTag = tags['GPS GPSLatitude'];
    final IfdTag? latRefTag = tags['GPS GPSLatitudeRef'];
    final IfdTag? lngTag = tags['GPS GPSLongitude'];
    final IfdTag? lngRefTag = tags['GPS GPSLongitudeRef'];

    if (latTag == null ||
        latRefTag == null ||
        lngTag == null ||
        lngRefTag == null) {
      return null;
    }

    final double? latitude = _convertToDecimalDegrees(
      latTag.values.toList(),
      latRefTag.printable,
    );
    final double? longitude = _convertToDecimalDegrees(
      lngTag.values.toList(),
      lngRefTag.printable,
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    return <String, double>{'latitude': latitude, 'longitude': longitude};
  }

  double? _convertToDecimalDegrees(List<dynamic> dms, String ref) {
    if (dms.isEmpty) {
      return null;
    }

    if (dms.length == 1) {
      final double? degrees = _partToDouble(dms.first);
      if (degrees == null) {
        return null;
      }
      return _applyRef(degrees, ref);
    }

    if (dms.length < 3) {
      return null;
    }

    final double? degrees = _partToDouble(dms[0]);
    final double? minutes = _partToDouble(dms[1]);
    final double? seconds = _partToDouble(dms[2]);

    if (degrees == null || minutes == null || seconds == null) {
      return null;
    }

    final double decimal = degrees + (minutes / 60.0) + (seconds / 3600.0);
    return _applyRef(decimal, ref);
  }

  double _applyRef(double value, String ref) {
    final String normalized = ref.trim().toUpperCase();
    if (normalized.startsWith('S') || normalized.startsWith('W')) {
      return -value;
    }
    return value;
  }

  double? _partToDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is Ratio) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
