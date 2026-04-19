import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';

extension HomeLocationUiX on LocationPoint {
  LatLng toLatLng() => LatLng(latitude, longitude);
}

extension HomeRoadRiskUiX on RoadRiskLevel {
  Color get color => switch (this) {
    RoadRiskLevel.low => const Color(0xFF16A34A),
    RoadRiskLevel.medium => const Color(0xFFF59E0B),
    RoadRiskLevel.high => const Color(0xFFDC2626),
  };
}

extension HomeIssueTypeUiX on IssueType {
  IconData get icon => switch (this) {
    IssueType.accident => Icons.warning_rounded,
    IssueType.pothole => Icons.construction_rounded,
    IssueType.traffic => Icons.traffic_rounded,
  };

  Color get color => switch (this) {
    IssueType.accident => const Color(0xFFDC2626),
    IssueType.pothole => const Color(0xFFF59E0B),
    IssueType.traffic => const Color(0xFF2563EB),
  };
}

extension HomeReportStatusUiX on ReportStatus {
  Color get color => switch (this) {
    ReportStatus.pending => const Color(0xFFF59E0B),
    ReportStatus.approved => const Color(0xFF16A34A),
    ReportStatus.rejected => const Color(0xFFDC2626),
  };
}
