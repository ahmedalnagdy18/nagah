import 'package:equatable/equatable.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';

enum HomeViewStatus { initial, loading, success, error }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeViewStatus.initial,
    this.currentTab = 0,
    this.dashboard,
    this.message,
    this.errorMessage,
  });

  final HomeViewStatus status;
  final int currentTab;
  final HomeDashboard? dashboard;
  final String? message;
  final String? errorMessage;

  HomeState copyWith({
    HomeViewStatus? status,
    int? currentTab,
    HomeDashboard? dashboard,
    String? message,
    String? errorMessage,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      currentTab: currentTab ?? this.currentTab,
      dashboard: dashboard ?? this.dashboard,
      message: clearMessage ? null : (message ?? this.message),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentTab,
    dashboard,
    message,
    errorMessage,
  ];
}
