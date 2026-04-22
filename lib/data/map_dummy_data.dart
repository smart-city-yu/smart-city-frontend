import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_issue.dart';


final List<MapIssue> initialIssues = [
  MapIssue(
    id: 'pothole_1',
    emoji: '🕳️',
    title: 'Pothole on King Abdullah II St.',
    sub: 'Reported 2h ago',
    desc: 'A large pothole has formed near the intersection. Drivers should be cautious.',
    color: const Color(0xFF8E2922),
    position: LatLng(31.9632, 35.9304), // Amman
  ),
  MapIssue(
    id: 'broken_1',
    emoji: '🚧',
    title: 'Broken Road Surface',
    sub: 'Reported 1h ago',
    desc: 'The asphalt is badly cracked and broken, making the lane unsafe for vehicles.',
    color: const Color(0xFFBB6610),
    position: LatLng(32.0728, 36.0880), // Zarqa
  ),
  MapIssue(
    id: 'tree_1',
    emoji: '🌳',
    title: 'Tree in the Middle of the Road',
    sub: 'Reported 35m ago',
    desc: 'A fallen tree is blocking one side of the road and causing traffic disruption.',
    color: const Color(0xFF3A7D1E),
    position: LatLng(32.5556, 35.8500), // Irbid

  ),
  MapIssue(
    id: 'manhole_1',
    emoji: '⭕',
    title: 'Exposed Manhole',
    sub: 'Reported 50m ago',
    desc: 'An uncovered manhole is exposed near the roadside and is dangerous for drivers and pedestrians.',
    color: const Color(0xFFD14E78),
    position: LatLng(31.7167, 35.8000), // Madaba

  ),
  MapIssue(
    id: 'unpaved_1',
    emoji: '🛣️',
    title: 'Unpaved Street',
    sub: 'Reported 3h ago',
    desc: 'This street remains unpaved, causing dust, rough movement, and drainage issues.',
    color: const Color(0xFF6F5647),
    position: LatLng(29.5320, 35.0063), // Aqaba

  ),
  MapIssue(
    id: 'lamp_1',
    emoji: '💡',
    title: 'Broken Lamppost',
    sub: 'Reported 1d ago',
    desc: 'A broken lamppost has stopped working, reducing visibility and safety at night.',
    color: const Color(0xFFF0B017),
    position: LatLng(31.5590, 35.4732), // Dead Sea

  ),
  MapIssue(
    id: 'speed_1',
    emoji: '⛰️',
    title: 'Illegal Speed Bump',
    sub: 'Reported 25m ago',
    desc: 'An unmarked speed bump was placed illegally and may damage vehicles.',
    color: const Color(0xFF6C8A98),
    position: LatLng(30.3200, 35.4444), // Petra
  ),
];

const List<Map<String, String>> reportCategories = [
  {'emoji': '🕳️', 'label': 'Pothole'},
  {'emoji': '🚧', 'label': 'Broken Road'},
  {'emoji': '🌳', 'label': 'Tree in Road'},
  {'emoji': '🛣️', 'label': 'Unpaved Street'},
  {'emoji': '⭕', 'label': 'Manhole'},
  {'emoji': '💡', 'label': 'Lamppost'},
  {'emoji': '⛰️', 'label': 'Speed Bump'},
];

final List<Map<String, String>> goToCategories = [
  {'label': 'Restaurant', 'emoji': '🍽️'},
  {'label': 'Gas station', 'emoji': '⛽'},
  {'label': 'Park', 'emoji': '🌳'},
  {'label': 'Parking', 'emoji': '🅿️'},
  {'label': 'Supermarket', 'emoji': '🛒'},
  {'label': 'Mosque', 'emoji': '🕌'},
];