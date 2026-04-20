class LocationPoint {
  const LocationPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  LocationPoint copyWith({double? latitude, double? longitude}) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

enum RoadRiskLevel { low, medium, high }

enum IssueType { accident, pothole, traffic }

enum ReportStatus { pending, approved, rejected }

extension RoadRiskLevelX on RoadRiskLevel {
  String get label => switch (this) {
    RoadRiskLevel.low => 'Green',
    RoadRiskLevel.medium => 'Orange',
    RoadRiskLevel.high => 'Red',
  };
}

extension IssueTypeX on IssueType {
  String get label => switch (this) {
    IssueType.accident => 'Accident',
    IssueType.pothole => 'Road hole',
    IssueType.traffic => 'Traffic',
  };
}

extension ReportStatusX on ReportStatus {
  String get label => switch (this) {
    ReportStatus.pending => 'Pending review',
    ReportStatus.approved => 'Approved',
    ReportStatus.rejected => 'Rejected',
  };
}

class RoadSegment {
  const RoadSegment({
    required this.id,
    required this.name,
    required this.points,
    required this.riskLevel,
    required this.totalApprovedReports,
  });

  final String id;
  final String name;
  final List<LocationPoint> points;
  final RoadRiskLevel riskLevel;
  final int totalApprovedReports;

  RoadSegment copyWith({
    String? id,
    String? name,
    List<LocationPoint>? points,
    RoadRiskLevel? riskLevel,
    int? totalApprovedReports,
  }) {
    return RoadSegment(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      riskLevel: riskLevel ?? this.riskLevel,
      totalApprovedReports: totalApprovedReports ?? this.totalApprovedReports,
    );
  }
}

class RoadIssueReport {
  const RoadIssueReport({
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
  final LocationPoint location;
  final ReportStatus status;
  final DateTime createdAt;
  final String submittedBy;
  final String? imageLabel;
  final String? adminNote;

  RoadIssueReport copyWith({
    String? id,
    String? roadId,
    IssueType? issueType,
    String? description,
    LocationPoint? location,
    ReportStatus? status,
    DateTime? createdAt,
    String? submittedBy,
    String? imageLabel,
    String? adminNote,
  }) {
    return RoadIssueReport(
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

class HomeDashboard {
  const HomeDashboard({
    required this.currentLocation,
    required this.selectedLocation,
    required this.roads,
    required this.reports,
  });

  final LocationPoint currentLocation;
  final LocationPoint? selectedLocation;
  final List<RoadSegment> roads;
  final List<RoadIssueReport> reports;

  List<RoadIssueReport> get approvedReports => reports
      .where((report) => report.status == ReportStatus.approved)
      .toList();

  HomeDashboard copyWith({
    LocationPoint? currentLocation,
    LocationPoint? selectedLocation,
    List<RoadSegment>? roads,
    List<RoadIssueReport>? reports,
  }) {
    return HomeDashboard(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      roads: roads ?? this.roads,
      reports: reports ?? this.reports,
    );
  }
}

class SubmitReportParams {
  const SubmitReportParams({
    this.roadId,
    required this.issueType,
    required this.description,
    this.imagePath,
  });

  final String? roadId;
  final IssueType issueType;
  final String description;
  final String? imagePath;
}
