import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_issue.dart';
import '../models/app_category.dart';

class MapIssueParser {
  static MapIssue fromJson(Map<String, dynamic> json) {
    final categoryValue = json['category'] as String? ?? '';
    final cat = reportCategoryFromValue(categoryValue);

    return MapIssue(
      id: json['reportId']?.toString() ?? json['id']?.toString() ?? '',
      emoji: cat?.emoji ?? '📍',
      title: cat?.displayName ?? 'Road Issue',
      sub: json['status']?.toString() ?? 'Reported',
<<<<<<< HEAD
      desc: json['description']?.toString() ?? '',
=======
      desc: json['aiAnalysis']?.toString() ??
            json['validationReason']?.toString() ??
            json['description']?.toString() ?? '',
>>>>>>> c97f44e (Edit Last Version Before Last uploaded Version From Leen)
      color: cat?.color ?? const Color(0xFF607D8B),
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lon'] as num).toDouble(),
      ),
<<<<<<< HEAD
      stillThereCount: json['still_there_count'] as int? ?? 0,
      fixedCount: json['fixed_count'] as int? ?? 0,
      isVoted: json['is_voted'] as bool? ?? false,
=======
      stillThereCount: (json['stillVotes'] ?? json['stillThereCount'] ?? json['still_there_count']) as int? ?? 0,
      fixedCount: (json['fixedVotes'] ?? json['fixedCount'] ?? json['fixed_count']) as int? ?? 0,
      isVoted: (json['isVoted'] ?? json['is_voted']) as bool? ?? false,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      subProblem: json['subProblem'] as String?,
>>>>>>> c97f44e (Edit Last Version Before Last uploaded Version From Leen)
    );
  }

  static List<MapIssue> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
  }
}