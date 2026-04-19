import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/domain/repository/home_repository.dart';

class GetHomeDashboardUseCase {
  const GetHomeDashboardUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeDashboard> call() => _repository.getDashboard();
}

class SelectMapLocationUseCase {
  const SelectMapLocationUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeDashboard> call(LocationPoint location) {
    return _repository.selectMapLocation(location);
  }
}

class RecenterMapUseCase {
  const RecenterMapUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeDashboard> call() => _repository.recenterMap();
}

class SubmitReportUseCase {
  const SubmitReportUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeDashboard> call(SubmitReportParams params) {
    return _repository.submitReport(params);
  }
}

class UpdateReportStatusUseCase {
  const UpdateReportStatusUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeDashboard> call({
    required String reportId,
    required ReportStatus status,
  }) {
    return _repository.updateReportStatus(reportId: reportId, status: status);
  }
}
