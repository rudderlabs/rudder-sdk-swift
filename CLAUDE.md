# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build, test, lint

This is a Swift Package (`Package.swift`) — there is no `Podfile`, `Brewfile`, or makefile.

```bash
# Build the library + tests
swift build --build-tests

# Run the full test suite — MUST use --no-parallel (tests race on shared async state).
swift test --skip-build --no-parallel

# Run a single test or test class (XCTest filter syntax)
swift test --no-parallel --filter RudderStackAnalyticsTests.EventQueueTests
swift test --no-parallel --filter RudderStackAnalyticsTests.EventQueueTests/test_put_writesEvent

# Lint (matches the CI swiftlint-check job)
swiftlint lint

# Cross-platform build check (CI runs this for iOS/tvOS/watchOS; macOS is covered by `swift test`)
xcodebuild build -scheme RudderStackAnalytics -destination 'generic/platform=iOS'  | xcpretty
xcodebuild build -scheme RudderStackAnalytics -destination 'generic/platform=tvOS' | xcpretty
xcodebuild build -scheme RudderStackAnalytics -destination 'generic/platform=watchOS' | xcpretty
```

For interactive development, open `RudderStackAnalytics.xcworkspace` — it bundles the SDK with the primary sample app at `Examples/Main/SwiftUIExample/`. The standalone `.xcodeproj` is for the library alone. Sample apps under `Examples/Others/` use the SDK via a local SPM reference, so SDK edits show up immediately on rebuild.

`sh scripts/setup-hooks.sh` (also triggered by Xcode on first build) installs three hooks from `scripts/git-hooks/`: `commit-msg` (Conventional Commits), `pre-commit`, and `pre-push` (the latter runs `swift build --build-tests && swift test --skip-build --no-parallel`). The pre-push hook only fires from a terminal — GUI clients skip it because macOS Gatekeeper blocks SPM from parsing `Package.swift` non-interactively — and CI enforces the same build+test.

**Platform minimums** (`Package.swift`): iOS 15, macOS 12, tvOS 15, watchOS 8. Don't use newer-OS-only APIs without an `@available` / `if #available` guard, or the cross-platform `xcodebuild` jobs in CI will fail.

## Architecture

Event pipeline (everything pivots around this):

```
public API (track/screen/identify/group/alias)
        │
        ▼
Analytics.processEventChannel (AsyncChannel<Event>)
        │
        ▼
PluginChain.process(event)
   ├── preProcess plugins  (context enrichment: DeviceInfo, OSInfo, AppInfo, Locale, TimeZone, Screen, Library, Network, Lifecycle, SessionTracking)
   ├── onProcess plugins   (transforms / IntegrationsManagementPlugin → device-mode destinations)
   └── terminal plugins    (RudderStackDataPlanePlugin → EventQueue)
                                       │
                                       ▼
                          EventQueue (writeChannel ─► EventWriter ─► Storage ─► uploadChannel ─► EventUploader ─► HttpNetwork)
```

Key invariants:

- **One `AsyncChannel<Event>` from public API to plugin chain**, then a second `writeChannel`/`uploadChannel` pair inside `EventQueue`. Writer and uploader are decoupled — writer batches into storage and signals the uploader by sending a batch reference over `uploadChannel`. Don't bypass this; in particular, don't call the data-plane network code directly from a plugin.
- **`Analytics.setup()` order matters.** `LifecycleObserver` must be created before `SessionHandler` (session handler subscribes to lifecycle events). `pluginChain` is created before any default plugins are added. The default plugin add-order in `Analytics.setup()` is the actual execution order within each `PluginType` bucket — preserve it when adding new built-in plugins.
- **Plugin types** (`PluginType` enum, `Plugins/Core/Plugin.swift`): `preProcess`, `onProcess`, `terminal`, `utility`. The chain processes in that order; `utility` plugins only run when invoked manually. Custom plugins implement `Plugin` (generic) or `EventPlugin` (typed `identify/track/screen/group/alias` callbacks). Integrations are a distinct subtype — `IntegrationPlugin` instances are routed to `IntegrationsController`, not the main `PluginChain`.
- **State is Combine-based.** `StateImpl<T>` wraps a `CurrentValueSubject` and is mutated only via `dispatch(action:)` with a `StateAction` reducer. The two reducers are `UserIdentity` (user/anonymous IDs, traits) and `SourceConfig` (server-side source config). Anything that needs to react to config changes should subscribe to `analytics.sourceConfigState.state` (see `EventQueue.observeConfigAndUpdateSchedule`).
- **Storage is a protocol composition.** `Storage = KeyValueStorage + EventStorage`. `BasicStorage` is the default; it switches between `DiskStore` and `MemoryStore` based on `StorageMode`. Key-value persistence (anonymousId, userId, traits) and batched event persistence go through the same `Storage` instance.
- **Logger is per-instance.** `Analytics.logger` is built from `configuration.logger` + `configuration.logLevel` and wrapped in `AnalyticsLogger`, which enforces the level before delegating. The static `LoggerAnalytics` API is deprecated and being actively migrated off (see recent `migrate call sites to instance-based logger` / `migrate sample apps to per-instance logger` commits) — new code must use `analytics.logger` (or the `logger` computed property on the `Plugin` extension). Don't reintroduce static logging or revert call sites already moved off it.
- **Flush behavior is policy-driven.** `FlushPolicy` implementations (`CountFlushPolicy`, `FrequencyFlushPolicy`, `StartupFlushPolicy`) are passed via `Configuration.flushPolicies` and queried by `EventWriter`. Network retry uses `ExponentialBackoffPolicy` via `BackoffPolicyHandler`.
- **Public ObjC surface lives in `Sources/RudderStackAnalytics/ObjC/`.** Swift types exposed to ObjC are prefixed `RSS` via `@objc(RSS…)`. When changing a public type that's ObjC-bridged (`Configuration`, `Analytics`, event types, `RudderOption`, `SessionConfiguration`, etc.), update the matching `ObjC*.swift` wrapper. Run `/objc-bridge-sync` (`.claude/skills/objc-bridge-sync/`) before push to flag wrapper drift — it diffs the branch against `origin/develop` and reports any public Swift members missing on their `RSS…` wrapper.

## Conventions enforced by CI / hooks

- **Branch names**: `<type>/<description>` where type is one of `feat|fix|hotfix|refactor|release|docs|chore|test|ci`. `main` and `develop` are also valid. Enforced by `pre-push` and the `pr-title-check` workflow.
- **Commit messages**: Conventional Commits (`type(optional-scope): description`, types `feat|fix|refactor|perf|style|test|docs|chore|build|ci|revert`). Merge commits are allowed as-is. Enforced by `commit-msg`.
- **SwiftLint** runs on `Sources/RudderStackAnalytics/**` only (Tests and Examples are excluded). Notable opt-in rules: `force_unwrapping`, `missing_docs` (all `public` API must have doc comments), `no_magic_numbers`, `explicit_init`, `function_default_parameter_at_end`. Type body cap 600 lines, function body cap 125 lines.
- **Public APIs require doc comments** (`missing_docs` is opt-in). All existing public types use markdown-style `/** … */` comments — match that style.

## Testing notes

- Test plans live in `Tests/RudderStackAnalyticsTests/TestPlans/` (excluded from the SPM target via `Package.swift`'s `exclude:`). Mocks/fixtures are under `MockResources/`.
- Tests rely on async coordination through `AsyncChannel` and Combine; running in parallel is racy, hence the mandatory `--no-parallel`.
