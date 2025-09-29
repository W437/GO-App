# Backend Story System Plan (Laravel + MySQL)

## Goals
- Support Instagram-style restaurant stories with 24-hour lifetime.
- Provide consumer-facing API feed plus vendor CRUD via admin/vendor panels.
- Track views and completion metrics without localization or mute functionality.

## Architecture Overview
- Follow existing Laravel modular structure (Controllers → Services → Repositories → Models).
- Use MySQL with Eloquent models, queue workers for media processing & expiration, and storage disks (S3/local) for media.
- Reuse current authentication guards: public consumer API (token optional), vendor API (JWT/Passport), admin panel guard for moderation.

## Database Schema
Create new migration batch with the following tables and indexes:

1. `stories`
   - `id` (PK, ULID/UUID recommended), `restaurant_id` (FK → restaurants.id, indexed), `title` (nullable, 120 chars), `status` enum (`draft`, `scheduled`, `published`, `expired`, `deleted`), `publish_at` (nullable), `expire_at` (nullable), `created_at`, `updated_at`, `deleted_at` (soft delete).
   - Constraints: `CHECK (expire_at IS NULL OR expire_at > publish_at)`. Default `expire_at` filled via DB trigger or model observer to `publish_at + INTERVAL 24 HOUR`.
   - Indexes: `index_stories_restaurant_status` on (`restaurant_id`,`status`,`publish_at` desc); `index_stories_expire_at` on (`expire_at`).

2. `story_media`
   - `id` (PK ULID), `story_id` (FK → stories.id, cascade delete), `sequence` (unsigned tinyint), `media_type` enum (`image`, `video`), `media_path`, `thumbnail_path` (nullable for images), `duration_seconds` (default 5), `caption` (nullable, 240 chars), `cta_label` (nullable), `cta_url` (nullable), `created_at`, `updated_at`.
   - Unique constraint on (`story_id`, `sequence`). Index on (`media_type`).

3. `story_views`
   - `id` (PK ULID), `story_id` (FK → stories.id, cascade), `customer_id` (nullable for guest views), `session_key` (nullable string for guests), `viewed_at`, `completed` (boolean default false).
   - Unique composite index on (`story_id`, `customer_id`, `session_key`) to prevent duplicates.
   - Additional index on (`story_id`, `viewed_at`).

4. Optional metrics table (if summarized nightly): `story_metrics` storing aggregated counts per story per day.

MySQL housekeeping:
- Add event or scheduled job to hard-delete stories + media older than configurable retention (e.g. 7 days) to keep storage lean.
- Update `restaurants` seeder/factory to optionally generate sample stories for QA.

## Eloquent Models & Relationships
- `Story` model:
  - `hasMany(StoryMedia::class)` ordered by `sequence`.
  - `belongsTo(Restaurant::class)`.
  - `hasMany(StoryView::class)`.
  - Scopes: `active()` (status = published AND `publish_at <= now < expire_at`), `ownedBy($restaurantId)`, `forFeed($zoneId)` to filter by restaurant zone if required.
  - Observer to set `expire_at = publish_at + 24h` when publishing.

- `StoryMedia` model: casts `duration_seconds`, accessors for CDN URLs via `Storage::disk()` helpers.

- `StoryView` model: cast `completed` boolean; static method to record view idempotently.

## Services & Business Logic
- `StoryService`
  - `createDraft(array $data)`.
  - `attachMedia(Story $story, array $mediaPayload)` handles validation, storage, and sequencing.
  - `publish(Story $story, Carbon $publishAt = null)` sets status, `publish_at`, `expire_at`.
  - `delete(Story $story)` soft deletes and queues media purge.
  - `recordView(Story $story, ?User $customer, ?string $sessionKey, bool $completed)` ensures idempotence and increments counters.

- `StoryFeedService`
  - `fetchActiveStories(Zone $zone = null, int $limit = 20)` returns stories grouped by restaurant, eager loading media.
  - Applies caching (Redis) for 30 seconds to reduce DB load; cache key includes zone id.

- `StoryExpirationService`
  - Cron-friendly service invoked by scheduler to mark expired stories and queue media purge job.

## Media Handling
- Use Laravel `Storage` facade with dedicated disk (e.g., `stories`).
- Implement queued job `ProcessStoryMedia` to:
  - Validate MIME/size (images ≤ 1080x1920, videos ≤ 15s & <20MB).
  - Generate video thumbnails (FFmpeg integration) and re-encode to H.264 MP4 baseline with fallback.
  - Resize/compress images to webp/jpg variants.
  - Update `story_media` rows with final paths/durations.
- Add `PurgeStoryMedia` job to delete storage files when stories expire or are deleted.

## API Endpoints
Follow RESTful conventions with dedicated controllers under `App\Http\Controllers\Api` namespaces.

### Consumer API (Public)
- `GET /api/v1/stories` → `StoryFeedController@index`
  - Query params: `zone_id` (optional), `limit`.
  - Returns JSON: list of restaurants with story metadata, media arrays, boolean `seen` flag (provided separately from backend, though seen-state primarily tracked client-side).
  - Caches response, includes pagination headers if needed.

- `POST /api/v1/stories/{story}/view` → `StoryViewController@store`
  - Requires auth middleware optional; accepts `completed` boolean.
  - Records view via `StoryService::recordView`.
  - Rate-limit by IP to prevent abuse.

### Vendor API
- Guarded by vendor auth middleware (JWT/Passport).

- `GET /api/v1/vendor/stories` → list stories with status filters & metrics.
- `POST /api/v1/vendor/stories` → create draft. Request includes `title`, optional `scheduled_for`.
- `POST /api/v1/vendor/stories/{story}/media` → multipart upload; supports `sequence`, `media_type`, file(s), `caption`, `cta_label`, `cta_url`. Validate max `sequence` count (config `story_max_media` default 10).
- `PATCH /api/v1/vendor/stories/{story}` → publish or update metadata. Validate that story has >=1 processed media before publish.
- `DELETE /api/v1/vendor/stories/{story}` → soft delete.
- `DELETE /api/v1/vendor/stories/{story}/media/{media}` → remove specific media, re-sequence remaining items.

### Admin Panel (Laravel Nova / custom blade)
- Add section under Marketing → Stories.
- CRUD screens: list by status, search by restaurant, manually expire, view metrics. Expose toggle to feature/unfeature stories if future functionality desired.
- Add ability to ban a restaurant from stories (boolean column on `restaurants` table). Controllers enforce check before allowing creation.

## Request Validation & Policies
- Form Request classes per endpoint (e.g., `StoreStoryRequest`, `UploadStoryMediaRequest`). Enforce allowed formats, file size (use `max:`), and CTA URL validation (`url` rule with allowed schemes http/https).
- Authorization via policies:
  - `StoryPolicy@update/delete` ensures vendor owns the story.
  - Admin guard bypass.
- Middleware to ensure restaurants with suspended status cannot publish stories.

## Scheduling & Queues
- Add scheduler entries in `app/Console/Kernel.php`:
  - `StoryExpirationCommand` runs every 10 minutes to mark expired stories and dispatch purge jobs.
  - `StoryMetricsCommand` (optional) runs hourly to aggregate views into `story_metrics` for reporting.
- Ensure queue workers have FFmpeg/processing dependencies installed (document for DevOps).

## Config & Environment
- Add `config/stories.php` with keys:
  - `enabled` (default true).
  - `max_media_per_story` (default 10).
  - `default_duration` (5 seconds for images).
  - `retention_days` (7).
- `.env` additions: `STORY_MEDIA_DISK`, `STORY_MAX_MEDIA`, `STORY_ENABLED`.
- Register config in `config/app.php` providers if needed.

## Testing Strategy
- Feature tests for vendor endpoints (auth, validation, publishing flow).
- Feature tests for consumer feed (ensures only published stories <24h appear, sorted by `publish_at`).
- Job tests for `ProcessStoryMedia` (mock storage & FFmpeg) and `StoryExpirationCommand`.
- Policy tests verifying vendor ownership restrictions.
- Database factory updates to generate story data for tests & seeds.

## Rollout Checklist
1. Merge migrations & deploy DB changes.
2. Ensure FFmpeg binaries available in all environments.
3. Configure scheduler + queue workers.
4. Deploy backend endpoints behind feature flag `stories.enabled`.
5. Update API documentation (OpenAPI/Swagger) with new endpoints & payloads.
6. Provide sample Postman collection for mobile team.
7. Train support/admin teams on new panel tools.

## Non-Goals / Clarifications
- No per-language localization; `caption` saved as plain text.
- Stories auto-expire exactly 24h after `publish_at` with no manual extension (only early deletion).
- No consumer mute/block functionality at this phase (future enhancement slot noted but not implemented).

