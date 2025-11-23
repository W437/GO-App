/// Represents the state of data loading operations
enum LoadingState {
  idle,       // Not loading
  loading,    // Currently loading
  success,    // Load completed successfully
  error,      // Load failed
}
