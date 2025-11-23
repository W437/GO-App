import 'package:get/get.dart';
import 'package:godelivery_user/features/app_data/enums/loading_state.dart';
import 'package:godelivery_user/features/app_data/services/app_data_loader_service.dart';

/// Central controller for managing all app-wide data loading
/// Provides a single point of control for initial load, refresh, and state tracking
class AppDataController extends GetxController implements GetxService {
  final AppDataLoaderService _dataLoaderService = AppDataLoaderService();

  LoadingState _loadingState = LoadingState.idle;
  LoadingState get loadingState => _loadingState;

  double _loadingProgress = 0.0;
  double get loadingProgress => _loadingProgress;

  String _loadingMessage = '';
  String get loadingMessage => _loadingMessage;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isComplete => _loadingState == LoadingState.success;

  /// Load all initial app data (called during splash)
  Future<bool> loadInitialData() async {
    _loadingState = LoadingState.loading;
    _loadingProgress = 0.0;
    _loadingMessage = '';
    _errorMessage = '';
    update();

    final success = await _dataLoaderService.loadInitialData(
      onProgress: (progress, message) {
        _loadingProgress = progress;
        _loadingMessage = message;
        update();
      },
      onError: (error) {
        _errorMessage = error;
        _loadingState = LoadingState.error;
        update();
      },
    );

    if (success) {
      _loadingState = LoadingState.success;
      _loadingProgress = 100.0;
      _loadingMessage = 'Ready!';
    } else {
      _loadingState = LoadingState.error;
      if (_errorMessage.isEmpty) {
        _errorMessage = 'Failed to load application data';
      }
    }

    update();
    return success;
  }

  /// Refresh all data (for pull-to-refresh)
  Future<void> refreshAllData() async {
    await _dataLoaderService.refreshAllData();
  }

  /// Reset loading state (for retry)
  void resetLoadingState() {
    _loadingState = LoadingState.idle;
    _loadingProgress = 0.0;
    _loadingMessage = '';
    _errorMessage = '';
    _dataLoaderService.reset();
    update();
  }
}
