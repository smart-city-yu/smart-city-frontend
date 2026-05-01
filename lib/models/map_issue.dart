import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'app_category.dart';

class MapIssue {
  final String id;
  final String emoji;
  final String title;
  final String sub;
  final String desc;
  final Color color;
  final LatLng position;

  final int stillThereCount;
  final int fixedCount;
  final bool isVoted;


  const MapIssue({
    required this.id,
    required this.emoji,
    required this.title,
    required this.sub,
    required this.desc,
    required this.color,
    required this.position,

    this.stillThereCount = 0,
    this.fixedCount = 0,
    this.isVoted = false,
  });

  /// Builds a [MapIssue] from a backend Report JSON object.
  ///
  /// Expected shape (mirrors the Report JPA entity):
  /// ```json
  /// {
  ///   "reportId":    "abc123",
  ///   "description": "Large pothole near intersection",
  ///   "lat":         31.9632,
  ///   "lon":         35.9304,
  ///   "category":    "pothole"   // exact ReportCategory enum value
  /// }
  /// ```
  factory MapIssue.fromJson(Map<String, dynamic> json) {
    final categoryValue = json['category'] as String? ?? '';
    final cat = reportCategoryFromValue(categoryValue);

    return MapIssue(
      id: json['reportId'] as String? ?? '',
      emoji: cat?.emoji ?? '📍',
      title: cat?.displayName ?? 'Road Issue',
      sub: 'Reported',
      desc: json['description'] as String? ?? '',
      color: cat?.color ?? const Color(0xFF607D8B),
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lon'] as num).toDouble(),
      ),
    );
  }

  MapIssue copyWith({
    String? id,
    String? emoji,
    String? title,
    String? sub,
    String? desc,
    Color? color,
    LatLng? position,
  }) {
    return MapIssue(
      id: id ?? this.id,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      sub: sub ?? this.sub,
      desc: desc ?? this.desc,
      color: color ?? this.color,
      position: position ?? this.position,
    );
  }
}