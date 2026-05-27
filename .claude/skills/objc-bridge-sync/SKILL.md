---
name: objc-bridge-sync
description: Flag drift between public Swift types in Sources/RudderStackAnalytics/ and their @objc(RSS…) wrappers under Sources/RudderStackAnalytics/ObjC/. Use when the user types /objc-bridge-sync, or before pushing a branch whose diff touches a public Swift type that is ObjC-bridged.
---

# objc-bridge-sync

This SDK ships a parallel Objective-C surface under `Sources/RudderStackAnalytics/ObjC/`. When a public Swift type changes, its `@objc(RSS…)` wrapper must change with it — there is no compiler check for this, and SwiftLint does not enforce it. This skill is the manual check.

## When to run

- User invokes `/objc-bridge-sync` explicitly.
- User is about to push or open a PR and the branch diff modifies a file under `Sources/RudderStackAnalytics/` outside the `ObjC/` subdirectory.

Do not run on diffs that only touch `Tests/`, `Examples/`, `ObjC/` alone, or non-public types.

## Procedure

1. **Collect candidate Swift files** from the diff. This repo uses `develop` as the integration branch (PRs merge into `develop`; `main` only advances on release), so diff against `origin/develop`:

   ```bash
   git diff origin/develop...HEAD --name-only -- 'Sources/RudderStackAnalytics/*' ':!Sources/RudderStackAnalytics/ObjC/*'
   ```

   If `origin/develop` is unreachable (no remote, detached state, fresh clone), try in order: `origin/main`, `main`, `develop`. If none resolve, fall back to working-tree changes only and warn the user that the diff base is unverified:

   ```bash
   git diff HEAD --name-only -- 'Sources/RudderStackAnalytics/*' ':!Sources/RudderStackAnalytics/ObjC/*'
   ```

   Always also run the working-tree diff and union its file list with the branch diff — committed work on a feature branch plus uncommitted tweaks both count, and the user may have either or both:

   ```bash
   git diff HEAD --name-only -- 'Sources/RudderStackAnalytics/*' ':!Sources/RudderStackAnalytics/ObjC/*'
   ```

2. **For each candidate file**, find the public type declarations actually touched by the diff (not just every public type in the file):

   ```bash
   git diff origin/develop...HEAD -- <file> \
     | grep -E '^\+.*\bpublic\s+(class|struct|enum|protocol|actor|extension)\b'
   ```

   Skip the file if no public declaration appears in the diff hunks. For changes to existing public members, also grep the hunks for `^\+.*\bpublic\s+(var|let|func|init)\b` so renamed or new members on an unchanged type declaration are caught.

3. **Classify the bridge pattern** for each public type `T`:

   | Pattern | How to recognise | Wrapper file |
   |---|---|---|
   | **Direct `@objc(RSS<T>)`** | `T` itself carries `@objc(RSS<T>)` or `@objc` and inherits `NSObject` | none — `T` *is* its own bridge |
   | **Builder wrapper** | a class in `ObjC/` is annotated `@objc(RSS<T>Builder)` and has a `build() -> T` method | `Sources/RudderStackAnalytics/ObjC/**/ObjC<T>.swift` |
   | **Delegation wrapper** | a class in `ObjC/` is annotated `@objc(RSS<T>)` and holds a `let` reference of type `T` | `Sources/RudderStackAnalytics/ObjC/**/ObjC<T>.swift` |

   **Filename convention:** the wrapper *file* is always `ObjC<T>.swift` regardless of pattern. The `Builder` suffix appears only in the `@objc(…)` symbol, not the filename. Example: `ObjC/Base/ObjCConfiguration.swift` declares `@objc(RSSConfigurationBuilder)`. Don't hunt for `ObjCConfigurationBuilder.swift` — it doesn't exist.

   Locate wrappers with:

   ```bash
   grep -rln "@objc(RSS" Sources/RudderStackAnalytics/ObjC/
   ```

4. **Diff the public surface**:
   - From `T.swift`: enumerate `public` properties, methods, and `init` parameters touched by the diff (see step 2's grep).
   - From the wrapper file, enumerate `@objc`-exposed members:

     ```bash
     grep -nE '@objc(\([^)]*\))?\s+(public\s+)?(func|var|let)' <wrapper-file>
     ```

     For builder wrappers, also look for `func setX(_:)` setter methods that may not carry an explicit `@objc` attribute (they inherit it from the class-level `@objc(RSS…Builder)`).
   - **For public protocols** (e.g. `Plugin`, `EventPlugin`, `IntegrationPlugin`), the wrapper is typically `ObjC<T>` as an `NSObject`-backed adapter class implementing forwarding. Diff added protocol requirements against the wrapper's `@objc` method list.
   - Report:
     - Swift members added or renamed with no matching wrapper member. (Treat a removed+added pair with a similar name/signature as a likely rename and flag both sides.)
     - Wrapper members whose signature no longer matches the Swift side.
     - Swift members removed but still exposed on the wrapper.

5. **Handle new public types**:
   - If the diff adds a new `public` type with no wrapper and the type is not in the allowlist below, ask the user: "Is `<TypeName>` intentionally Swift-only? If yes, I'll add it to the skill allowlist. If no, the wrapper goes at `Sources/RudderStackAnalytics/ObjC/<area>/ObjC<TypeName>.swift`."

## Swift-only allowlist

These public types are intentionally not 1:1 bridged. Do NOT flag changes to them as missing wrappers:

- Concrete event structs: `TrackEvent`, `ScreenEvent`, `IdentifyEvent`, `GroupEvent`, `AliasEvent` — bridged via the generic `ObjCEvent` protocol adapter in `Sources/RudderStackAnalytics/ObjC/Events/ObjCEvent.swift`.
- Plugin sub-protocols beyond `Plugin`, `EventPlugin`, `IntegrationPlugin` — only those three have ObjC analogs.
- The `Logger` protocol — exposed via the `ObjCAnalyticsLogger` adapter, not as a wrapper class.
- Internal-by-design helpers: any type without the `public` modifier (the diff filter already excludes these, but double-check before flagging).

When adding to this list, edit this SKILL.md file directly — keeping the list inline ensures it goes through code review.

## Report format

One markdown section per candidate Swift type. Use `✓` and `⚠` so the user can scan quickly.

```
### Configuration  (Sources/RudderStackAnalytics/Base/Configuration.swift)
Wrapper: ObjCConfigurationBuilder  (Sources/RudderStackAnalytics/ObjC/Base/ObjCConfiguration.swift)

⚠ Missing on wrapper:
  - public var gzipEnabled: Bool  → add `setGzipEnabled(_:)` to ObjCConfigurationBuilder
  - public var flushAt: Int       → add `setFlushAt(_:)` to ObjCConfigurationBuilder

✓ In sync:
  - writeKey, dataPlaneUrl, controlPlaneUrl
```

End with a one-line summary: `N type(s) checked, M wrapper change(s) needed.`

If no drift is found, the entire report can be a single line: `✓ All bridged types in this diff are in sync (N type(s) checked).`

## Caveats

- This is a heuristic — the report is a checklist for a human, not a guarantee. Always confirm the suggested wrapper edits compile and that the ObjC method signatures match the project's existing naming conventions (e.g., builder setters prefix with `set`, return `self` for chaining).
- The skill does not run Swift compilation. If a flagged type involves Swift-only constructs (associated-value enums, generics, `async` without an ObjC completion-handler shim), call that out in the report rather than naively proposing a wrapper method.
- Do not edit the wrapper files as part of this skill — only report. The user (or a follow-up edit task) makes the actual changes.
