import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapIssue {
  final String id;
  final String emoji;
  final String title;
  final String sub;
  final String desc;
  final Color color;
  final LatLng position;

  const MapIssue({
    required this.id,
    required this.emoji,
    required this.title,
    required this.sub,
    required this.desc,
    required this.color,
    required this.position,
  });

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