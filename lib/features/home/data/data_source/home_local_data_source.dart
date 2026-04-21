import 'package:nagah/features/home/data/model/home_models.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';

class HomeLocalDataSource {
  HomeLocalDataSource() {
    _currentLocation = const LocationPointModel(
      latitude: 31.4165,
      longitude: 31.8133,
    );
    _selectedLocation = const LocationPointModel(
      latitude: 31.4172,
      longitude: 31.8151,
    );
    _roads = _buildRoads();
    _reports = _buildReports();
  }

  late LocationPointModel _currentLocation;
  LocationPointModel? _selectedLocation;
  late List<RoadSegmentModel> _roads;
  late List<RoadIssueReportModel> _reports;

  HomeDashboardModel getDashboard() {
    final myReports = _reports
        .where((report) => report.userId == 'current-user')
        .toList();

    return HomeDashboardModel(
      currentLocation: _currentLocation,
      selectedLocation: _selectedLocation,
      roads: List<RoadSegmentModel>.from(_roads),
      reports: List<RoadIssueReportModel>.from(_reports),
      myReports: List<RoadIssueReportModel>.from(myReports),
    );
  }

  HomeDashboardModel selectLocation(LocationPointModel location) {
    _selectedLocation = location;
    return getDashboard();
  }

  HomeDashboardModel recenterMap() {
    _selectedLocation = _currentLocation;
    return getDashboard();
  }

  HomeDashboardModel submitReport({
    String? roadId,
    required IssueType issueType,
    required String description,
    String? imagePath,
  }) {
    final report = RoadIssueReportModel(
      id: 'rep-${_reports.length + 1}',
      userId: 'current-user',
      roadId: roadId ?? '',
      issueType: issueType,
      description: description,
      location: _selectedLocation ?? _currentLocation,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
      submittedBy: 'Current user',
      imageLabel: imagePath,
    );

    _reports = [report, ..._reports];
    return getDashboard();
  }

  HomeDashboardModel updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
  }) {
    final report = _reports.firstWhere((item) => item.id == reportId);

    _reports = _reports
        .map(
          (item) => item.id == reportId
              ? item.copyWith(
                  status: status,
                  adminNote:
                      adminNote ??
                      (status == ReportStatus.approved
                          ? 'Approved by admin review panel.'
                          : 'Rejected by admin review panel.'),
                )
              : item,
        )
        .toList();

    if (status == ReportStatus.approved) {
      _roads = _roads.map((road) {
        if (road.id != report.roadId) {
          return road;
        }

        final nextRisk = switch (report.issueType) {
          IssueType.accident => RoadRiskLevel.high,
          IssueType.traffic => RoadRiskLevel.medium,
          IssueType.pothole =>
            road.riskLevel == RoadRiskLevel.low
                ? RoadRiskLevel.medium
                : road.riskLevel,
        };

        return road.copyWith(
          riskLevel: nextRisk,
          totalApprovedReports: road.totalApprovedReports + 1,
        );
      }).toList();
    }

    return getDashboard();
  }

  List<RoadSegmentModel> _buildRoads() {
    return const [
      RoadSegmentModel(
        id: 'road-1',
        name: 'Corniche Road',
        points: [
          LocationPointModel(latitude: 31.4148, longitude: 31.8058),
          LocationPointModel(latitude: 31.4162, longitude: 31.8104),
          LocationPointModel(latitude: 31.4178, longitude: 31.8149),
          LocationPointModel(latitude: 31.4191, longitude: 31.8192),
        ],
        riskLevel: RoadRiskLevel.low,
        totalApprovedReports: 1,
      ),
      RoadSegmentModel(
        id: 'road-2',
        name: 'Bridge Street',
        points: [
          LocationPointModel(latitude: 31.4131, longitude: 31.8117),
          LocationPointModel(latitude: 31.4153, longitude: 31.8140),
          LocationPointModel(latitude: 31.4180, longitude: 31.8162),
          LocationPointModel(latitude: 31.4204, longitude: 31.8181),
        ],
        riskLevel: RoadRiskLevel.medium,
        totalApprovedReports: 2,
      ),
      RoadSegmentModel(
        id: 'road-3',
        name: 'Port Access Road',
        points: [
          LocationPointModel(latitude: 31.4188, longitude: 31.8065),
          LocationPointModel(latitude: 31.4204, longitude: 31.8103),
          LocationPointModel(latitude: 31.4216, longitude: 31.8154),
          LocationPointModel(latitude: 31.4232, longitude: 31.8198),
        ],
        riskLevel: RoadRiskLevel.high,
        totalApprovedReports: 3,
      ),
    ];
  }

  List<RoadIssueReportModel> _buildReports() {
    return [
      RoadIssueReportModel(
        id: 'rep-1',
        userId: 'mahmoud',
        roadId: 'road-3',
        issueType: IssueType.accident,
        description:
            'Two damaged cars blocking one lane near the port entrance.',
        location: const LocationPointModel(
          latitude: 31.4213,
          longitude: 31.8148,
        ),
        status: ReportStatus.approved,
        createdAt: DateTime(2026, 3, 29, 9, 15),
        submittedBy: 'Mahmoud',
        imageLabel: 'accident_scene.jpg',
        adminNote: 'Approved after patrol confirmation.',
      ),
      RoadIssueReportModel(
        id: 'rep-2',
        userId: 'sara',
        roadId: 'road-2',
        issueType: IssueType.traffic,
        description:
            'Heavy traffic building up before the bridge after school hours.',
        location: const LocationPointModel(
          latitude: 31.4170,
          longitude: 31.8158,
        ),
        status: ReportStatus.pending,
        createdAt: DateTime(2026, 3, 30, 8, 30),
        submittedBy: 'Sara',
        adminNote: 'Waiting for a second confirmation.',
      ),
      RoadIssueReportModel(
        id: 'rep-3',
        userId: 'nada',
        roadId: 'road-1',
        issueType: IssueType.pothole,
        description: 'Large road hole close to the service lane.',
        location: const LocationPointModel(
          latitude: 31.4164,
          longitude: 31.8112,
        ),
        status: ReportStatus.rejected,
        createdAt: DateTime(2026, 3, 28, 18, 45),
        submittedBy: 'Nada',
        adminNote: 'Location did not match the uploaded proof.',
      ),
    ];
  }
}
