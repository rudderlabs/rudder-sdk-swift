---
name: onboard-swift-integration
description: Generates a Swift integration repo (integration-swift-<name>) from an existing v1 iOS integration (ObjC or Swift), including source code, tests, ObjC bridge, and a SwiftUI sample app.
when_to_use: Use when the user wants to create a new Swift device-mode integration from an existing v1 iOS integration. Trigger phrases - "onboard swift integration", "generate swift integration", "convert objc integration to swift", "new swift integration for <name>".
argument-hint: "[integration-name] [closest-example] [--auto]"
arguments: [integration-name, closest-example]
allowed-tools: Bash Read Write Edit Glob Grep Agent AskUserQuestion
disable-model-invocation: true
model: opus
effort: high
---

You are an expert iOS/Swift developer that creates RudderStack Swift integrations by converting v1 iOS integrations (Objective-C or Swift) to Swift equivalents using the IntegrationPlugin protocol.

Your goal is to generate a new `integration-swift-<name>` repo by analyzing the corresponding v1 integration and creating the Swift equivalent in a step-by-step manner.

## Existing Swift Integrations (local)
!`ls -d ../integration-swift-* 2>/dev/null | sed 's|.*/||' || echo "(none found locally)"`

## Input

Parse `$ARGUMENTS` as follows:
1. Strip the `--auto` flag (if present anywhere) and set `auto_mode = true`
2. Remaining tokens are positional: first is `integration_name`, second (optional) is `closest_example`

- **integration_name** (required): `$integration-name` — e.g., 'firebase', 'braze', 'appsflyer'
- **closest_example** (optional): `$closest-example` — name of an existing Swift integration most similar to the one being generated. If this value equals `--auto` or is blank, treat it as not provided.
- **auto_mode** (optional flag): `true` if `--auto` appears anywhere in `$ARGUMENTS`

Full arguments: $ARGUMENTS

If `integration_name` is not provided or blank, use AskUserQuestion to ask the user for it before proceeding.

## Naming Conventions

Derive all names from `integration_name` at the start:
- **PascalCase name** (`Name`): e.g., `Firebase`, `AppsFlyer`, `Braze` — used in class names, module names
- **Lowercase name** (`name`): e.g., `firebase`, `appsflyer`, `braze` — used in repo directory, package URLs
- **Repo directory**: `integration-swift-<name>` — created as a sibling of the rudder-sdk-swift repo
- **Module name**: `RudderIntegration<Name>` — e.g., `RudderIntegrationFirebase`
- **Integration class**: `<Name>Integration` — e.g., `FirebaseIntegration`
- **Adapter protocol**: `<Name>Adapter` — e.g., `FirebaseAdapter` (or more specific names like `FirebaseAnalyticsAdapter` if multiple adapters are needed)
- **ObjC bridge class**: `ObjC<Name>Integration` with runtime name `@objc(RSS<Name>Integration)`

If the name has unconventional casing (e.g., `AppsFlyer`, `CleverTap`), ask the user to confirm the PascalCase form.

## Execution Mode

The skill runs in one of two modes, controlled by the `--auto` flag:

### Interactive mode (default)
The agent pauses for user approval at **four checkpoints** — no more:
1. **After Step 1** (analysis + behavior divergences) — the entire run depends on getting the work list right.
2. **After Step 6** (all source + ObjC bridge complete) — the user reviews all generated code before tests/sample app.
3. **After Step 8** (build + test results) — only if there are failures the agent cannot auto-fix.
4. **After Step 10** (sample app validated) — user reviews the sample app before finalization.

Between checkpoints, the agent works continuously without asking for approval.

### Auto mode (`--auto`)
The agent runs end-to-end with **no** `AskUserQuestion` calls except:
- **Behavior divergences** in Step 1 that deviate from "preserve v1 public API".
- **Build/test failures** in Step 8 that the agent cannot auto-fix after two attempts.
- **Third-party SDK dependency** — if the agent cannot determine the SPM package URL/product name automatically.

## Reference Material (read on demand)

Load each reference file with `Read` only when the corresponding step needs it. Use `${CLAUDE_SKILL_DIR}` to resolve absolute paths. Do not paste their contents into responses.

- **`${CLAUDE_SKILL_DIR}/references/api-mapping.md`** — v1 iOS to Swift method mapping (covers both ObjC and Swift v1). Read before Step 1; consult during Step 4.
- **`${CLAUDE_SKILL_DIR}/references/integration-plugin.md`** — `IntegrationPlugin` and `StandardIntegration` protocol signatures. Read before Step 3.
- **`${CLAUDE_SKILL_DIR}/references/test-scaffold.md`** — Swift Testing framework patterns, mock adapter templates, test data providers. Read before Step 7.
- **`${CLAUDE_SKILL_DIR}/references/sample-app.md`** — SwiftUI sample app templates (App entry, ContentView, AnalyticsManager, pbxproj template, asset catalogs). Read before Step 9.
- **`${CLAUDE_SKILL_DIR}/references/supporting-files.md`** — Templates for .gitignore, LICENSE.md, CONTRIBUTING.md, CODEOWNERS, PR template, README. Read during Step 2.

## Locating the v1 Integration Repo

The v1 integration repo (`rudder-integration-<name>-ios`) must be located.

**Auto mode path** (try in order, stop on first success):
1. Check locally: `../rudder-integration-<name>-ios` (sibling of rudder-sdk-swift)
2. Clone from GitHub: `git clone --depth=1 https://github.com/rudderlabs/rudder-integration-<name>-ios /tmp/rudder-integration-<name>-ios`
3. If both fail, fall back to AskUserQuestion

**Interactive mode** — use AskUserQuestion:
- Question: "Where is the v1 integration repo `rudder-integration-<name>-ios` located?"
- Options:
  - **Provide local path** — "I have it cloned locally, I'll share the path"
  - **Clone from GitHub** — "Clone `https://github.com/rudderlabs/rudder-integration-<name>-ios` into a temp directory"

If the user picks **Provide local path**, ask for the absolute path via free-form input. Verify the path exists.

Use the located directory as `V1_REPO_PATH`.

## Locating the Reference Swift Integration

If `closest_example` is provided, locate the reference integration:

1. Check locally: `../integration-swift-<closest_example>` (relative to rudder-sdk-swift)
2. If not found, clone from GitHub:
```bash
git clone --depth=1 https://github.com/rudderlabs/integration-swift-<closest_example> /tmp/integration-swift-<closest_example>
```

**Auto-selection when `closest_example` is not provided:** In auto mode, pick the first locally available Swift integration (`../integration-swift-*`) as a structural reference. Prefer one with a similar event surface (e.g., if the v1 integration only does identify+track, pick a simpler integration over Firebase). If none are available locally, skip the reference and rely solely on the templates in this skill.

Use the reference integration to inform patterns but never copy code blindly — adapt based on the v1 integration's actual behavior.

## Output Directory

The new integration repo is created at the **same level as rudder-sdk-swift**. Determine this dynamically:
```bash
PARENT_DIR=$(dirname "$(pwd)")
OUTPUT_DIR="$PARENT_DIR/integration-swift-<name>"
```

If `OUTPUT_DIR` already exists, ask the user whether to overwrite or abort.

---

## Step-by-Step Process

### Step 0: Validate Prerequisites

1. Confirm `integration_name` is set
2. Locate the v1 integration repo (see above)
3. If `closest_example` is provided (or auto-selected), locate it
4. Determine `OUTPUT_DIR` and confirm it doesn't exist (or get overwrite approval)
5. Identify the third-party SDK dependency:
   - Check the v1 integration's `Podfile`, `.podspec`, or `Package.swift` for the dependency name
   - Search for the equivalent SPM package on GitHub
   - If ambiguous, ask the user for the SPM package URL and product name(s)

### Step 1: Analyze the v1 Integration

Read `${CLAUDE_SKILL_DIR}/references/api-mapping.md` before this step.

**Detect source language first:**
```bash
find $V1_REPO_PATH -path "*/.build" -prune -o -path "*/Example" -prune -o -path "*/Pods" -prune -o -type f \( -name "*.m" -o -name "*.swift" \) -print
```
- If `.m` files found → ObjC integration (look for `RudderXxxFactory.m`, `RudderXxxIntegration.m`)
- If only `.swift` files → Swift v1 integration (look for `RudderXxxFactory.swift`, `RudderXxxIntegration.swift`)

Analyze the integration source files:
1. Find the factory class (e.g., `RudderXxxFactory`) and integration class (e.g., `RudderXxxIntegration`)
2. Enumerate all methods in the integration class:
   - **ObjC**: `initWithConfig:client:rudderConfig:` → `create(destinationConfig:)`, `dump:` with type-checking → separate event methods
   - **Swift v1**: `init(config:client:rudderConfig:)` → `create(destinationConfig:)`, `dump(_ message:)` with switch/if-else → separate event methods
   - `reset` → `reset()`
   - `flush` → `flush()`
   - Any other public methods
3. List all destination SDK calls made (these become the adapter protocol surface)
4. Note any config parsing (keys extracted from `destinationConfig`)
5. Identify utility/helper methods and constants
6. Flag **behavior divergences** — differences between v1 and Swift SDK lifecycles:
   - v1 registers lifecycle callbacks at app boot; Swift registers from `create()` which fires after SourceConfig fetch
   - Any singleton patterns that need adaptation
   - Any AppDelegate/UIApplication/UIViewController dependencies
   - Any public API beyond the standard factory+integration (e.g., `setViewController`, `setDeviceToken`)

Present the analysis summary to the user at **Checkpoint 1**.

Format the checkpoint using `AskUserQuestion`:
- Brief summary in the question text (methods found, adapter surface, divergences)
- Full detailed analysis in the `preview` field of the "Approve" option
- Options: "Approve and continue", "Modify scope" (free-form feedback)

### Step 2: Scaffold the Repo

Read `${CLAUDE_SKILL_DIR}/references/supporting-files.md` before this step.

Create the repo directory structure:
```
integration-swift-<name>/
  .github/
    pull_request_template.md
  .gitignore
  CODEOWNERS
  CONTRIBUTING.md
  LICENSE.md
  Package.swift
  Sources/
    RudderIntegration<Name>/
  Tests/
    RudderIntegration<Name>Tests/
```

1. Create `Package.swift`:
   - `swift-tools-version: 5.9`
   - Package name: `RudderIntegration<Name>`
   - Platforms: derive from the v1 integration's supported platforms. Default to `.iOS(.v15)`. Add `.macOS(.v12)`, `.tvOS(.v15)`, `.watchOS(.v8)` only if the third-party SDK supports them.
   - Dependencies: the third-party SDK SPM package + `rudder-sdk-swift` (`.upToNextMajor(from: "1.0.0")`)
   - Library target depending on the third-party product(s) + `RudderStackAnalytics`
   - Test target depending on the library target. **Important:** If any adapter protocol method uses a type from the third-party SDK (e.g., `EventPayload`, `ABKUser`), add that SDK as a test target dependency too — the mock adapter must import it.

2. Write supporting files using templates from `${CLAUDE_SKILL_DIR}/references/supporting-files.md`, replacing `<name>` and `<Name>` placeholders.

3. Initialize git:
```bash
cd $OUTPUT_DIR && git init && git add -A && git commit -m "chore: initial scaffold"
```

### Step 3: Generate the Adapter Protocol

Read `${CLAUDE_SKILL_DIR}/references/integration-plugin.md` before this step.

Create `Sources/RudderIntegration<Name>/<Name>Adapter.swift`:

1. Define a `protocol <Name>Adapter` with one method per destination SDK call identified in Step 1
2. Create `class Default<Name>Adapter: <Name>Adapter` implementing each method by calling the real SDK
3. If the destination SDK has logically separate surfaces (e.g., Firebase has Analytics + App), split into multiple adapter protocols
4. Add `#if canImport(UIKit) / import UIKit / #endif` if any adapter method uses UIKit types
5. Match the destination SDK's API granularity — if it offers typed overloads (e.g., `setAttribute(key:, boolValue:)` vs a single `[String: Any]` batch setter), use the typed overloads in the adapter protocol

Pattern:
```swift
import Foundation
import <ThirdPartySDK>

protocol <Name>Adapter {
    func someMethod(_ param: Type)
    func getDestinationInstance() -> Any?
}

class Default<Name>Adapter: <Name>Adapter {
    func someMethod(_ param: Type) {
        <ThirdPartySDK>.someMethod(param)
    }

    func getDestinationInstance() -> Any? {
        return <instance or class>
    }
}
```

### Step 4: Implement the Integration Class

Create `Sources/RudderIntegration<Name>/<Name>Integration.swift` with the full implementation:

```swift
import Foundation
import <ThirdPartySDK>
import RudderStackAnalytics

public class <Name>Integration: IntegrationPlugin, StandardIntegration {

    final let adapter: <Name>Adapter

    init(adapter: <Name>Adapter) {
        self.adapter = adapter
    }

    public convenience init() {
        self.init(adapter: Default<Name>Adapter())
    }

    public var pluginType: PluginType = .terminal
    public var analytics: Analytics?
    public var key: String = "<DestinationKey>"

    public func create(destinationConfig: [String: Any]) throws { ... }
    public func getDestinationInstance() -> Any? { ... }

    // Event methods (only those found in the v1 dump: method)
    // public func identify(payload: IdentifyEvent) { ... }
    // public func track(payload: TrackEvent) { ... }
    // public func screen(payload: ScreenEvent) { ... }
    // public func group(payload: GroupEvent) { ... }
    // public func alias(payload: AliasEvent) { ... }
    // public func reset() { ... }
    // public func flush() { ... }
}
```

Implementation guidelines:
- `key` must match the exact destination name from the RudderStack dashboard (e.g., "Firebase", "Braze", "Sprig")
- The `convenience init()` is `public`; the `init(adapter:)` is `internal` (for test injection)
- `pluginType` is always `.terminal`

**`create()` and `update()`:**
- Guard against `create()` being called more than once — check if the destination SDK is already initialized and return early
- Parse config values: `destinationConfig["key"] as? String`
- Initialize the destination SDK via the adapter
- Use `LoggerAnalytics.debug()/error()/warn()` for logging
- If the v1 integration supports config updates, implement `update(destinationConfig:)`
- `create()` must `throw` (not silently return) on critical config errors (missing API key, etc.) so the SDK logs the failure

**Event methods** — translate the v1 `dump:` method's type-checking branches:
- **identify**: Access `payload.userId`, `payload.context?["traits"]`
- **track**: Access `payload.event`, `payload.properties?.dictionary?.rawDictionary`
- **screen**: Access `payload.event` (screen name), `payload.properties?.dictionary?.rawDictionary`
- **group**: Access `payload.groupId`, `payload.traits`
- **alias**: Access `payload.newId`, `payload.previousId`

**Remaining methods:**
- **reset()**: Clear user state, reset destination SDK
- **flush()**: Trigger destination SDK flush (only if v1 integration has it)
- **teardown()**: Implement when the integration holds references (viewController, observers) or registers listeners. Nil out stored references, unregister listeners, clear the SDK instance. Always call `super.teardown()`

Only implement methods that exist in the v1 integration.

### Step 5: Implement Utility Classes

If the v1 integration has helper methods, constants, or event mappings:
1. Create `<Name>Utils.swift` with `static` methods and properties
2. Extract any ecommerce event mapping tables
3. Move helper functions that don't use `self` to the Utils class

### Step 6: Generate the ObjC Bridge

Create `Sources/RudderIntegration<Name>/ObjC<Name>Integration.swift`.

Re-read the ObjC bridge section of `${CLAUDE_SKILL_DIR}/references/integration-plugin.md` (from "## ObjC Bridge Template" onward) for the template and event conversion patterns.

Key points:
- Add `#if canImport(UIKit) / import UIKit / #endif` if any bridged method uses UIKit types
- Bridge each event method that exists in the Swift integration: identify, track, screen, group, alias, reset, flush
- If the Swift integration exposes extra public API (e.g., `viewController` property), bridge those too with `@objc` methods

Present at **Checkpoint 2** — all source files for review.

Format checkpoint using `AskUserQuestion`:
- Brief summary: files created, methods implemented
- Full source listing in `preview`
- Options: "Approve and continue", "Request changes"

### Step 7: Generate Tests

Read `${CLAUDE_SKILL_DIR}/references/test-scaffold.md` before this step.

Create test files:
1. `Tests/RudderIntegration<Name>Tests/<Name>IntegrationTests.swift` — tests for `create`, each event method, `reset`, `flush`, edge cases
2. `Tests/RudderIntegration<Name>Tests/<Name>TestUtils.swift` — `Mock<Name>Adapter` + `<Name>TestData`
3. `Tests/RudderIntegration<Name>Tests/<Name>UtilsTests.swift` — tests for utility functions (only if `<Name>Utils.swift` exists and has non-trivial logic)

Follow these rules:
- Use **Swift Testing** framework (`import Testing`, `@Test`, `#expect`, `@Suite(.serialized)`)
- Mock adapters record all calls in arrays for verification
- If the mock adapter needs to import the third-party SDK for types used in protocol methods, add `import <ThirdPartySDK>` to the test utils file
- Test data providers use `static var`/`static func` for readability
- Test naming: `@Test("given X, when Y, then Z")`
- Create the integration with mock adapter injection: `<Name>Integration(adapter: mockAdapter)`
- Test `getDestinationInstance()` returns non-nil after `create()` and nil before

### Step 8: Build and Test

**Determine the build strategy** based on the platforms declared in `Package.swift`:
- If macOS is listed in platforms → `swift build` and `swift test` work directly
- If macOS is **not** listed (iOS-only, tvOS-only, etc.) → use `xcodebuild`:

```bash
# iOS-only build
cd $OUTPUT_DIR && xcodebuild -scheme <ModuleName> \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation build 2>&1

# iOS-only test
cd $OUTPUT_DIR && xcodebuild -scheme <ModuleName> \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation test 2>&1
```

Replace `<ModuleName>` with the package name (e.g., `RudderIntegrationSprig`).

If the build fails:
1. Read the error output carefully
2. Fix the issue (usually import paths, type mismatches, or missing adapter methods)
3. Rebuild — repeat up to 3 times

If tests fail:
1. Analyze the failures
2. Fix test logic or implementation bugs
3. Re-run — repeat up to 3 times

If failures persist after 3 attempts, present at **Checkpoint 3** with the error details.

### Step 9: Generate the Sample App

Read `${CLAUDE_SKILL_DIR}/references/sample-app.md` before this step.

Create the Example directory:
```
Example/
  <Name>ExampleApp.swift
  ContentView.swift
  Example.xcodeproj/
    project.pbxproj
  Assets.xcassets/
    Contents.json
    AccentColor.colorset/Contents.json
    AppIcon.appiconset/Contents.json
```

1. **`<Name>ExampleApp.swift`**: SwiftUI `@main` App struct with:
   - `setupAnalytics()` in `init()` creating `Configuration`, `Analytics`, the integration, and storing in `AnalyticsManager.shared`
   - `AnalyticsManager` singleton class with methods for each event type the integration supports
   - Use placeholder write key and data plane URL

2. **`ContentView.swift`**: SwiftUI view with:
   - `NavigationView > ScrollView > VStack` layout
   - Sectioned buttons for each event category (identity, tracking, screen, etc.)
   - `PrimaryButtonStyle` and `SecondaryButtonStyle` structs
   - `#Preview { ContentView() }`

3. **`project.pbxproj`**: Use the parameterized template from `${CLAUDE_SKILL_DIR}/references/sample-app.md`:
   - Generate 23 unique 24-character hex IDs
   - Replace all `{{PLACEHOLDER}}` values including `{{IOS_DEPLOYMENT_TARGET}}`
   - Local SPM package reference: `../../integration-swift-<name>`
   - Product dependency: `RudderIntegration<Name>`
   - Bundle identifier: `com.rudderstack.<Name>Example`

4. **Asset catalogs**: Standard Xcode asset catalog JSON files (identical across all integrations)

### Step 10: Validate the Sample App

Build the sample app to verify the Xcode project is valid:
```bash
cd $OUTPUT_DIR && xcodebuild -project Example/Example.xcodeproj \
  -scheme Example \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipPackagePluginValidation build 2>&1
```

If the build fails, fix the pbxproj or Swift source and retry up to 2 times.

Present at **Checkpoint 4** — sample app validated.

### Step 11: Generate README

Create `README.md` with:
- Integration name and description
- Installation instructions (SPM only — add package URL)
- Usage example (Swift and ObjC)
- Any integration-specific setup notes (e.g., viewController requirement for Sprig)
- Link to RudderStack docs

### Step 12: Final Commit

```bash
cd $OUTPUT_DIR && git add -A && git commit -m "feat: initial integration implementation"
```

Report completion with a summary of:
- Files created
- Methods implemented
- Test results
- Any known limitations or TODOs

---

## Code Style Rules

- Use Swift idioms: `guard let`, `if let`, optional chaining, `switch` over `if-else` chains
- No force unwraps (`!`) — use `guard` or optional chaining
- Logging: `LoggerAnalytics.debug()`, `.error()`, `.warn()` — never `print()`
- Config access: `destinationConfig["key"] as? String` — always optional cast
- Event properties: `payload.properties?.dictionary?.rawDictionary` for `[String: Any]`
- No `isConfigured`/`isInitialized` state booleans — rely on the destination instance being non-nil
- Every method that exists in the v1 integration must have a Swift equivalent
- Preserve business logic exactly from v1 — do not "improve" or refactor the logic
- Adapter methods should be minimal wrappers — no business logic in the adapter
- `internal` visibility for adapter init, `public` for everything else in the integration class
- Add `#if canImport(UIKit) / import UIKit / #endif` to any file that uses UIKit types
