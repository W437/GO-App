import 'package:get/get.dart';
import 'package:godelivery_user/common/enums/data_source_enum.dart';
import 'package:godelivery_user/features/story/domain/models/story_collection_model.dart';
import 'package:godelivery_user/features/story/domain/services/story_service_interface.dart';

class StoryController extends GetxController implements GetxService {
  final StoryServiceInterface storyServiceInterface;

  StoryController({required this.storyServiceInterface});

  List<StoryCollectionModel>? _storyList;
  List<StoryCollectionModel>? get storyList => _storyList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int? _currentStoryIndex;
  int? get currentStoryIndex => _currentStoryIndex;

  int? _currentMediaIndex;
  int? get currentMediaIndex => _currentMediaIndex;

  // Throttle mechanism for view events
  final Map<int, DateTime> _lastViewEventTime = {};
  static const Duration _viewEventThrottle = Duration(seconds: 2);

  Future<void> getStories({bool reload = false}) async {
    print('📖 [STORIES] getStories called - reload: $reload, isLoading: $_isLoading');

    if (_isLoading) {
      print('📖 [STORIES] Skipping - already loading');
      return;
    }

    _isLoading = true;
    update();

    try {
      print('📖 [STORIES] Fetching from ${reload ? 'SERVER' : 'LOCAL CACHE'}');

      List<StoryCollectionModel>? stories =
          await storyServiceInterface.getStoryList(
        source: reload ? DataSourceEnum.client : DataSourceEnum.local,
      );

      print('📖 [STORIES] Initial fetch result: ${stories?.length ?? 'null'} stories');

      if ((stories == null || stories.isEmpty) && !reload) {
        // Try fetching from server if local cache is empty or null
        print('📖 [STORIES] Cache empty/null, fetching from server...');
        stories = await storyServiceInterface.getStoryList(
          source: DataSourceEnum.client,
        );
        print('📖 [STORIES] Server fetch result: ${stories?.length ?? 'null'} stories');
      }

      _storyList = stories;
      print('📖 [STORIES] ✅ Stories loaded successfully: ${_storyList?.length ?? 0} collections');
    } catch (e) {
      print('📖 [STORIES] ❌ Error fetching stories: $e');
      print('📖 [STORIES] Stack trace: ${StackTrace.current}');
      _storyList = [];
    } finally {
      _isLoading = false;
      update();
    }
  }

  void setCurrentIndices(int storyIndex, int mediaIndex) {
    _currentStoryIndex = storyIndex;
    _currentMediaIndex = mediaIndex;
    update();
  }

  Future<void> markStoryViewed(int storyId, bool completed) async {
    // Throttle view events
    if (_lastViewEventTime.containsKey(storyId)) {
      final timeSinceLastEvent =
          DateTime.now().difference(_lastViewEventTime[storyId]!);
      if (timeSinceLastEvent < _viewEventThrottle) {
        return; // Skip if called too soon
      }
    }

    _lastViewEventTime[storyId] = DateTime.now();

    try {
      await storyServiceInterface.markStoryViewed(storyId, completed);
    } catch (e) {
      print('Error marking story viewed: $e');
    }
  }

  void markRestaurantStorySeen(int restaurantId) {
    storyServiceInterface.markRestaurantStorySeen(restaurantId);

    // Update hasUnseen flag in the story list
    if (_storyList != null) {
      final collection = _storyList!.firstWhereOrNull(
        (c) => c.restaurant?.id == restaurantId,
      );
      if (collection != null) {
        collection.hasUnseen = false;
      }
    }
    update();
  }

  bool isRestaurantStorySeen(int restaurantId) {
    return storyServiceInterface.isRestaurantStorySeen(restaurantId);
  }

  void clearSeenState() {
    storyServiceInterface.clearSeenState();
    // Reset hasUnseen flags
    if (_storyList != null) {
      for (var collection in _storyList!) {
        collection.hasUnseen = true;
      }
    }
    update();
  }

  bool get hasStories => _storyList != null && _storyList!.isNotEmpty;
}