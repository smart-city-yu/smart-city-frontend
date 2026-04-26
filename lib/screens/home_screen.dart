import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/home/nearest_place_sheet.dart';
import '../core/app_colors.dart';
import '../data/map_dummy_data.dart';
import '../models/map_issue.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home/add_report_sheet.dart';
import '../widgets/home/go_to_sheet.dart';
import '../widgets/home/home_map_view.dart';
import '../widgets/home/issue_details_sheet.dart';
import '../widgets/home/report_form_sheet.dart';
import '../widgets/home/success_dialog.dart';
import '../models/path_node.dart';
import '../services/routing_service.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedNavIndex = 0;
  final Set<String> votedIssueIds = {};
  late List<MapIssue> mapIssues;

  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();
  final AuthService _authService = AuthService();
  LatLng? _currentLocation;

  List<PathNode> pathNodes = [];
  List<LatLng> pathPoints = [];
  bool _isLoadingPlaces = false;

  @override
  void initState() {
    super.initState();
    mapIssues = List<MapIssue>.from(initialIssues);
    _loadLocation();
  }

  void _logout(BuildContext context) async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _loadLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();

    setState(() {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
    });

    _mapController.move(_currentLocation!, 16);
  }

  void _recenterMap() {
    if (_currentLocation == null) return;
    _mapController.move(_currentLocation!, 16);
  }

  void _addReportToMap(String label, String emoji, String description) {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location not available yet. Allow access to your location',
          ),
        ),
      );
      return;
    }

    setState(() {
      mapIssues.add(
        MapIssue(
          id: 'report_${DateTime.now().millisecondsSinceEpoch}',
          emoji: emoji,
          title: '$label Report',
          sub: 'Reported just now',
          desc: description,
          color: const Color(0xFF3A7D1E),
          position: _currentLocation!,
        ),
      );
    });

    _mapController.move(_currentLocation!, 16);
  }

  void _showIssueSheet(MapIssue issue) {
    showIssueDetailsSheet(
      context: context,
      issue: issue,
      alreadyVoted: votedIssueIds.contains(issue.id),
      onVoteStillThere: () {
        setState(() {
          votedIssueIds.add(issue.id);
        });
      },
      onVoteFixed: () {
        setState(() {
          votedIssueIds.add(issue.id);
        });
      },
    );
  }

  void _showAddReportSheet() {
    showAddReportSheet(
      context: context,
      onCategorySelected: (label, emoji) {
        _showReportForm(label, emoji);
      },
    );
  }

  void _showReportForm(String label, String emoji) {
    showReportFormSheet(
      context: context,
      label: label,
      emoji: emoji,
      onSubmit: (description) {
        _addReportToMap(label, emoji, description);

        showSuccessDialog(
          context: context,
          title: 'Report Submitted!',
          message:
          'Your $label report has been pinned on the map at your current location.',
        );
      },
    );
  }

  void _showGoToSheet() {
    showGoToSheet(
      context: context,
      onCategorySelected: (label, emoji) async {
        if (_currentLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current location not available. Allow location access.'),
            ),
          );
          return;
        }

        setState(() => _isLoadingPlaces = true);

        final placesResult = await _routingService.getNearbyPlaces(
          _currentLocation!.latitude,
          _currentLocation!.longitude,
          label,
        );

        setState(() => _isLoadingPlaces = false);

        if (!mounted) return;

        if (placesResult['success'] != true ||
            (placesResult['data'] as List?)?.isEmpty != false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  placesResult['message'] as String? ?? 'No $label found nearby.'),
            ),
          );
          return;
        }

        final placesList = placesResult['data'] as List<dynamic>;
        final nearestRaw = placesList.first as Map<String, dynamic>;
        final placeInfo = nearestRaw['place'] as Map<String, dynamic>;
        final center = placeInfo['center'] as Map<String, dynamic>;
        final placeLat = (center['lat'] as num).toDouble();
        final placeLon = (center['lon'] as num).toDouble();
        final placeName = placeInfo['name'] as String? ?? label;

        final distanceMeters = const Distance()(
          _currentLocation!,
          LatLng(placeLat, placeLon),
        );
        final distanceStr = distanceMeters < 1000
            ? '${distanceMeters.round()} m away'
            : '${(distanceMeters / 1000).toStringAsFixed(1)} km away';

        if (!mounted) return;

        showNearestPlaceSheet(
          context: context,
          label: label,
          emoji: emoji,
          onBack: _showGoToSheet,
          placeData: {
            'name': placeName,
            'distance': distanceStr,
            'address': '',
          },
          onNavigate: () async {
            if (_currentLocation == null) return;

            final routeResult = await _routingService.getRoute(
              _currentLocation!.latitude,
              _currentLocation!.longitude,
              placeLat,
              placeLon,
            );

            if (routeResult['success'] == true) {
              final routeData = routeResult['data'] as Map<String, dynamic>;
              final rawNodes = routeData['pathNodes'] as List<dynamic>;
              final nodes = rawNodes
                  .map((n) => PathNode.fromJson(n as Map<String, dynamic>))
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));
              setState(() {
                pathNodes = nodes;
                pathPoints =
                    nodes.map((n) => LatLng(n.latitude, n.longitude)).toList();
              });
              _mapController.move(_currentLocation!, 15);
            }

            if (mounted) {
              showSuccessDialog(
                context: context,
                title: 'Navigation Started',
                message:
                    'Routing to the nearest $label. Follow the directions on the map.',
              );
            }
          },
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    if (selectedNavIndex == 3) {
      return const ProfileScreen();
    }

    return HomeMapView(
      mapController: _mapController,
      mapIssues: mapIssues,
      currentLocation: _currentLocation,
      onLogout: () => _logout(context),
      onRecenter: _recenterMap,
      onShowAddReport: _showAddReportSheet,
      onShowGoTo: _showGoToSheet,
      onTapIssue: _showIssueSheet,
      pathPoints: pathPoints,
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
                Expanded(
                  child: _buildCurrentScreen(),
                ),
                HomeBottomNavBar(
                  selectedIndex: selectedNavIndex,
                  onTap: (index) {
                    setState(() {
                      selectedNavIndex = index;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        if (_isLoadingPlaces)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x55000000),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }
}