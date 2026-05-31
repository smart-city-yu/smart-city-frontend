import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/api_constants.dart';
import '../../core/app_colors.dart';
import '../../models/map_issue.dart';
import '../../models/place_marker.dart';
import '../../models/report_summary.dart';
import '../search_bar_widget.dart';

class HomeMapView extends StatefulWidget {
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
  final void Function(MapLibreMapController controller)? onMapCreated;
  final VoidCallback? onMapReady;

  const HomeMapView({
    super.key,
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
    this.onMapCreated,
    this.onMapReady,
  });

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  MapLibreMapController? _ctrl;
  bool _styleLoaded = false;

  // Active annotations — keyed by issue id for issues, plain list for others
  final Map<String, Symbol> _issueSymbols = {};
  final Map<Symbol, MapIssue> _symbolToIssue = {};
  final List<Symbol> _summarySymbols = [];
  final List<Symbol> _placeSymbols = [];
  final Map<Symbol, PlaceMarker> _symbolToPlace = {};
  Symbol? _locationSymbol;
  Line? _routeLine;

  // Images already added to the map style — avoids duplicate addImage calls
  final Set<String> _registeredImages = {};

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(HomeMapView old) {
    super.didUpdateWidget(old);
    if (!_styleLoaded || _ctrl == null) return;

    final issuesChanged = !_sameIssueList(widget.mapIssues, old.mapIssues) ||
        !_sameSummaryList(widget.summaryMarkers, old.summaryMarkers);
    if (issuesChanged) _updateIssueAndSummaryMarkers();

    if (!_samePlaceList(widget.placeMarkers, old.placeMarkers)) {
      _updatePlaceMarkers();
    }
    if (widget.currentLocation != old.currentLocation) {
      _updateLocationMarker();
    }
    if (widget.pathPoints != old.pathPoints) {
      _updateRouteLine();
    }
  }

  @override
  void dispose() {
    _ctrl?.onSymbolTapped.remove(_onSymbolTapped);
    super.dispose();
  }

  // ── Map callbacks ────────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _ctrl = controller;
    _ctrl!.onSymbolTapped.add(_onSymbolTapped);
    widget.onMapCreated?.call(controller);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _updateIssueAndSummaryMarkers();
    await _updatePlaceMarkers();
    await _updateLocationMarker();
    await _updateRouteLine();
    widget.onMapReady?.call();
  }

  Future<void> _onCameraIdle() async {
    if (widget.onMapMove == null || _ctrl == null) return;
    final bounds = await _ctrl!.getVisibleRegion();
    final zoom = _ctrl!.cameraPosition?.zoom ?? 7.5;
    widget.onMapMove!(bounds, zoom);
  }

  void _onSymbolTapped(Symbol symbol) {
    final issue = _symbolToIssue[symbol];
    if (issue != null) {
      widget.onTapIssue(issue);
      return;
    }
    final place = _symbolToPlace[symbol];
    if (place != null) widget.onTapPlace(place);
  }

  // ── Shallow equality helpers (avoids redundant re-renders) ───────────────

  bool _sameIssueList(List<MapIssue> a, List<MapIssue> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  bool _sameSummaryList(List<ReportSummary> a, List<ReportSummary> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].lat != b[i].lat ||
          a[i].lng != b[i].lng ||
          a[i].count != b[i].count) {
        return false;
      }
    }
    return true;
  }

  bool _samePlaceList(List<PlaceMarker> a, List<PlaceMarker> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].lat != b[i].lat || a[i].lon != b[i].lon) return false;
    }
    return true;
  }

  // ── Marker image rendering (dart:ui canvas → PNG bytes) ─────────────────

  Future<void> _ensureImage(
      String key, Future<Uint8List> Function() render) async {
    if (_registeredImages.contains(key)) return;
    final bytes = await render();
    await _ctrl!.addImage(key, bytes);
    _registeredImages.add(key);
  }

  Future<Uint8List> _renderEmojiMarker(String emoji, Color color) async {
    const double sz = 44;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, sz, sz));

    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2,
      Paint()..color = color.withValues(alpha: 0.25),
    );
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 * 0.65,
      Paint()..color = color,
    );

    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 17),
    )..addText(emoji);
    final para = pb.build()..layout(ui.ParagraphConstraints(width: sz));
    canvas.drawParagraph(para, Offset(0, (sz - para.height) / 2));

    final img =
        await recorder.endRecording().toImage(sz.toInt(), sz.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<Uint8List> _renderClusterImage(int count) async {
    const double sz = 52;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, sz, sz));

    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 - 3,
      Paint()..color = AppColors.primary.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 - 3,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final text = count > 999 ? '999+' : count.toString();
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: count > 99 ? 11 : 14,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
        fontWeight: ui.FontWeight.bold,
      ))
      ..addText(text);
    final para = pb.build()..layout(ui.ParagraphConstraints(width: sz));
    canvas.drawParagraph(para, Offset(0, (sz - para.height) / 2));

    final img =
        await recorder.endRecording().toImage(sz.toInt(), sz.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<Uint8List> _renderPlaceMarkerImage(String emoji) async {
    const double w = 48, h = 62;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

    // Pin tail
    final tail = Path()
      ..moveTo(w / 2 - 9, w - 8)
      ..lineTo(w / 2 + 9, w - 8)
      ..lineTo(w / 2, h - 2)
      ..close();
    canvas.drawPath(tail, Paint()..color = AppColors.green);

    // Circle body
    canvas.drawCircle(
      Offset(w / 2, w / 2),
      w / 2 - 2,
      Paint()..color = AppColors.green,
    );
    canvas.drawCircle(
      Offset(w / 2, w / 2),
      w / 2 - 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 20),
    )..addText(emoji);
    final para = pb.build()..layout(ui.ParagraphConstraints(width: w));
    canvas.drawParagraph(para, Offset(0, (w - para.height) / 2));

    final img =
        await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  Future<Uint8List> _renderLocationImage() async {
    const double sz = 36;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, sz, sz));

    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2,
      Paint()..color = const Color(0x664285F4),
    );
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 * 0.52,
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawCircle(
      const Offset(sz / 2, sz / 2),
      sz / 2 * 0.52,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final img =
        await recorder.endRecording().toImage(sz.toInt(), sz.toInt());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  // ── Annotation update methods ────────────────────────────────────────────

  Future<void> _updateIssueAndSummaryMarkers() async {
    if (_ctrl == null) return;

    // Remove old issue symbols
    for (final sym in _issueSymbols.values) {
      _symbolToIssue.remove(sym);
      await _ctrl!.removeSymbol(sym);
    }
    _issueSymbols.clear();

    // Remove old cluster symbols
    for (final sym in _summarySymbols) {
      await _ctrl!.removeSymbol(sym);
    }
    _summarySymbols.clear();

    if (widget.summaryMarkers.isNotEmpty) {
      for (final s in widget.summaryMarkers) {
        final clampedCount = s.count > 999 ? 999 : s.count;
        final imgKey = 'cluster_$clampedCount';
        await _ensureImage(imgKey, () => _renderClusterImage(s.count));
        final sym = await _ctrl!.addSymbol(SymbolOptions(
          geometry: LatLng(s.lat, s.lng),
          iconImage: imgKey,
          iconSize: 1.0,
          iconAnchor: 'center',
        ));
        _summarySymbols.add(sym);
      }
    } else {
      for (final issue in widget.mapIssues) {
        final imgKey =
            'issue_${issue.emoji}_${issue.color.toARGB32().toRadixString(16)}';
        await _ensureImage(
            imgKey, () => _renderEmojiMarker(issue.emoji, issue.color));
        final sym = await _ctrl!.addSymbol(SymbolOptions(
          geometry: issue.position,
          iconImage: imgKey,
          iconSize: 1.0,
          iconAnchor: 'center',
        ));
        _issueSymbols[issue.id] = sym;
        _symbolToIssue[sym] = issue;
      }
    }
  }

  Future<void> _updatePlaceMarkers() async {
    if (_ctrl == null) return;

    for (final sym in _placeSymbols) {
      _symbolToPlace.remove(sym);
      await _ctrl!.removeSymbol(sym);
    }
    _placeSymbols.clear();

    for (final place in widget.placeMarkers) {
      final imgKey = 'place_${place.category.emoji}';
      await _ensureImage(
          imgKey, () => _renderPlaceMarkerImage(place.category.emoji));
      final sym = await _ctrl!.addSymbol(SymbolOptions(
        geometry: LatLng(place.lat, place.lon),
        iconImage: imgKey,
        iconSize: 1.0,
        iconAnchor: 'bottom',
      ));
      _placeSymbols.add(sym);
      _symbolToPlace[sym] = place;
    }
  }

  Future<void> _updateLocationMarker() async {
    if (_ctrl == null) return;

    if (_locationSymbol != null) {
      await _ctrl!.removeSymbol(_locationSymbol!);
      _locationSymbol = null;
    }
    if (widget.currentLocation == null) return;

    await _ensureImage('location', _renderLocationImage);
    _locationSymbol = await _ctrl!.addSymbol(SymbolOptions(
      geometry: widget.currentLocation!,
      iconImage: 'location',
      iconSize: 1.0,
      iconAnchor: 'center',
      zIndex: 10,
    ));
  }

  Future<void> _updateRouteLine() async {
    if (_ctrl == null) return;

    if (_routeLine != null) {
      await _ctrl!.removeLine(_routeLine!);
      _routeLine = null;
    }
    if (widget.pathPoints.isEmpty) return;

    // Convert Flutter Color(0xFF2E7D32) → '#2E7D32'
    final hex = AppColors.primary.toARGB32().toRadixString(16).padLeft(8, '0');
    _routeLine = await _ctrl!.addLine(LineOptions(
      geometry: widget.pathPoints,
      lineColor: '#${hex.substring(2)}',
      lineWidth: 8.0,
      lineOpacity: 1.0,
      lineJoin: 'round',
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showingPlaces = widget.placeMarkers.isNotEmpty;

    return Stack(
      children: [
        // ── MapLibre map ───────────────────────────────────────────────────
        MapLibreMap(
          styleString: kMapTilerStyleUrl,
          initialCameraPosition: const CameraPosition(
            target: LatLng(31.24, 36.51),
            zoom: 7.5,
          ),
          minMaxZoomPreference: const MinMaxZoomPreference(6, 18),
          trackCameraPosition: true,
          compassEnabled: false,
          myLocationEnabled: false,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          onCameraIdle: _onCameraIdle,
        ),

        // ── top bar ────────────────────────────────────────────────────────
        SearchBarWidget(onLogout: widget.onLogout),

        // ── "Clear places" chip ────────────────────────────────────────────
        if (showingPlaces)
          Positioned(
            left: 14,
            bottom: 148,
            child: GestureDetector(
              onTap: widget.onClearPlaces,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
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
                      widget.placeMarkers.first.category.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.placeMarkers.length} places',
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

        // ── Go-To button ───────────────────────────────────────────────────
        Positioned(
          left: 14,
          bottom: 96,
          child: ElevatedButton.icon(
            onPressed: widget.onShowGoTo,
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

        // ── Zoom buttons ───────────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: 202,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapControlButton(
                icon: Icons.add,
                onTap: () => _ctrl?.animateCamera(CameraUpdate.zoomIn()),
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.remove,
                onTap: () => _ctrl?.animateCamera(CameraUpdate.zoomOut()),
              ),
            ],
          ),
        ),

        // ── Recenter button ────────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: 150,
          child: Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onRecenter,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.my_location, color: AppColors.textGrey),
              ),
            ),
          ),
        ),

        // ── Add-report FAB ─────────────────────────────────────────────────
        Positioned(
          right: 14,
          bottom: 86,
          child: FloatingActionButton(
            backgroundColor: AppColors.green,
            onPressed: widget.onShowAddReport,
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
