# Story System Implementation Plan

## Objectives
- Surface active restaurant stories on the consumer home page below the header across mobile, web, and theme variations.
- Allow restaurants to create, publish, and remove ephemeral stories (image or video) from the restaurant app; stories expire automatically after 24 hours.
- Track view state so consumers see unread/read rings and restaurants can monitor reach.
- Keep parity with existing clean architecture (GetX controllers + repository/service layers and cached API usage).

## Backend (API & Data)
### Data Model Additions
1. `stories` table: `id`, `restaurant_id`, `title` (nullable), `status` (`draft/published/expired`), `created_at`, `publish_at`, `expire_at` (computed = `publish_at + 24h`), `last_modified_at`.
2. `story_media` table: `id`, `story_id`, `sequence`, `media_type` (`image/video`), `file_path`(CDN URL), `thumbnail_path`, `duration_seconds` (default 5 for images), `caption` (nullable), `cta_link` (nullable), `language_code` (optional for localization), `metadata` (json for future use).
3. `story_audience` table (optional but recommended): `id`, `story_id`, `customer_id`, `viewed_at` for tracking unique views and suppressing unread rings.
4. DB indexes: `(restaurant_id, publish_at desc)` for feed queries; `(story_id, sequence)` for ordered media; TTL/expired sweep job on `expire_at`.

### Services & Jobs
- Media processing pipeline (re-use existing upload service) to generate webp thumbnails and transcode videos (<=15s) to adaptive MP4; enforce max file size/duration.
- Scheduled job (cron/queue worker) every 30 minutes to mark `status=expired` for records whose `expire_at` has passed and purge from CDN if needed.
- Optional analytics job to aggregate views per story for vendor dashboard.

### API Endpoints
- **Consumer**
  - `GET /api/v1/stories/active?zone_id=<id>&limit=<n>` → list of restaurants with active stories, each containing ordered media items and lightweight restaurant summary (id, name, logo).
  - `POST /api/v1/stories/{storyId}/view` → mark as viewed (idempotent); records into `story_audience` and increments counter.
- **Vendor/Restaurant**
  - `GET /api/v1/vendor/stories` → paginated list with status filters.
  - `POST /api/v1/vendor/stories` → create draft story shell (title optional) returning story id.
  - `POST /api/v1/vendor/stories/{storyId}/media` → multipart upload for images/videos (sequence ordering in payload) with server side media validation.
  - `PATCH /api/v1/vendor/stories/{storyId}` → publish (sets `publish_at=now`) or schedule, update title/cta.
  - `DELETE /api/v1/vendor/stories/{storyId}` → remove story (soft delete) and purge media.
  - Optional: `GET /api/v1/vendor/stories/{storyId}/metrics` → aggregated views, completion rate.

### Auth & Permissions
- Re-use vendor JWT scopes; ensure consumer endpoint is public but zone-aware.
- Enforce max concurrent published stories per restaurant (configurable, default 5).

### Configuration
- Add environment toggles: `stories_enabled`, `story_max_media_per_story`, `story_default_duration`.
- Extend admin panel (if exists) to manage global limits.

## Consumer App (GoDelivery User)
### Data Layer
1. Add `StoryModel`, `StoryFeedModel`, `StoryMediaModel` under `lib/features/story/domain/models/`.
2. Create repository `StoryRepository` implementing `RepositoryInterface` to wrap `ApiClient.getData`/`postData` calls to new endpoints (`AppConstants.storyFeedUri`, `AppConstants.storyViewUri`). Support LocalClient caching similar to banners (store last response for offline fallback, TTL 5 minutes).
3. Service layer `StoryService` handling transformations (e.g., grouping by restaurant, filtering expired, computing seen state using shared prefs) and side-effects like recording `view` after completing a media chunk.
4. Controller `StoryController` (GetX) exposing:
   - `RxList<StoryCollection>` for feed.
   - `Map<int,bool>` for seen state persisted via `SharedPreferences` key `story_seen_{restaurantId}` (sync with backend `story_audience`).
   - Methods `fetchStories({bool reload})`, `markMediaSeen(...)`, `preloadNext()`.

### Dependency Injection
- Register repository/service/controller in `lib/helper/get_di.dart` (lazyPut) and wire into `HomeScreen`/`Theme1HomeScreen`/`WebHomeScreen` initial loaders.
- Extend `AppConstants` with new URIs and shared-pref keys.

### UI Integration
1. **Story Strip Widget**
   - Create `StoryStripWidget` under `lib/features/story/widgets/` showing horizontal `ListView` of circular avatars below the search/location section.
   - Provide shimmer placeholder and fallback if no stories.
   - Integrate into `HomeScreen` after location row, `Theme1HomeScreen` near top, and `WebHomeScreen` (ensure responsive layout with 6 items per row on desktop).
   - Use `CachedNetworkImage` for logos; overlay gradient ring (brand colors) indicating unseen state; grey ring for seen.

2. **Story Viewer**
   - New screen `StoryViewerScreen` (route via `RouteHelper.getStoryViewerRoute(restaurantId, initialIndex)`).
   - UI features: full-screen `PageView` for restaurants (horizontal swipe), nested `PageView`/`Stack` for media (tap right/left to advance/rewind, vertical swipe down to dismiss).
   - Progress bars at top per media item; animate using `AnimationController` tied to media duration; pause on long press or when video is buffering.
   - Use existing `video_player` + `chewie` for videos, ensure caching and prefetch (call `StoryService.preloadNext`).
   - Display optional caption and CTA button linking to product/restaurant page; use `RouteHelper` navigation.

3. **State Handling**
   - On viewer dismiss, call `StoryController.persistSeenState()` and trigger backend `view` event (avoid sending duplicates via throttling).
   - Support offline fallback: if feed loaded from cache, allow viewing but queue `view` events until connectivity (persist queue in `SharedPreferences`).

### Analytics & A/B
- Fire Firebase Analytics events (`story_open`, `story_media_complete`, `story_swipe_next`) for product insights.
- Guard feature with remote config flag to allow staged rollout.

### Testing
- Unit tests for `StoryService` transformations & seen persistence.
- Widget tests covering `StoryStripWidget` empty/loaded states and navigation.
- Integration test stub to simulate full playback using `WidgetTester` (ensure skip on web if needed).

## Restaurant App (Vendor)
*(Assuming separate Flutter module mirroring GetX architecture)*

### Data & Services
1. Mirror models (`VendorStoryModel`, `VendorStoryMediaModel`) and repository hitting vendor endpoints with multipart upload via existing `ApiClient.postMultipartData` pattern (reference `lib/features/auth/domain/reposotories/restaurant_registration_repo.dart`).
2. Implement `VendorStoryService` for sequencing, validation (max media count, enforce durations), and local draft persistence (temporary storage in `GetStorage`/`SharedPreferences`).
3. Controller `VendorStoryController` handling story list, draft builder state, upload progress (use Rx for UI binding).

### Story Management UI
1. Add entry point in restaurant dashboard (e.g., `Marketing` tab → `Stories`).
2. Screens:
   - `StoryListScreen`: shows active, scheduled, expired stories with metrics (views, completes). Provide delete & republish actions.
   - `StoryComposerScreen`: allow selecting media from gallery or recording (image_picker / camera); show timeline chips for reordering (drag & drop); allow per-media caption/CTA.
   - `StoryPreviewScreen`: reuse story viewer widget for preview before publishing.
3. Include publish scheduling (immediate vs schedule). Validate at least one media before enabling publish button.
4. Show upload progress with cancellation; handle retries with exponential backoff.

### Media Handling
- Use existing `image_picker`/`video_player` to capture/preview.
- Compress images (`image_picker` provides path; optionally integrate `image` compression if needed) and clip videos to max length (trim UI or reject). Generate thumbnail client-side for preview (use `get_thumbnail_video`).

### Story Lifecycle Controls
- Allow manual expiration (DELETE) and unpublish if inside 24h window.
- Expose analytics: total views, unique viewers, taps forward/back, exits; start with `views` + `completions` from backend aggregates.

### Testing & QA
- Unit tests for controller validators (max media, scheduling).
- Widget tests for composer (media tile add/remove).
- Manual QA checklist covering upload failure, slow network, offline drafts, expiry accuracy.

## Rollout & Coordination
- Behind feature flag (`stories_enabled`); ensure consumer app gracefully hides UI when disabled.
- Backfill initial data (optional: allow admin to seed stories for testing).
- Coordinate backend deployment first, then vendor app update, then consumer release.
- Update documentation/help center for restaurants explaining story guidelines (ratio 9:16, max 15s, etc.).
- Monitor logs & analytics; add on-call alerts for media upload failures.

## Open Questions / Follow-up
- Do we need localized stories per language/zone? Backend design allows `language_code` per media.
- How aggressively should expired media be purged from CDN? Align with storage cost policies.
- Should consumers be able to mute restaurants? Could extend `story_audience` preferences later.
