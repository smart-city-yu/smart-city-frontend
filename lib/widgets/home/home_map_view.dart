import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_colors.dart';
import '../../models/map_issue.dart';
import '../map_marker.dart';
import '../search_bar_widget.dart';
import 'current_location_marker.dart';

class HomeMapView extends StatelessWidget {
  final MapController mapController;
  final List<MapIssue> mapIssues;
  final LatLng? currentLocation;
  final VoidCallback onLogout;
  final VoidCallback onRecenter;
  final VoidCallback onShowAddReport;
  final VoidCallback onShowGoTo;
  final ValueChanged<MapIssue> onTapIssue;
  final List<LatLng> pathPoints;

  const HomeMapView({
    super.key,
    required this.mapController,
    required this.mapIssues,
    required this.currentLocation,
    required this.onLogout,
    required this.onRecenter,
    required this.onShowAddReport,
    required this.onShowGoTo,
    required this.onTapIssue,
    required this.pathPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(31.24, 36.51),
              initialZoom: 7.5,
              minZoom: 6,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.roadna',
              ),
              if (pathPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pathPoints,
                      strokeWidth: 8,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ...mapIssues.map((issue) {
                    return Marker(
                      point: issue.position,
                      width: 40,
                      height: 40,
                      child: MapMarker(
                        emoji: issue.emoji,
                        color: issue.color,
                        onTap: () => onTapIssue(issue),
                      ),
                    );
                  }),
                  if (currentLocation != null)
                    Marker(
                      point: currentLocation!,
                      width: 30,
                      height: 30,
                      child: const CurrentLocationMarker(),
                    ),
                ],
              ),
            ],
          ),
          SearchBarWidget(onLogout: onLogout),
          Positioned(
            left: 14,
            bottom: 96,
            child: ElevatedButton.icon(
              onPressed: onShowGoTo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.greenDark,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: const Text(
                'Go To',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 150,
            child: Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRecenter,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.my_location, color: AppColors.textGrey),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 86,
            child: FloatingActionButton(
              backgroundColor: AppColors.green,
              onPressed: onShowAddReport,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
