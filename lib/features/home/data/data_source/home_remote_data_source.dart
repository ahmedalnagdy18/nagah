import 'package:geolocator/geolocator.dart';
import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/auth/data/data_source/auth_session_local_data_source.dart';
import 'package:nagah/features/auth/data/model/auth_models.dart';
import 'package:nagah/features/home/data/model/home_models.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';

class HomeRemoteDataSource {
  static const String _fallbackRoadPrefix = 'fallback-road-';
  static const LocationPointModel _fallbackLocation = LocationPointModel(
    latitude: 30.0444,
    longitude: 31.2357,
  );

  HomeRemoteDataSource(this._client, this._sessionLocalDataSource)
    : _currentLocation = _fallbackLocation;

  final SupabaseRestClient _client;
  final AuthSessionLocalDataSource _sessionLocalDataSource;
  LocationPointModel _currentLocation;

  LocationPointModel? _selectedLocation;
  List<RoadSegmentModel> _realRoads = const [];
  List<RoadSegmentModel> _roads = const [];
  List<RoadIssueReportModel> _reports = const [];
  List<RoadIssueReportModel> _myReports = const [];

  Future<HomeDashboardModel> getDashboard() async {
    final session = await _sessionLocalDataSource.getSession();
    _currentLocation = await _getCurrentDeviceLocation();
    _selectedLocation ??= _currentLocation;

    final roadRows = await _client.getList(
      'roads',
      query: {'select': '*'},
    );

    final reportRows = await _client.getList(
      'reports',
      query: {'select': '*', 'order': 'created_at.desc'},
    );

    _realRoads = roadRows.map(_mapRoad).toList();
    _roads = List<RoadSegmentModel>.from(_realRoads);
    _reports = reportRows.map(_mapReport).toList();
    _myReports = session == null
        ? const []
        : _reports.where((report) => report.userId == session.id).toList();

    final approvedCounts = <String, int>{};
    for (final report in _reports.where(
      (item) => item.status == ReportStatus.approved,
    )) {
      if (report.roadId.isEmpty) {
        continue;
      }
      approvedCounts.update(
        report.roadId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    _roads = _roads
        .map(
          (road) => road.copyWith(
            totalApprovedReports: approvedCounts[road.id] ?? 0,
            riskLevel: _resolveRoadRiskLevel(
              approvedCounts[road.id] ?? 0,
              fallback: road.riskLevel,
            ),
          ),
        )
        .toList();

    if (_roads.isEmpty && _reports.isNotEmpty) {
      _roads = _buildFallbackRoadsFromReports();
    }

    return _buildDashboard();
  }

  Future<HomeDashboardModel> selectLocation(
    LocationPointModel location,
  ) async {
    _selectedLocation = location;
    return _buildDashboard();
  }

  Future<HomeDashboardModel> recenterMap() async {
    _currentLocation = await _getCurrentDeviceLocation();
    _selectedLocation = _currentLocation;
    return _buildDashboard();
  }

  Future<HomeDashboardModel> submitReport({
    String? roadId,
    required IssueType issueType,
    required String description,
    String? imagePath,
  }) async {
    final session = await _requireSession();
    final targetLocation = _selectedLocation ?? _currentLocation;
    final resolvedRoadId = _resolveValidRoadId(
      requestedRoadId: roadId,
      target: targetLocation,
    );

    await _client.insert(
      'reports',
      body: {
        'user_id': session.id,
        if (resolvedRoadId != null) 'road_id': resolvedRoadId,
        'description': '[${issueType.name}] ${description.trim()}',
        'latitude': targetLocation.latitude,
        'longitude': targetLocation.longitude,
        'status': 'pending',
        if (imagePath != null && imagePath.isNotEmpty) 'image_url': imagePath,
      },
    );

    return getDashboard();
  }

  Future<HomeDashboardModel> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
  }) async {
    await _client.update(
      'reports',
      query: {'id': 'eq.$reportId'},
      body: {'status': status.name},
    );

    return getDashboard();
  }

  HomeDashboardModel _buildDashboard() {
    return HomeDashboardModel(
      currentLocation: _currentLocation,
      selectedLocation: _selectedLocation,
      roads: List<RoadSegmentModel>.from(_roads),
      reports: List<RoadIssueReportModel>.from(_reports),
      myReports: List<RoadIssueReportModel>.from(_myReports),
    );
  }

  RoadSegmentModel _mapRoad(Map<String, dynamic> json) {
    final lat = _toDouble(
      json['location_lat'] ?? json['latitude'] ?? json['lat'],
    );
    final lng = _toDouble(
      json['location_lng'] ?? json['longitude'] ?? json['lng'],
    );

    final center = LocationPointModel(
      latitude: lat,
      longitude: lng,
    );

    return RoadSegmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed road',
      points: _buildSyntheticRoadPoints(center),
      riskLevel: _parseRiskLevel(json['risk_level']),
      totalApprovedReports: 0,
    );
  }

  RoadIssueReportModel _mapReport(Map<String, dynamic> json) {
    final rawDescription = json['description']?.toString() ?? '';

    return RoadIssueReportModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      roadId: json['road_id']?.toString() ?? '',
      issueType: _parseIssueTypeFromDescription(rawDescription),
      description: _cleanDescription(rawDescription),
      location: _resolveReportLocation(json),
      status: _parseReportStatus(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      submittedBy: 'Community user',
      imageLabel: json['image_url']?.toString(),
      adminNote: null,
    );
  }

  LocationPointModel _resolveReportLocation(Map<String, dynamic> json) {
    final lat = _toDouble(
      json['latitude'] ?? json['location_lat'] ?? json['lat'],
    );
    final lng = _toDouble(
      json['longitude'] ?? json['location_lng'] ?? json['lng'],
    );

    if (lat == 0 && lng == 0) {
      final road = _findRoadById(json['road_id']?.toString() ?? '');
      if (road != null && road.points.isNotEmpty) {
        return road.points[road.points.length ~/ 2];
      }
      return _currentLocation;
    }

    return LocationPointModel(latitude: lat, longitude: lng);
  }

  List<LocationPointModel> _buildSyntheticRoadPoints(
    LocationPointModel center,
  ) {
    return [
      LocationPointModel(
        latitude: center.latitude - 0.001,
        longitude: center.longitude - 0.0014,
      ),
      LocationPointModel(
        latitude: center.latitude - 0.00035,
        longitude: center.longitude - 0.00045,
      ),
      LocationPointModel(
        latitude: center.latitude + 0.00035,
        longitude: center.longitude + 0.00045,
      ),
      LocationPointModel(
        latitude: center.latitude + 0.001,
        longitude: center.longitude + 0.0014,
      ),
    ];
  }

  List<RoadSegmentModel> _buildFallbackRoadsFromReports() {
    final grouped = <String, List<RoadIssueReportModel>>{};
    for (final report in _reports) {
      final key = report.roadId.isEmpty ? report.id : report.roadId;
      grouped.putIfAbsent(key, () => []).add(report);
    }

    return grouped.entries.map((entry) {
      final first = entry.value.first;
      final approvedCount = entry.value
          .where((item) => item.status == ReportStatus.approved)
          .length;
      return RoadSegmentModel(
        id: '$_fallbackRoadPrefix${entry.key}',
        name: 'Reported road',
        points: _buildSyntheticRoadPoints(first.location),
        riskLevel: _resolveRoadRiskLevel(
          approvedCount,
          fallback: RoadRiskLevel.low,
        ),
        totalApprovedReports: approvedCount,
      );
    }).toList();
  }

  RoadRiskLevel _resolveRoadRiskLevel(
    int approvedReports, {
    required RoadRiskLevel fallback,
  }) {
    if (approvedReports >= 15) {
      return RoadRiskLevel.high;
    }
    if (approvedReports >= 5) {
      return RoadRiskLevel.medium;
    }

    return fallback;
  }

  RoadRiskLevel _parseRiskLevel(dynamic value) {
    if (value is int) {
      return switch (value) {
        >= 3 => RoadRiskLevel.high,
        2 => RoadRiskLevel.medium,
        _ => RoadRiskLevel.low,
      };
    }

    return switch (value?.toString().toLowerCase()) {
      'high' => RoadRiskLevel.high,
      'medium' => RoadRiskLevel.medium,
      '3' => RoadRiskLevel.high,
      '2' => RoadRiskLevel.medium,
      _ => RoadRiskLevel.low,
    };
  }

  IssueType _parseIssueTypeFromDescription(String value) {
    final lower = value.toLowerCase();

    if (lower.contains('[traffic]') || lower.contains('traffic')) {
      return IssueType.traffic;
    }

    if (lower.contains('[pothole]') ||
        lower.contains('pothole') ||
        lower.contains('hole')) {
      return IssueType.pothole;
    }

    return IssueType.accident;
  }

  String _cleanDescription(String value) {
    return value
        .replaceAll('[accident]', '')
        .replaceAll('[traffic]', '')
        .replaceAll('[pothole]', '')
        .trim();
  }

  ReportStatus _parseReportStatus(String? value) {
    return switch (value?.toLowerCase()) {
      'approved' => ReportStatus.approved,
      'rejected' => ReportStatus.rejected,
      _ => ReportStatus.pending,
    };
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  RoadSegmentModel? _findRoadById(String roadId) {
    for (final road in _roads) {
      if (road.id == roadId) {
        return road;
      }
    }

    return null;
  }

  String? _findNearestRoadId(LocationPointModel target) {
    if (_realRoads.isEmpty) {
      return null;
    }

    RoadSegmentModel? nearestRoad;
    var nearestDistance = double.infinity;

    for (final road in _realRoads) {
      final center = road.points[road.points.length ~/ 2];
      final distance =
          (center.latitude - target.latitude).abs() +
          (center.longitude - target.longitude).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestRoad = road;
      }
    }

    return nearestRoad?.id;
  }

  String? _resolveValidRoadId({
    required String? requestedRoadId,
    required LocationPointModel target,
  }) {
    if (requestedRoadId != null &&
        requestedRoadId.isNotEmpty &&
        !requestedRoadId.startsWith(_fallbackRoadPrefix) &&
        _realRoads.any((road) => road.id == requestedRoadId)) {
      return requestedRoadId;
    }

    return _findNearestRoadId(target);
  }

  Future<AuthUserModel> _requireSession() async {
    final session = await _sessionLocalDataSource.getSession();
    if (session == null || session.id.isEmpty) {
      throw Exception('Please login first to continue.');
    }
    return session;
  }

  Future<LocationPointModel> _getCurrentDeviceLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _currentLocation;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _currentLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LocationPointModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return _currentLocation;
    }
  }
}
