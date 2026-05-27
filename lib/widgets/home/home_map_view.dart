import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/app_colors.dart';
import '../../models/map_issue.dart';
import '../../models/place_marker.dart';
import '../../models/report_summary.dart';
import '../map_marker.dart';
import '../map_place_marker.dart';
import '../search_bar_widget.dart';
import 'current_location_marker.dart';

class HomeMapView extends StatelessWidget {
  final MapController mapController;
  final List<MapIssue> mapIssues;
  final List<PlaceMarker> placeMarkers;
  final List<ReportSummary> summaryMarkers;
  final LatLng? currentLocation;
  final VoidCallback onLogout;
  final VoidCallback onRecenter;
  final VoidCallback onShowAddReport;
  final VoidCallback onShowGoTo;
  final VoidCallback onClearPlaces;
  final ValueChanged<MapIssue> onTapIssue;
  final ValueChanged<PlaceMarker> onTapPlace;
  final List<LatLng> pathPoints;
  final void Function(LatLngBounds bounds, double zoom)? onMapMove;
  final VoidCallback? onMapReady;

  const HomeMapView({
    super.key,
    required this.mapController,
    required this.mapIssues,
    required this.placeMarkers,
    required this.currentLocation,
    required this.onLogout,
    required this.onRecenter,
    required this.onShowAddReport,
    required this.onShowGoTo,
    required this.onClearPlaces,
    required this.onTapIssue,
    required this.onTapPlace,
    required this.pathPoints,
    this.summaryMarkers = const [],
    this.onMapMove,
    this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    final showingPlaces = placeMarkers.isNotEmpty;
    final showingSummary = summaryMarkers.isNotEmpty;

    return Stack(
        children: [
          // ── map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(31.24, 36.51),
              initialZoom: 7.5,
              minZoom: 6,
              maxZoom: 18,
              onMapReady: onMapReady,
              onMapEvent: (MapEvent event) {
                if (onMapMove == null) return;
                // MapEventMove covers programmatic moves (zoom buttons, recenter,
                // mapController.move) as well as continuous gestures.
                // The remaining types cover scroll-wheel, double-tap, and
                // fling-end on devices where MoveEnd doesn't fire reliably.
                if (event is MapEventMove ||
                    event is MapEventMoveEnd ||
                    event is MapEventFlingAnimationEnd ||
                    event is MapEventScrollWheelZoom ||
                    event is MapEventDoubleTapZoomEnd) {
                  onMapMove!(
                    event.camera.visibleBounds,
                    event.camera.zoom,
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.roadna',
              ),

              // route polyline
              if (pathPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pathPoints,
                      strokeWidth: 8,
                      color: AppColors.primary,
                    ),
                  ],
                ),

              // cluster summary markers (zoom < 12)
              if (showingSummary)
                MarkerLayer(
                  markers: summaryMarkers
                      .map(
                        (s) => Marker(
                          point: s.position,
                          width: 48,
                          height: 48,
                          child: _ClusterMarker(count: s.count),
                        ),
                      )
                      .toList(),
                ),

              // individual road-issue markers (zoom >= 12)
              if (!showingSummary)
                MarkerLayer(
                  markers: [
                    ...mapIssues.map(
                      (issue) => Marker(
                        point: issue.position,
                        width: 40,
                        height: 40,
                        child: MapMarker(
                          emoji: issue.emoji,
                          color: issue.color,
                          onTap: () => onTapIssue(issue),
                        ),
                      ),
                    ),
                    if (currentLocation != null)
                      Marker(
                        point: currentLocation!,
                        width: 30,
                        height: 30,
                        child: const CurrentLocationMarker(),
                      ),
                  ],
                ),

              // current-location dot still visible in summary mode
              if (showingSummary && currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      width: 30,
                      height: 30,
                      child: const CurrentLocationMarker(),
                    ),
                  ],
                ),

              // place markers (shown after Go-To category is selected)
              if (showingPlaces)
                MarkerLayer(
                  markers: placeMarkers
                      .map(
                        (p) => Marker(
                          point: LatLng(p.lat, p.lon),
                          width: 50,
                          height: 50,
                          // bottomCenter → pin tail points at the coordinate
                          alignment: Alignment.bottomCenter,
                          child: MapPlaceMarker(
                            emoji: p.category.emoji,
                            onTap: () => onTapPlace(p),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),

          // ── top bar ───────────────────────────────────────────────────────
          SearchBarWidget(onLogout: onLogout),

          // ── "Clear places" chip — appears while place pins are visible ────
          if (showingPlaces)
            Positioned(
              left: 14,
              bottom: 148,
              child: GestureDetector(
                onTap: onClearPlaces,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        placeMarkers.first.category.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${placeMarkers.length} places',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.close,
                          size: 15, color: AppColors.textGrey),
                    ],
                  ),
                ),
              ),
            ),

          // ── Go-To button ──────────────────────────────────────────────────
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 11),
              ),
              icon: const Icon(Icons.navigation_outlined, size: 16),
              label: const Text(
                'Go To',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // ── zoom buttons ─────────────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: 202,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  onTap: () {
                    final cam = mapController.camera;
                    mapController.move(cam.center, (cam.zoom + 1).clamp(6, 18));
                  },
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  onTap: () {
                    final cam = mapController.camera;
                    mapController.move(cam.center, (cam.zoom - 1).clamp(6, 18));
                  },
                ),
              ],
            ),
          ),

          // ── recenter button ───────────────────────────────────────────────
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
                  child: Icon(Icons.my_location,
                      color: AppColors.textGrey),
                ),
              ),
            ),
          ),

          // ── add-report FAB ────────────────────────────────────────────────
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
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.textGrey),
        ),
      ),
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  final int count;

  const _ClusterMarker({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 999 ? '999+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}