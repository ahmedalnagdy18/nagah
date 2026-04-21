import 'dart:async';

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
  Timer? _pollingTimer;

  Future<void> initialize() async {
    await refreshDashboard();
    _startAutoRefresh();
  }

  void changeTab(int index) {
    emit(state.copyWith(currentTab: index, clearMessage: true));

    if (index == 2) {
      unawaited(refreshDashboard(silent: true));
    }
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
    String? roadId,
    required IssueType issueType,
    required String description,
    String? imagePath,
  }) async {
    emit(state.copyWith(status: HomeViewStatus.loading, clearError: true));

    try {
      final dashboard = await _submitReportUseCase(
        SubmitReportParams(
          roadId: roadId,
          issueType: issueType,
          description: description,
          imagePath: imagePath,
        ),
      );
      emit(
        state.copyWith(
          status: HomeViewStatus.success,
          dashboard: dashboard,
          currentTab: 2,
          message: 'Report sent successfully and is pending admin review.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeViewStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> refreshDashboard({bool silent = false}) async {
    if (!silent || state.dashboard == null) {
      emit(state.copyWith(status: HomeViewStatus.loading, clearError: true));
    }

    try {
      final dashboard = await _getHomeDashboardUseCase();
      emit(
        state.copyWith(
          status: HomeViewStatus.success,
          dashboard: dashboard,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeViewStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> updateReportStatus({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
  }) async {
    emit(state.copyWith(status: HomeViewStatus.loading, clearError: true));

    try {
      final dashboard = await _updateReportStatusUseCase(
        reportId: reportId,
        status: status,
        adminNote: adminNote,
      );

      emit(
        state.copyWith(
          status: HomeViewStatus.success,
          dashboard: dashboard,
          message: status == ReportStatus.approved
              ? 'Report approved and the map risk was updated.'
              : 'Report rejected successfully.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeViewStatus.error,
          errorMessage: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  void _startAutoRefresh() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(refreshDashboard(silent: true));
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
