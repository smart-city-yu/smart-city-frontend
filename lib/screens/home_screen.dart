import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_colors.dart';
import '../data/map_dummy_data.dart';
import '../models/app_category.dart';
import '../models/map_issue.dart';
import '../models/path_node.dart';
import '../models/place_marker.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../services/routing_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home/add_report_sheet.dart';
import '../widgets/home/go_to_sheet.dart';
import '../widgets/home/home_map_view.dart';
import '../widgets/home/issue_details_sheet.dart';
import '../widgets/home/place_details_sheet.dart';
import '../widgets/home/report_form_sheet.dart';
import '../widgets/home/success_dialog.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── services ─────────────────────────────────────────────────────────────
  final AuthService _authService = AuthService();
  final ReportService _reportService = ReportService();
  final RoutingService _routingService = RoutingService();

  // ── navigation ────────────────────────────────────────────────────────────
  int _selectedNavIndex = 0;

  // ── map state ─────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  late List<MapIssue> _mapIssues;        // road-issue markers
  List<PlaceMarker> _placeMarkers = [];  // nearby-place pins (Go-To mode)
  List<LatLng> _pathPoints = [];         // active route polyline

  final Set<String> _votedIssueIds = {};

  bool _isLoading = false; // overlay for long API calls

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _mapIssues = List<MapIssue>.from(initialIssues);
    _loadLocation();
    _loadReports();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  String _formatDistance(double meters) => meters < 1000
      ? '${meters.round()} m away'
      : '${(meters / 1000).toStringAsFixed(1)} km away';

  // ── location ──────────────────────────────────────────────────────────────

  Future<void> _loadLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
    _mapController.move(_currentLocation!, 16);
  }

  void _recenterMap() {
    if (_currentLocation != null) _mapController.move(_currentLocation!, 16);
  }

  // ── GET /api/report/all ───────────────────────────────────────────────────

  Future<void> _loadReports() async {
    final result = await _reportService.getAllReports();
    if (!mounted) return;
    if (result['success'] == true) {
      final list = result['data'] as List<dynamic>;
      if (list.isNotEmpty) {
        setState(() {
          _mapIssues = list
              .map((j) => MapIssue.fromJson(j as Map<String, dynamic>))
              .toList();
        });
      }
      // empty → backend stub still active → keep initialIssues
    }
  }

  // ── auth ──────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  // ── POST /api/report/vote ─────────────────────────────────────────────────

  void _showIssueSheet(MapIssue issue) {
    showIssueDetailsSheet(
      context: context,
      issue: issue,
      alreadyVoted: _votedIssueIds.contains(issue.id),
      onVoteStillThere: () {
        setState(() => _votedIssueIds.add(issue.id));
        _reportService.voteReport(reportId: issue.id, voteType: 'Still');
      },
      onVoteFixed: () {
        setState(() => _votedIssueIds.add(issue.id));
        _reportService.voteReport(reportId: issue.id, voteType: 'Fixed');
      },
    );
  }

  // ── report creation ───────────────────────────────────────────────────────

  void _showAddReportSheet() {
    showAddReportSheet(
      context: context,
      onCategorySelected: (AppCategory cat) => _showReportForm(cat),
    );
  }

  void _showReportForm(AppCategory category) {
    showReportFormSheet(
      context: context,
      label: category.displayName,
      emoji: category.emoji,
      onSubmit: (String desc) =>
          _submitReport(category: category, description: desc),
    );
  }

  // POST /api/report/create
  Future<void> _submitReport({
    required AppCategory category,
    required String description,
  }) async {
    if (_currentLocation == null) {
      _snack('Location unavailable. Allow location access first.');
      return;
    }

    // Optimistic marker
    setState(() {
      _mapIssues.add(MapIssue(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        emoji: category.emoji,
        title: '${category.displayName} Report',
        sub: 'Reported just now',
        desc: description,
        color: category.color,
        position: _currentLocation!,
      ));
    });
    _mapController.move(_currentLocation!, 16);

    await _reportService.createReport(
      category: category.backendValue,
      description: description,
      lat: _currentLocation!.latitude,
      lon: _currentLocation!.longitude,
    );

    if (mounted) {
      showSuccessDialog(
        context: context,
        title: 'Report Submitted!',
        message:
            'Your ${category.displayName} report has been pinned at your current location.',
      );
    }
  }

  // ── Go-To flow ────────────────────────────────────────────────────────────
  //
  // New behaviour:
  //   1. User selects a category  →  GET /api/routing/places
  //   2. All returned places appear as green pin markers on the map
  //   3. User taps a pin  →  showPlaceDetailsSheet
  //   4. User taps "Route"  →  POST /api/routing/route  →  polyline drawn

  void _showGoToSheet() {
    showGoToSheet(
      context: context,
      onCategorySelected: (AppCategory category) async {
        if (_currentLocation == null) {
          _snack('Location unavailable. Allow location access.');
          return;
        }

        _setLoading(true);

        // ── GET /api/routing/places ──────────────────────────────────────
        final result = await _routingService.getNearbyPlaces(
          lat: _currentLocation!.latitude,
          lon: _currentLocation!.longitude,
          categoryBackendValue: category.backendValue,
        );

        _setLoading(false);
        if (!mounted) return;

        final rawList = result['data'] as List<dynamic>?;
        if (result['success'] != true || rawList == null || rawList.isEmpty) {
          _snack(result['message'] as String? ??
              'No ${category.displayName} found nearby.');
          return;
        }

        // Parse every H3PlaceWrapper into a PlaceMarker
        final places = rawList
            .map((j) =>
                PlaceMarker.fromH3Json(j as Map<String, dynamic>, category))
            .toList();

        setState(() {
          _placeMarkers = places;
          _pathPoints = [];          // clear any previous route
        });

        // Pan map to the first result so the pins are immediately visible
        _mapController.move(
          LatLng(places.first.lat, places.first.lon),
          14,
        );
      },
    );
  }

  /// Dismiss all place pins (and any active route).
  void _clearPlaces() {
    setState(() {
      _placeMarkers = [];
      _pathPoints = [];
    });
  }

  // Called when user taps a place pin on the map
  void _onTapPlace(PlaceMarker place) {
    if (_currentLocation == null) {
      _snack('Location unavailable.');
      return;
    }

    final dist = const Distance()(
      _currentLocation!,
      LatLng(place.lat, place.lon),
    );

    showPlaceDetailsSheet(
      context: context,
      place: place,
      distanceStr: _formatDistance(dist),
      onRoute: () => _routeToPlace(place),
    );
  }

  // POST /api/routing/route
  Future<void> _routeToPlace(PlaceMarker place) async {
    if (_currentLocation == null) return;

    _setLoading(true);

    final result = await _routingService.getRoute(
      lat1: _currentLocation!.latitude,
      lon1: _currentLocation!.longitude,
      lat2: place.lat,
      lon2: place.lon,
    );

    _setLoading(false);
    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final rawNodes = data['pathNodes'] as List<dynamic>;
      final nodes = rawNodes
          .map((n) => PathNode.fromJson(n as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _pathPoints =
            nodes.map((n) => LatLng(n.latitude, n.longitude)).toList();
        _placeMarkers = []; // route is shown — clear place pins
      });
      _mapController.move(_currentLocation!, 15);
    }

    showSuccessDialog(
      context: context,
      title: 'Navigation Started',
      message:
          'Routing to ${place.name}. Follow the directions on the map.',
    );
  }

  // ── utils ─────────────────────────────────────────────────────────────────

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_selectedNavIndex == 3) return const ProfileScreen();

    return HomeMapView(
      mapController: _mapController,
      mapIssues: _mapIssues,
      placeMarkers: _placeMarkers,
      currentLocation: _currentLocation,
      onLogout: _logout,
      onRecenter: _recenterMap,
      onShowAddReport: _showAddReportSheet,
      onShowGoTo: _showGoToSheet,
      onClearPlaces: _clearPlaces,
      onTapIssue: _showIssueSheet,
      onTapPlace: _onTapPlace,
      pathPoints: _pathPoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildBody()),
                HomeBottomNavBar(
                  selectedIndex: _selectedNavIndex,
                  onTap: (i) => setState(() => _selectedNavIndex = i),
                ),
              ],
            ),
          ),
        ),

        // ── full-screen loading overlay ─────────────────────────────────────
        if (_isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55000000),
              child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}
