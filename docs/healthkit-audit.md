# HealthKit audit
Updated 2026-09-16. Code support is not physical-device verification.

All six types request read permission only, on demand from Profile. No writes, network transfer, or persisted Health records. HealthKit entitlement and NSHealthShareUsageDescription are configured. Deployment supports the iOS 16 sleep categories.

| Metric / identifier | Query / aggregation | Unit | Missing behaviour | Scores / display |
|---|---|---|---|---|
| Sleep / sleepAnalysis | HKSampleQuery; previous noon through date noon, clipped at now; asleep union minus awake union | minutes | nil; partial/mixed windows provisional | No grade; eligible duration comparison; Today/ Sleep details |
| Steps / stepCount | HKStatisticsQuery cumulativeSum; local midnight to next midnight or now; strict start | count | nil, never inferred zero | No score; Today/Activity |
| Active energy / activeEnergyBurned | Same daily statistics cumulativeSum | kcal | nil | No score; Activity |
| Resting HR / restingHeartRate | Same daily statistics discreteAverage | bpm | nil | No score; Recovery |
| HRV / heartRateVariabilitySDNN | Same daily statistics discreteAverage | milliseconds SDNN | nil | No score; Recovery |
| Workouts / HKWorkoutType | HKSampleQuery; workouts starting within local day; sum recorded duration | minutes | nil if no readable workouts | No training-load score; Activity |

Each query catches its own errors; one metric cannot discard the others. Latest-day metric status is distinct from recent-sample diagnostic status. HealthKit protects read privacy: empty results cannot distinguish denied permission from genuinely absent data. The UI explicitly combines these cases instead of claiming definitive denial. Recorded zero remains a valid available quantity.

The service retrieves 15 local dates. Midnight defines goal history; sleep is attributed separately noon-to-noon. Unusual daytime sleep may be split. Workout duration includes the entire workout starting that day, not clipped physiological load. The legacy `workoutLoad` field now means recorded minutes only. Quantity totals use HealthKit statistics, not diagnostic sample sums; mixed-device source prioritization still needs device checks.

## Conservative interpretation
Sleep/recovery score required inputs, calculation, range: none; disabled and always nil. No arbitrary health grades or training-readiness inference. Sleep duration uses any usable asleep interval; unspecified asleep is valid, in-bed/unknown are not. Partial, clipped, mixed-source windows remain visible but do not drive comparisons. A complete window is an interval-coverage heuristic, not proof that a device recorded a full night.

Sleep comparison requires complete, finite, positive latest sleep and at least five complete, finite, positive prior dates. Optional inputs: none. Calculation: latest duration minus arithmetic mean of up to 30 prior dates (currently at most 14 fetched), output signed minutes. Insufficient data produces nil. Activity displays available totals without a grade/goal assumption. Recommendations are neutral reflection text, not clinical advice.

## Source inspection
Debug Profile > Health diagnostics shows availability/request state, latest-day statuses, latest usable records and source revision/device/start/end metadata. Reads at most the latest 100 samples per metric in 15 days; source lists are bounded inspection, not exhaustive contribution accounting. Sleep sample duration is individual stage duration, not the nightly union total. Missing device metadata is not inferred. Exact Garmin bundle and Apple device heuristics are classification aids, not proof of a Forerunner 165 origin. No sensitive console logs or exports; diagnostics exist in memory and compile out under Release.

## Exact physical-device sequence
1. Open DIL.xcodeproj in Xcode; select DIL target, Signing & Capabilities, your Apple Developer team, and verify HealthKit capability/provisioning. Connect/unlock/trust iPhone, enable Developer Mode, choose it as run destination. Use Debug, then Run.
2. On a fresh app install, open Profile and request Health. Test all/none/partial access separately; change grants in Settings/Health data access afterward, then retry. Permission-sheet completion is not proof of readable permission.
3. Open Profile > Health diagnostics. Compare each today's total and latest record with Apple Health, including date, source name/bundle and device metadata. Do not share raw health screenshots publicly. No samples and query errors must not become zero.
4. Install/sign in to Garmin Connect, pair Forerunner 165 there, enable its Apple Health sharing, and complete watch sync. Inspect Health's individual records/data sources first, then retry Good Morning. Verify Garmin source metadata rather than assuming any visible data is Garmin.
5. Repeat with Apple/iPhone sources and mixed sources. Record overnight sleep, compare union duration and awake exclusions, check before/after noon, kill/relaunch, after midnight, revoked access, device lock, and airplane mode. Keep manual goals/logs usable.
6. Repeat user-facing flows with Release on device; diagnostics must not exist. Record pass/fail privately in the release checklist, without committing measurements. No physical checks have been completed here.
