# Garmin through Apple Health

## Canonical verification status (2026-09-16)
VERIFIED requires actual Garmin-originated records from a physical device; none inspected. LIKELY means documented sharing generally, not guaranteed Forerunner 165 compatibility. UNVERIFIED means no sufficient export evidence. NOT AVAILABLE refers to this app's current HealthKit path, not every future Garmin API.

| Desired metric | Classification | Evidence / scope |
|---|---|---|
| Steps | LIKELY | General sharing expectation; device verification required |
| Workouts | LIKELY | General sharing expectation; recorded duration only in app |
| Active energy | UNVERIFIED | App reads it; actual Garmin export not inspected |
| Heart rate | LIKELY | Garmin official guide describes all-day HR and timed high/low; app does not request general HR |
| Resting heart rate | UNVERIFIED | General HR sharing is not proof of restingHeartRate export |
| HRV SDNN | UNVERIFIED | Garmin overnight HRV must not be assumed equivalent/exported |
| Sleep duration | LIKELY | Official sharing guide lists Sleep Analysis |
| Sleep stages | UNVERIFIED | Sleep Analysis does not establish stage completeness |
| Respiratory data | UNVERIFIED | Not requested/read by this app |
| VO2 max | UNVERIFIED | Not requested/read by this app |
| Body Battery | NOT AVAILABLE | No imported proprietary field/current HealthKit mapping |
| Training readiness | NOT AVAILABLE | No imported proprietary field/current HealthKit mapping |
| Stress | NOT AVAILABLE | No Garmin proprietary stress mapping in current path |
| Recovery time | NOT AVAILABLE | No imported proprietary field/current HealthKit mapping |

The official Garmin support search excerpts were rechecked on 2026-09-16; complete page access remains limited, so no device-export guarantee is claimed. Future proprietary data requires a separately approved direct Garmin API/backend integration and verified field support. Debug diagnostics and exact device instructions are in [HealthKit audit](healthkit-audit.md).

Expected flow: Forerunner 165 → Garmin Connect → Apple Health → Good Morning. No Bluetooth watch pairing, direct Garmin login, partner API, or Garmin connection verification exists in this app.

Good Morning requests read-only sleep, steps, active energy, workouts, resting heart rate, and HRV SDNN permissions, on demand. Availability depends on Health records, individual permissions, Connect version, watch support, and sync completion. Health samples may originate from other devices; this app does not identify the watch as their guaranteed source.

| Metric | App support | Garmin expectation |
|---|---|---|
| Steps | Health daily cumulative sum | Likely; Garmin support search confirms sharing depends on settings/device |
| Sleep | Union of recorded asleep intervals, overnight noon-to-noon attribution | Likely; duration/stage completeness must be verified with the user's watch |
| Workouts | Recorded durations for workouts starting on that date | Likely; no inferred intensity or proprietary training load |
| Active energy | Health daily cumulative sum | Uncertain for this watch/Connect configuration until inspected in Health |
| Resting heart rate | Health discrete daily average | Uncertain; do not substitute all-day heart rate |
| HRV SDNN | Health discrete daily average in ms | Uncertain; Garmin overnight HRV is not guaranteed to be exported or equivalent to SDNN |
| Sleep/recovery scores, Body Battery, training readiness | Not imported | Proprietary Garmin fields; no equivalent guaranteed HealthKit export |
| Routes, detailed pace streams, continuous activity HR | Not implemented | Must not promise; Garmin support indicates timed-activity heart rate export has limitations |

Garmin's official [sharing guide](https://support.garmin.com/en-NZ/?faq=lK5FPB9iPF5PXFkIpFlFPA&productID=125677) search excerpt was checked 2026-09-16; fetching its complete content returned HTTP 403. Therefore this table intentionally marks unsupported evidence as uncertain, not verified compatibility. Validate each metric in Health > Data Access & Devices after a real Forerunner sync.

Apple [protects read authorization privacy](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data): an empty query may mean permission denial or no samples. Do not label a successfully dismissed permission sheet as connected. The app handles this as no readable data, keeps missing metrics nil, and offers retry.

Sleep intervals are clipped/unioned to avoid duplicate overlapping stages/sources. A fixed noon-to-noon sleep window may split unusual daytime sleep; it is not an exhaustive sleep classifier. Workout duration is not physiological training load. No samples means unavailable, not zero workouts. Health cumulative statistics manage available-source aggregation; real multi-device behaviour needs device verification.

Future direct Garmin data needs approved [Garmin developer program](https://developer.garmin.com/gc-developer-program/health-api/) access, backend credential protection, user consent, revocation/deletion, source deduplication, licensing review, and independent verification of supported fields. No credentials belong in the app bundle.
