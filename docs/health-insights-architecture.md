# Good Morning Health Insights Architecture

## Critical Review

Good Morning should not become a wall of wearable charts. The strongest version of the product turns Apple Health and Garmin-synced data into a few calm, specific observations: how well the user slept, how recovered they appear, what changed from their normal baseline, and what to do next.

Main risks:
- Data quality: different watches expose different metrics, and Garmin data reaches the app through Garmin Connect and Apple Health unless a future Garmin partner API is approved.
- Missing data: sleep stages, HRV, respiratory rate, temperature, stress, and route detail are not guaranteed.
- Safety: unusual biometrics can support wellness guidance, but they do not diagnose illness.
- Privacy: raw health samples, derived scores, and AI explanations must be stored and permissioned separately.
- Explainability: every score should have visible drivers and avoid hidden black-box logic.

Recommended changes:
- Treat Apple Health as the MVP ingestion path, including Garmin Connect data shared into Apple Health.
- Add direct Garmin API support only after partner approval, OAuth review, backend token storage, and a clear commercial/legal path.
- Make every insight confidence-aware. Stronger language requires enough history and multiple signals.
- Keep friend leaderboard points separate from raw health metrics.

## Assumptions

- MVP is iOS-first with HealthKit as the local source of truth.
- Garmin Forerunner 165 users sync their watch to Garmin Connect, then Garmin Connect shares supported data to Apple Health.
- A backend will be needed before real cross-device sync, AI coaching, or direct Garmin OAuth.
- Current app implementation can start with deterministic local scoring and sample data.

## Architecture

Pipeline:

1. Provider adapters import samples from Apple Health or Garmin.
2. Adapters output normalized health metrics.
3. Aggregation builds one daily health summary per active day.
4. Baseline service computes 7-day and 30-day personal baselines.
5. Scoring service calculates sleep, recovery, and activity signals.
6. Anomaly detector flags multi-signal deviations only when confidence is high enough.
7. AI layer receives structured summaries, never thousands of raw samples.
8. UI shows concise insight cards and lets the user inspect drivers.

Adapter contract:
- `AppleHealthAdapter`: reads HealthKit samples with explicit per-type permission.
- `GarminAdapter`: MVP bridge status and source attribution for Garmin Connect data in Apple Health.
- Future direct Garmin adapter: OAuth-backed server integration that normalizes Garmin Health API payloads.

## Scoring Methodology

Sleep score, 0-100:
- 35% duration vs personal 30-day baseline or target range.
- 20% sleep consistency, based on bedtime/wake-time deviation.
- 15% efficiency, when available.
- 10% interruptions or awake minutes, when available.
- 10% sleep debt across recent nights.
- 10% sleep stages only when reliable and available.

Recovery score, 0-100:
- 30% HRV vs personal baseline.
- 20% resting heart rate vs baseline.
- 20% sleep score.
- 10% respiratory rate vs baseline, when available.
- 10% temperature deviation, when available.
- 10% recent workout load or activity load.

Anomaly detection:
- Never warn from a single metric alone.
- Compare today against personal baseline and variability.
- Prefer multi-day or multi-signal patterns.
- Trigger gentle warnings when at least two recovery signals are meaningfully outside the user's normal range.
- Use language like "unusual pattern" or "poor recovery signal"; never "you are sick."

## Database Schema

`users`
- `id`, `display_name`, `created_at`, `deleted_at`

`health_connections`
- `id`, `user_id`, `provider`, `status`, `connected_at`, `last_sync_at`, `permissions_json`, `source_device`

`health_metric_samples`
- `id`, `user_id`, `provider`, `source_device`, `metric_type`, `value`, `unit`, `start_at`, `end_at`, `recorded_at`, `external_id_hash`

`daily_health_summaries`
- `id`, `user_id`, `date`, `timezone`, `sleep_minutes`, `sleep_efficiency`, `bedtime_minutes`, `wake_minutes`, `resting_hr`, `hrv`, `respiratory_rate`, `temperature_deviation`, `steps`, `active_energy`, `workout_load`, `data_quality`

`personal_baselines`
- `id`, `user_id`, `metric_type`, `window_days`, `mean`, `lower_bound`, `upper_bound`, `variability`, `sample_count`, `updated_at`

`health_insights`
- `id`, `user_id`, `date`, `type`, `severity`, `title`, `explanation`, `recommendation`, `supporting_metrics_json`, `confidence`, `created_at`

`ai_health_messages`
- `id`, `user_id`, `conversation_id`, `role`, `structured_context_hash`, `content`, `created_at`

## API Endpoints

`GET /health/connections`
- Returns provider status, last sync, permissions, and source devices.

`POST /health/connections/apple-health/sync`
- Accepts normalized summaries or sample batches produced locally from HealthKit.

`POST /health/connections/garmin/oauth/start`
- Future direct Garmin OAuth start.

`POST /health/connections/garmin/oauth/callback`
- Future direct Garmin token exchange. Tokens must be encrypted server-side.

`DELETE /health/connections/{provider}`
- Disconnects provider and optionally deletes imported data.

`GET /health/today`
- Returns today's daily summary, scores, insights, and missing-data notices.

`GET /health/trends?range=7d|30d|90d`
- Returns trend cards and baseline comparisons.

`POST /health/coach/messages`
- Sends a question plus structured health context to the AI coach.

## UI Components

- Today insight summary: sleep score, recovery score, activity status, one recommendation.
- Sleep screen: last night, consistency, debt, trend, and coach prompts.
- Recovery screen: HRV, resting HR, respiratory signals, drivers, and suggested training intensity.
- Trends screen: 7/30/90-day segmented views.
- Health Coach: conversational Q&A grounded in structured summaries.
- Connections screen: Apple Health, Garmin, permissions, last sync, disconnect, delete data.

## Phased Plan

MVP 1:
- HealthKit permission flow and Garmin-via-Apple-Health setup.
- Normalized local health models.
- Daily sleep and recovery summaries.
- Deterministic sleep score and basic coaching cards.
- 7-day and 30-day trend-ready baselines.

MVP 2:
- Real HealthKit reads and daily aggregation.
- Recovery score with HRV/resting-HR analysis.
- Better data-quality labels and missing-metric messaging.

MVP 3:
- Multi-signal anomaly detection over multiple days.
- Push notifications for calm recovery warnings.
- Delete/export imported health data.

MVP 4:
- Conversational health coach.
- Direct Garmin partner API integration if approved.
- Long-term personalization and richer recommendations.
