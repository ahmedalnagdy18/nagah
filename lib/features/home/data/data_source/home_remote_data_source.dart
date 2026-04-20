import 'package:nagah/core/network/supabase_rest_client.dart';
import 'package:nagah/features/home/data/model/home_models.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';

class HomeRemoteDataSource {
  HomeRemoteDataSource(this._client)
    : _currentLocation = const LocationPointModel(
        latitude: 31.4165,
        longitude: 31.8133,
      );

  final SupabaseRestClient _client;
  final LocationPointModel _currentLocation;

  LocationPointModel? _selectedLocation;
  List<RoadSegmentModel> _roads = const [];
  List<RoadIssueReportModel> _reports = const [];

  Future<HomeDashboardModel> getDashboard() async {
    final roadRows = await _client.getList(
      'roads',
      query: {'select': '*'},
    );

    final reportRows = await _client.getList(
      'reports',
      query: {'select': '*'},
    );

    _roads = roadRows.map(_mapRoad).toList();
    _reports = reportRows.map(_mapReport).toList();

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

  Future<HomeDashboardModel> selectLocation(
    LocationPointModel location,
  ) async {
    _selectedLocation = location;
    return _buildDashboard();
  }

  Future<HomeDashboardModel> recenterMap() async {
    _selectedLocation = _currentLocation;
    return _buildDashboard();
  }

  Future<HomeDashboardModel> submitReport({
    String? roadId,
    required IssueType issueType,
    required String description,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{
      'description': '[${issueType.name}] $description',
      'status': 'pending',
    };

    if (roadId != null && roadId.isNotEmpty) {
      body['road_id'] = roadId;
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      body['image_url'] = imagePath;
    }

    try {
      await _client.insert(
        'reports',
        body: body,
      );
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }

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
          query: {
            'select': '*',
            'id': 'eq.$reportId',
          },
        )).map(_mapReport).first;

    try {
      await _client.update(
        'reports',
        query: {'id': 'eq.$reportId'},
        body: {
          'status': status.name,
        },
      );
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }

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
        body: {
          'risk_level': nextRiskLevel,
        },
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
    final description = json['description']?.toString() ?? '';

    return RoadIssueReportModel(
      id: json['id']?.toString() ?? '',
      roadId: json['road_id']?.toString() ?? '',
      issueType: _parseIssueTypeFromDescription(description),
      description: _cleanDescription(description),
      location: _selectedLocation ?? _currentLocation,
      status: _parseReportStatus(
        json['status']?.toString(),
      ),
      createdAt:
          DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      submittedBy: 'Unknown user',
      imageLabel: json['image_url']?.toString(),
      adminNote: null,
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

  IssueType _parseIssueTypeFromDescription(String value) {
    final lower = value.toLowerCase();

    if (lower.contains('[traffic]')) {
      return IssueType.traffic;
    }

    if (lower.contains('[pothole]')) {
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
