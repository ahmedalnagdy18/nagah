import 'package:nagah/features/home/data/data_source/home_remote_data_source.dart';
import 'package:nagah/features/home/data/model/home_models.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/domain/repository/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<HomeDashboard> getDashboard() async {
    final model = await _remoteDataSource.getDashboard();
    return model.toEntity();
  }

  @override
  Future<HomeDashboard> selectMapLocation(LocationPoint location) async {
    final model = await _remoteDataSource.selectLocation(
      LocationPointModel.fromEntity(location),
    );
    return model.toEntity();
  }

  @override
  Future<HomeDashboard> recenterMap() async {
    final model = await _remoteDataSource.recenterMap();
    return model.toEntity();
  }

  @override
  Future<HomeDashboard> submitReport(SubmitReportParams params) async {
    final model = await _remoteDataSource.submitReport(
      roadId: params.roadId,
      issueType: params.issueType,
      description: params.description,
      imagePath: params.imagePath,
    );
    return model.toEntity();
  }

  @override
  Future<HomeDashboard> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
  }) async {
    final model = await _remoteDataSource.updateReportStatus(
      reportId: reportId,
      status: status,
      adminNote: adminNote,
    );
    return model.toEntity();
  }
}
