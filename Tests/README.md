# Core data checks

Run on a Mac with Xcode's Swift toolchain:

```sh
swiftc DIL/Models/Models.swift DIL/Views/DesignSystem.swift DIL/AppState.swift DIL/Services/DailyActivityStore.swift DIL/Services/LeaderboardService.swift DIL/Services/HealthAccessService.swift DIL/Services/HealthInsightsEngine.swift Tests/CoreDataChecks.swift -o /private/tmp/GoodMorningCoreChecks
/private/tmp/GoodMorningCoreChecks
```

Tests use an isolated UserDefaults suite and remove it when finished. No personal app data is changed. HealthKit permission/query behaviour still requires iPhone testing; the pure engine checks verify missing inputs never become scores.
