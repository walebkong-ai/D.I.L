# Core data checks

Run on a Mac with Xcode's Swift toolchain:

```sh
swiftc DIL/Models/Models.swift DIL/Views/DesignSystem.swift DIL/AppState.swift DIL/Services/DailyActivityStore.swift DIL/Services/LeaderboardService.swift DIL/Services/HealthAccessService.swift DIL/Services/HealthInsightsEngine.swift DIL/Services/HealthRecordProcessing.swift Tests/CoreDataChecks.swift Tests/HealthProcessingChecks.swift -o /private/tmp/GoodMorningCoreChecks
/private/tmp/GoodMorningCoreChecks
```

Tests use an isolated UserDefaults suite and remove it when finished. No personal app data is changed. HealthKit permission/query behaviour still requires iPhone testing; the pure engine checks verify missing inputs never become scores.

46 checks include sleep interval unions/awake exclusions, partial availability, source classification and conservative comparison eligibility. No XCTest target exists. Debug device diagnostics are under Profile > Apple Health > Health diagnostics; see docs/healthkit-audit.md for signing and the manual sequence. Physical permission behaviour and Garmin provenance are not covered by these synthetic checks.
