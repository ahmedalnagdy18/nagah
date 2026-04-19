import 'package:nagah/features/home/domain/model/home_models.dart';

class LocationPointModel {
  const LocationPointModel({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  LocationPoint toEntity() {
    return LocationPoint(latitude: latitude, longitude: longitude);
  }

  factory LocationPointModel.fromEntity(LocationPoint point) {
    return LocationPointModel(
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }
}

class RoadSegmentModel {
  const RoadSegmentModel({
    required this.id,
    required this.name,
    required this.points,
    required this.riskLevel,
    required this.totalApprovedReports,
  });

  final String id;
  final String name;
  final List<LocationPointModel> points;
  final RoadRiskLevel riskLevel;
  final int totalApprovedReports;

  RoadSegment toEntity() {
    return RoadSegment(
      id: id,
      name: name,
      points: points.map((point) => point.toEntity()).toList(),
      riskLevel: riskLevel,
      totalApprovedReports: totalApprovedReports,
    );
  }

  RoadSegmentModel copyWith({
    String? id,
    String? name,
    List<LocationPointModel>? points,
    RoadRiskLevel? riskLevel,
    int? totalApprovedReports,
  }) {
    return RoadSegmentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      riskLevel: riskLevel ?? this.riskLevel,
      totalApprovedReports: totalApprovedReports ?? this.totalApprovedReports,
    );
  }
}

class RoadIssueReportModel {
  const RoadIssueReportModel({
    required this.id,
    required this.roadId,
    required this.issueType,
    required this.description,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.submittedBy,
    this.imageLabel,
    this.adminNote,
  });

  final String id;
  final String roadId;
  final IssueType issueType;
  final String description;
  final LocationPointModel location;
  final ReportStatus status;
  final DateTime createdAt;
  final String submittedBy;
  final String? imageLabel;
  final String? adminNote;

  RoadIssueReport toEntity() {
    return RoadIssueReport(
      id: id,
      roadId: roadId,
      issueType: issueType,
      description: description,
      location: location.toEntity(),
      status: status,
      createdAt: createdAt,
      submittedBy: submittedBy,
      imageLabel: imageLabel,
      adminNote: adminNote,
    );
  }

  RoadIssueReportModel copyWith({
    String? id,
    String? roadId,
    IssueType? issueType,
    String? description,
    LocationPointModel? location,
    ReportStatus? status,
    DateTime? createdAt,
    String? submittedBy,
    String? imageLabel,
    String? adminNote,
  }) {
    return RoadIssueReportModel(
      id: id ?? this.id,
      roadId: roadId ?? this.roadId,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      submittedBy: submittedBy ?? this.submittedBy,
      imageLabel: imageLabel ?? this.imageLabel,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}

class HomeDashboardModel {
  const HomeDashboardModel({
    required this.currentLocation,
    required this.selectedLocation,
    required this.roads,
    required this.reports,
  });

  final LocationPointModel currentLocation;
  final LocationPointModel? selectedLocation;
  final List<RoadSegmentModel> roads;
  final List<RoadIssueReportModel> reports;

  HomeDashboard toEntity() {
    return HomeDashboard(
      currentLocation: currentLocation.toEntity(),
      selectedLocation: selectedLocation?.toEntity(),
      roads: roads.map((road) => road.toEntity()).toList(),
      reports: reports.map((report) => report.toEntity()).toList(),
    );
  }

  HomeDashboardModel copyWith({
    LocationPointModel? currentLocation,
    LocationPointModel? selectedLocation,
    List<RoadSegmentModel>? roads,
    List<RoadIssueReportModel>? reports,
  }) {
    return HomeDashboardModel(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      roads: roads ?? this.roads,
      reports: reports ?? this.reports,
    );
  }
}
