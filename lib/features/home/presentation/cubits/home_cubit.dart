import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/domain/usecase/home_usecases.dart';
import 'package:nagah/features/home/presentation/cubits/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetHomeDashboardUseCase getHomeDashboardUseCase,
    required SelectMapLocationUseCase selectMapLocationUseCase,
    required RecenterMapUseCase recenterMapUseCase,
    required SubmitReportUseCase submitReportUseCase,
    required UpdateReportStatusUseCase updateReportStatusUseCase,
  }) : _getHomeDashboardUseCase = getHomeDashboardUseCase,
       _selectMapLocationUseCase = selectMapLocationUseCase,
       _recenterMapUseCase = recenterMapUseCase,
       _submitReportUseCase = submitReportUseCase,
       _updateReportStatusUseCase = updateReportStatusUseCase,
       super(const HomeState());

  final GetHomeDashboardUseCase _getHomeDashboardUseCase;
  final SelectMapLocationUseCase _selectMapLocationUseCase;
  final RecenterMapUseCase _recenterMapUseCase;
  final SubmitReportUseCase _submitReportUseCase;
  final UpdateReportStatusUseCase _updateReportStatusUseCase;

  Future<void> initialize() async {
    emit(state.copyWith(status: HomeViewStatus.loading, clearError: true));

    try {
      final dashboard = await _getHomeDashboardUseCase();
      emit(
        state.copyWith(
          status: HomeViewStatus.success,
          dashboard: dashboard,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: HomeViewStatus.error,
          errorMessage: 'Failed to load home data.',
        ),
      );
    }
  }

  void changeTab(int index) {
    emit(state.copyWith(currentTab: index, clearMessage: true));
  }

  void openReportComposer() {
    emit(state.copyWith(currentTab: 1, clearMessage: true));
  }

  Future<void> selectMapLocation(LocationPoint location) async {
    final dashboard = await _selectMapLocationUseCase(location);
    emit(state.copyWith(dashboard: dashboard, clearMessage: true));
  }

  Future<void> recenterMap() async {
    final dashboard = await _recenterMapUseCase();
    emit(state.copyWith(dashboard: dashboard, clearMessage: true));
  }

  Future<void> submitReport({
    required String roadId,
    required IssueType issueType,
    required String description,
    required bool hasImage,
  }) async {
    final dashboard = await _submitReportUseCase(
      SubmitReportParams(
        roadId: roadId,
        issueType: issueType,
        description: description,
        hasImage: hasImage,
      ),
    );

    emit(
      state.copyWith(
        dashboard: dashboard,
        currentTab: 2,
        message:
            'Report saved as pending. It is ready for API submission later.',
      ),
    );
  }

  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
  }) async {
    final dashboard = await _updateReportStatusUseCase(
      reportId: reportId,
      status: status,
    );

    emit(
      state.copyWith(
        dashboard: dashboard,
        message: status == ReportStatus.approved
            ? 'Report approved and the map risk was updated.'
            : 'Report rejected successfully.',
      ),
    );
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
