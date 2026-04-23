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
import '../data/path_dummy_data.dart';
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
  LatLng? _currentLocation;

  List<PathNode> pathNodes = [];
  List<LatLng> pathPoints = [];

  @override
  void initState() {
    super.initState();
    mapIssues = List<MapIssue>.from(initialIssues);
    _loadLocation();
  }

  void _loadPathNodes(String category) {
    final filteredNodes = dummyPathNodes
        .where((node) => node.category == category)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (filteredNodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No path nodes found for $category')),
      );
      return;
    }

    setState(() {
      pathNodes = filteredNodes;
      pathPoints = filteredNodes
          .map((node) => LatLng(node.latitude, node.longitude))
          .toList();
    });
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
      onCategorySelected: (label, emoji) {
        _loadPathNodes(label);

        showNearestPlaceSheet(
          context: context,
          label: label,
          emoji: emoji,
          onBack: _showGoToSheet,
          onNavigate: () {
            showSuccessDialog(
              context: context,
              title: 'Navigation Started',
              message:
              'Routing to the nearest $label. Follow the directions on the map.',
            );
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
    return Scaffold(
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
    );
  }
}