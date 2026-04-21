import 'package:nagah/features/home/domain/model/home_models.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
  Future<HomeDashboard> selectMapLocation(LocationPoint location);
  Future<HomeDashboard> recenterMap();
  Future<HomeDashboard> submitReport(SubmitReportParams params);
  Future<HomeDashboard> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
  });
}
