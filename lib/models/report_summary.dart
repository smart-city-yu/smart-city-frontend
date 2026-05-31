import 'package:maplibre_gl/maplibre_gl.dart';

class ReportSummary {
  final double lat;
  final double lng;
  final int count;

  const ReportSummary({
    required this.lat,
    required this.lng,
    required this.count,
  });

  LatLng get position => LatLng(lat, lng);

  /// `false` when the backend returned null lat/lng — filter these out.
  bool get hasValidPosition => lat != 0.0 || lng != 0.0;

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}
