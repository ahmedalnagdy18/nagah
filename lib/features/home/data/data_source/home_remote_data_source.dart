import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/home/data/model/home_models.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._client)
    : _currentLocation = const LocationPointModel(
        latitude: 31.4165,
        longitude: 31.8133,
      ),
      _selectedLocation = const LocationPointModel(
        latitude: 31.4172,
        longitude: 31.8151,
      );

  final SupabaseRestClient _client;
  final LocationPointModel _currentLocation;
  LocationPointModel? _selectedLocation;
  List<RoadSegmentModel> _roads = const [];
  List<RoadIssueReportModel> _reports = const [];

  Future<HomeDashboardModel> getDashboard() async {
    final roadRows = await _client.getList('roads', query: {'select': '*'});
    final reportRows = await _client.getList('reports', query: {'select': '*'});

    _reports = reportRows.map(_mapReport).toList();
    _roads = roadRows.map(_mapRoad).toList();

    final approvedCounts = <String, int>{};
    for (final report in _reports.where(
      (item) => item.status == ReportStatus.approved,
    )) {
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
          ),
        )
        .toList();

    return _buildDashboard();
  }

  Future<HomeDashboardModel> selectLocation(LocationPointModel location) async {
    _selectedLocation = location;
    return _buildDashboard();
  }

  Future<HomeDashboardModel> recenterMap() async {
    _selectedLocation = _currentLocation;
    return _buildDashboard();
  }

  Future<HomeDashboardModel> submitReport({
    required String roadId,
    required IssueType issueType,
    required String description,
    required bool hasImage,
  }) async {
    final point = _selectedLocation ?? _currentLocation;

    await _client.insert(
      'reports',
      body: {
        'road_id': roadId,
        'issue_type': issueType.name,
        'description': description,
        'status': 'pending',
        'image_url': hasImage ? 'pending_upload_preview.jpg' : null,
        'admin_note': null,
        'location_lat': point.latitude,
        'location_lng': point.longitude,
        'submitted_by': 'Current user',
      },
    );

    return getDashboard();
  }

  Future<HomeDashboardModel> updateReportStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    final cachedReport = _findReportById(reportId);
    final report =
        cachedReport ??
        (await _client.getList(
          'reports',
          query: {'select': '*', 'id': 'eq.$reportId'},
        )).map(_mapReport).first;

    await _client.update(
      'reports',
      query: {'id': 'eq.$reportId'},
      body: {
        'status': status.name,
        'admin_note': status == ReportStatus.approved
            ? 'Approved by admin review panel.'
            : 'Rejected by admin review panel.',
      },
    );

    if (status == ReportStatus.approved) {
      final road = _findRoadById(report.roadId);
      final nextRiskLevel = _mapRiskLevelToApi(
        _resolveNextRiskLevel(
          issueType: report.issueType,
          current: road?.riskLevel ?? RoadRiskLevel.low,
        ),
      );

      await _client.update(
        'roads',
        query: {'id': 'eq.${report.roadId}'},
        body: {'risk_level': nextRiskLevel},
      );
    }

    return getDashboard();
  }

  HomeDashboardModel _buildDashboard() {
    return HomeDashboardModel(
      currentLocation: _currentLocation,
      selectedLocation: _selectedLocation,
      roads: List<RoadSegmentModel>.from(_roads),
      reports: List<RoadIssueReportModel>.from(_reports),
    );
  }

  RoadSegmentModel _mapRoad(Map<String, dynamic> json) {
    final lat = _toDouble(
      json['location_lat'] ?? json['latitude'] ?? json['lat'],
    );
    final lng = _toDouble(
      json['location_lng'] ?? json['longitude'] ?? json['lng'],
    );
    final center = LocationPointModel(latitude: lat, longitude: lng);

    return RoadSegmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed road',
      points: _buildSyntheticRoadPoints(center),
      riskLevel: _parseRiskLevel(json['risk_level']),
      totalApprovedReports: 0,
    );
  }

  RoadIssueReportModel _mapReport(Map<String, dynamic> json) {
    return RoadIssueReportModel(
      id: json['id']?.toString() ?? '',
      roadId: json['road_id']?.toString() ?? '',
      issueType: _parseIssueType(json['issue_type']?.toString()),
      description: json['description']?.toString() ?? '',
      location: LocationPointModel(
        latitude: _toDouble(
          json['location_lat'] ?? json['latitude'] ?? json['lat'],
        ),
        longitude: _toDouble(
          json['location_lng'] ?? json['longitude'] ?? json['lng'],
        ),
      ),
      status: _parseReportStatus(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      submittedBy:
          json['submitted_by']?.toString() ??
          json['full_name']?.toString() ??
          'Unknown user',
      imageLabel: json['image_url']?.toString(),
      adminNote: json['admin_note']?.toString(),
    );
  }

  List<LocationPointModel> _buildSyntheticRoadPoints(
    LocationPointModel center,
  ) {
    return [
      LocationPointModel(
        latitude: center.latitude - 0.0012,
        longitude: center.longitude - 0.0018,
      ),
      LocationPointModel(
        latitude: center.latitude - 0.0004,
        longitude: center.longitude - 0.0006,
      ),
      LocationPointModel(
        latitude: center.latitude + 0.0004,
        longitude: center.longitude + 0.0006,
      ),
      LocationPointModel(
        latitude: center.latitude + 0.0012,
        longitude: center.longitude + 0.0018,
      ),
    ];
  }

  RoadRiskLevel _resolveNextRiskLevel({
    required IssueType issueType,
    required RoadRiskLevel current,
  }) {
    return switch (issueType) {
      IssueType.accident => RoadRiskLevel.high,
      IssueType.traffic => RoadRiskLevel.medium,
      IssueType.pothole =>
        current == RoadRiskLevel.low ? RoadRiskLevel.medium : current,
    };
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

  int _mapRiskLevelToApi(RoadRiskLevel value) {
    return switch (value) {
      RoadRiskLevel.low => 1,
      RoadRiskLevel.medium => 2,
      RoadRiskLevel.high => 3,
    };
  }

  IssueType _parseIssueType(String? value) {
    return switch (value?.toLowerCase()) {
      'pothole' => IssueType.pothole,
      'traffic' => IssueType.traffic,
      _ => IssueType.accident,
    };
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

  RoadIssueReportModel? _findReportById(String reportId) {
    for (final report in _reports) {
      if (report.id == reportId) {
        return report;
      }
    }

    return null;
  }

  RoadSegmentModel? _findRoadById(String roadId) {
    for (final road in _roads) {
      if (road.id == roadId) {
        return road;
      }
    }

    return null;
  }
}
