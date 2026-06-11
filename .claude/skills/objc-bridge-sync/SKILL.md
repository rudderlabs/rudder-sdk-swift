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

1. **Collect candidate Swift files** from the diff. This repo uses `develop` as the integration branch (PRs merge into `develop`; `main` only advances on release), so diff against `origin/develop`. With the second ref omitted, the three-dot form diffs the merge-base against the working tree — committed branch work and uncommitted tweaks are both collected in one pass:

   ```bash
   git diff origin/develop... --name-only -- 'Sources/RudderStackAnalytics/*' ':!Sources/RudderStackAnalytics/ObjC/*'
   ```

   If `origin/develop` does not resolve (no remote, shallow or single-branch clone), fall back to the local `develop` branch. Whichever resolves is the **diff base** — reuse it for every diff command in the rest of this procedure. Do not substitute `main`/`origin/main`: `main` only advances on release, so diffing against it would flag changes already merged to `develop`. If neither ref resolves, there is no diff base; fall back to working-tree changes only and warn the user that the diff base is unverified:

   ```bash
   git diff HEAD --name-only -- 'Sources/RudderStackAnalytics/*' ':!Sources/RudderStackAnalytics/ObjC/*'
   ```

2. **For each candidate file**, find the public type declarations actually touched by the diff (not just every public type in the file). Use the diff base resolved in step 1, in the same working-tree-inclusive three-dot form:

   ```bash
   git diff <diff-base>... -- <file> \
     | grep -E '^\+.*\bpublic\s+(class|struct|enum|protocol|actor|extension)\b'
   ```

   If step 1 found no diff base, inspect working-tree hunks instead: `git diff HEAD -- <file>`.

   Skip the file if no public declaration appears in the diff hunks. For changes to existing public members, also grep the hunks for `^\+.*\bpublic\s+(var|let|func|init)\b` so renamed or new members on an unchanged type declaration are caught.

3. **Classify the bridge pattern** for each public type `T`:

   | Pattern | How to recognise | Wrapper file |
   |---|---|---|
   | **Direct `@objc(RSS<T>)`** | `T` itself carries `@objc(RSS<T>)` or `@objc` and inherits `NSObject` | none — `T` *is* its own bridge |
   | **Builder wrapper** | a class in `ObjC/` is annotated `@objc(RSS<T>Builder)` and has a `build() -> T` method | usually `ObjC/**/ObjC<T>.swift` — resolve via the grep below |
   | **Delegation wrapper** | a class in `ObjC/` is annotated `@objc(RSS<T>)` and holds a `let` reference of type `T` | usually `ObjC/**/ObjC<T>.swift` — resolve via the grep below |

   **Locating the wrapper file:** never guess from the filename — resolve it by grepping for the `@objc(RSS…)` symbol:

   ```bash
   grep -rln "@objc(RSS<T>" Sources/RudderStackAnalytics/ObjC/
   ```

   The *usual* filename is `ObjC<T>.swift` with the `Builder` suffix only in the `@objc(…)` symbol (e.g. `ObjC/Base/ObjCConfiguration.swift` declares `@objc(RSSConfigurationBuilder)`), but this is not universal: `ObjC/StateManagement/ObjCResetEntriesBuilder.swift` (`@objc(RSSResetEntriesBuilder)`) and `ObjCResetOptionsBuilder.swift` (`@objc(RSSResetOptionsBuilder)`) carry the suffix in the filename too. The grep is authoritative; treat the filename only as a hint.

4. **Diff the public surface**:
   - From `T.swift`: enumerate `public` properties, methods, and `init` parameters touched by the diff (see step 2's grep).
   - From the wrapper file, enumerate `@objc`-exposed members. In this codebase `@objc` is almost always on its own line, often with further attributes (`@discardableResult`, `@available`) between it and the declaration — a same-line grep finds nothing. Scan forward from each `@objc` to the next declaration line instead:

     ```bash
     awk '/@objc/ { armed = 1 }
          armed && !/private/ && /(^|[^A-Za-z0-9_])(func|var|let|init)[^A-Za-z0-9_]/ { print FILENAME ":" FNR ":" $0; armed = 0 }' <wrapper-file>
     ```

     (The spelled-out character classes are deliberate — macOS BSD awk does not support `\b`, which silently matches nothing. The first rule also arms on the same line, so single-line `@objc public func …` declarations are caught too. The class-level `@objc(RSS…)` annotation may make the scan print the first non-private member after the class declaration even if it lacks its own `@objc` — such a member is NOT actually exposed to Objective-C; see the exposure rule below.)

     Class-level `@objc(RSS…)` does NOT implicitly expose members (Swift 4 removed that inference, and this codebase never uses `@objcMembers`) — every exposed member needs its own `@objc`, and in the existing builder wrappers every `setX(_:)` and `build()` does carry one. So if a `public func`/`var` in a wrapper has no `@objc` of its own, do not count it as exposed: flag it as a probable bridge gap (the one current exception, `ObjCEvent.originalTimestamp`, is recorded in the allowlist below).
   - **For public protocols** (e.g. `Plugin`, `EventPlugin`, `IntegrationPlugin`), the wrapper is typically `ObjC<T>` as an `NSObject`-backed adapter class implementing forwarding. Diff added protocol requirements against the wrapper's `@objc` method list.
   - Report:
     - Swift members added or renamed with no matching wrapper member. (Treat a removed+added pair with a similar name/signature as a likely rename and flag both sides.)
     - Wrapper members whose signature no longer matches the Swift side.
     - Swift members removed but still exposed on the wrapper.

5. **Handle new public types**:
   - If the diff adds a new `public` type with no wrapper and the type is not in the allowlist below, ask the user: "Is `<TypeName>` intentionally Swift-only? If yes, I'll add it to the skill allowlist. If no, the wrapper goes at `Sources/RudderStackAnalytics/ObjC/<area>/ObjC<TypeName>.swift`."

## Allowlist: bridging exceptions

Not every public Swift symbol maps 1:1 onto its own wrapper member — some are intentionally Swift-only, others are bridged once in a shared place. Do NOT flag the following as missing:

- Members the concrete event structs (`TrackEvent`, `ScreenEvent`, `IdentifyEvent`, `GroupEvent`, `AliasEvent`) inherit from the `Event` protocol are bridged once on the shared `ObjCEvent` base class (`@objc(RSSEvent)`, `Sources/RudderStackAnalytics/ObjC/Events/ObjCEvent.swift`): `anonymousId`, `userId`, `channel`, `integrations`, `context`, `traits`, `messageId`, `sentAt`, `type`, and `originalTimestamp` (the last is public on the base but carries no `@objc` — Swift-only by current state). Don't demand per-wrapper duplicates of these. Two `Event` members are the opposite — `options` and `userIdentity` are re-exposed on **each** concrete wrapper, not the base. Everything else on a concrete event struct IS 1:1 bridged: each has its own wrapper subclass (`ObjCTrackEvent`/`@objc(RSSTrackEvent)`, `ObjCScreenEvent`/`@objc(RSSScreenEvent)`, …) exposing the event-specific properties and initializers — changes to those members must be checked against the concrete wrapper as usual.
- Plugin sub-protocols beyond `Plugin`, `EventPlugin`, `IntegrationPlugin` — only those three have ObjC analogs.
- The `Logger` protocol — exposed via the `ObjCAnalyticsLogger` adapter, not as a wrapper class.
- Internal-by-design helpers: any type without the `public` modifier (the diff filter already excludes these, but double-check before flagging).

When adding to this list, edit this SKILL.md file directly — keeping the list inline ensures it goes through code review.

## Report format

One markdown section per candidate Swift type. Use `✓` and `⚠` so the user can scan quickly.

```text
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
