# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

VistaClock is a macOS menubar clock utility. Clicking the status bar item opens a panel with
an analog clock (with second hand) and a month calendar. It also supports week-number display
in the menu bar, additional world clocks with time zone support, selectable clock faces, and
event/reminder indicators drawn onto calendar days via EventKit.

Original author: pawong / Mazookie, LLC. Released under MIT after Mazookie left the Mac App
Store. This repository is a fork maintained for personal use on Apple Silicon.

**Goal of this fork:** get a native arm64 build that runs reliably on current macOS, keeps the
original behavior, and can be maintained by one person indefinitely without an Apple Developer
Program membership.

## Non-goals (do not do these unless explicitly asked)

- Do not rewrite the app in Swift or SwiftUI. The Objective-C is in better shape than it looks.
  Incremental Swift files are fine where they solve a specific problem (see `LoginItemHelper.swift`).
- Do not restructure the project layout, rename the `MZ` class prefix, or reformat files wholesale.
  Keep diffs small and reviewable.
- Do not add third-party dependencies, package managers, or a Sparkle-style updater.
- Do not re-add App Store sandboxing. The app is distributed outside the store now.
- Do not add analytics, telemetry, or network calls of any kind. This app has no business
  touching the network.

## Build and run

Requires Xcode on an Apple Silicon Mac. There is no CI, no test target, and no test suite.

```bash
# Build (Debug)
xcodebuild -project VistaClock.xcodeproj -scheme VistaClock -configuration Debug build

# Build (Release)
xcodebuild -project VistaClock.xcodeproj -scheme VistaClock -configuration Release build

# Confirm the produced binary is native arm64 and not Intel
file build/Release/VistaClock.app/Contents/MacOS/VistaClock
# expect: Mach-O 64-bit arm64 executable

# Launch a built app
open build/Release/VistaClock.app
```

Day to day, building and running from the Xcode GUI is usually easier because of the login-item
helper and the TCC permission prompts.

### Signing

There is no paid Apple Developer account behind this fork. The project is set to ad-hoc signing
(`CODE_SIGN_IDENTITY = "-"`, empty `DEVELOPMENT_TEAM`) so command-line and GUI builds sign and run
locally without a team — equivalent to **Sign to Run Locally**. Hardened runtime requires *some*
signature, so an empty identity is not enough; keep it at `-` (or a free personal team). Do not
commit a change that hardcodes any specific Team ID or restores `"Mac Developer"`.

Notarization is not possible without a paid account and is out of scope. The app is for personal
use on machines where it can be launched manually the first time.

## Architecture

Objective-C with ARC, plus one Swift file. AppKit, hand-drawn `NSView` subclasses, XIB-based UI.
Roughly 5,500 lines total. No storyboards, no Auto Layout in the custom controls.

| File | Role |
|---|---|
| `MZVistaClockAppDelegate.m` | The center of gravity (~1,240 lines). Owns the `NSStatusItem`, the panel window, the menu bar text/week-icon updates, the timer tick, and EventKit authorization. Start here. |
| `MZCalendarControl.m` | Custom-drawn month calendar (~880 lines). Owns its own `EKEventStore` and draws the event/reminder indicator dots. |
| `MZVistaClockPreferences.m` | Preferences window controller (~600 lines). Also contains the login-item toggle logic. |
| `MZClockControl.m` / `MZClockControlCell.m` | Analog clock face. Control/cell split, drawing lives in the cell. |
| `MZDateCalc.m`, `NSDate+Tools.m` | Date math and week-number helpers. Pure logic, no UI. Safe to touch. |
| `MZClockItem.m`, `MZClockConfig*.m` | Model + config UI for the additional time zone clocks. |
| `MZStatusItemView.m` | Legacy custom status item view. **Believed dead code.** The app delegate now uses `NSStatusBarButton` directly. Verify before deleting. |
| `LoginItemHelper.swift` | Thin `@objc` wrapper around `SMAppService.loginItem(identifier:)`. Called from Objective-C. |
| `VistaClockLoginHelper/` | Separate helper app target that gets registered as the login item. |

Clock faces are bare PNGs sitting loose in `VistaClock/` (`DVCB06.png`, `HVCB02.png`, `MVCW08.png`
and friends), not in the asset catalog. The naming encodes face variants. Leave them alone.

### Settings persistence (read this before touching VCSettings)

Settings do **not** live in `NSUserDefaults`. `VCSettings` is a singleton that `NSKeyedArchiver`s
itself to a flat file:

```
~/Library/VistaClock.cfg        # unsandboxed (2.4.0 and this fork)
~/Library/Containers/com.Mazookie.VistaClock/Data/Library/VistaClock.cfg   # sandboxed (2.3.4, App Store)
```

The path comes from `+[VCSettings archivePath]`, built from `NSLibraryDirectory` plus the bundle
name. Because 2.4.0 dropped the sandbox, it looks in the real `~/Library` and will not see
settings written by the old App Store build.

The user's world clocks are an `NSMutableArray` of `MZClockConfig` objects on
`VCSettings.clockConfigs`. Each holds `title`, `timezoneName`, and `useSeconds` (the per-clock
second hand toggle). This array is the single most valuable piece of user state in the app and
the only part that is painful to reconstruct by hand. Treat it accordingly.

Back up before experimenting:

```bash
cp ~/Library/VistaClock.cfg ~/vistaclock-cfg-backup.plist
```

## State of the migration

pawong had already done most of the Apple Silicon and modern-API work before open sourcing, but
marked the 2.4.0 build "untested." Already done before this fork:

- `MACOSX_DEPLOYMENT_TARGET = 26.0`, `EXCLUDED_ARCHS = x86_64`, `SWIFT_VERSION = 6.0`
- Hardened runtime on, sandbox entitlements emptied out
- `NSStatusBarButton` instead of the old custom status item view
- `SMAppService` login item registration, with an `SMLoginItemSetEnabled` fallback path
- EventKit `requestFullAccessToEventsWithCompletion:` / `requestFullAccessToRemindersWithCompletion:`

Done in this fork (the previously "untested" 2.4.0 now runs correctly on Apple Silicon):

- Settings actually persist now (backlog item 1) and the over-release crash it exposed is fixed.
- EventKit full-access usage descriptions added (backlog item 2).
- Ad-hoc signing so local builds work without a paid account.
- Secondary time zone restored as two stacked lines in the menu bar, drawn onto the
  `NSStatusBarButton`'s `attributedTitle`.
- Panel header rebuilt to match the original: removed the half-finished expandable toolbar
  (goto-date field / today button / day-details) and its crash, switched to a `unified` toolbar
  showing the date as the window's native title, and made `resizeWindow` enforce a compact height
  instead of preserving a stale one.

## Known issues / working backlog

Roughly in priority order. Items 1 and 2 are now FIXED; 3 and 4 remain.

### 1. Settings never persist across launches (FIXED)

Fixed in commit "Fix settings persistence and the crash it exposed." The minimal reader fix below
was applied, and it exposed a latent over-release crash: `statusSecondaryTimezone` was a
`(nonatomic, assign)` `NSString*` (unsafe_unretained under ARC), harmless only while settings never
loaded and the property held the immortal `@"GMT"` default. Once real archives loaded, the decoded
string was freed and `updateTime` crashed in `objc_retain`. Changed it to `retain` to match the
sibling object properties. **If you touch `VCSettings`, keep every object property `retain`/`copy`.**
The history below is kept for context; the **proper `NSSecureCoding` fix is still pending** (see end).

**Symptom (was):** the user configures world clocks, faces, menu bar format, and so on. Everything
resets to defaults on the next launch.

**Cause:** a secure-coding mismatch between the writer and the reader in `VCSettings.m`.

- Write, line 41: `archivedDataWithRootObject:self requiringSecureCoding:NO`
- Read, line 84: `[NSKeyedUnarchiver unarchivedObjectOfClass:[VCSettings class] fromData:...]`

`unarchivedObjectOfClass:` implicitly requires secure coding. **Nothing in this codebase adopts
`NSSecureCoding`.** Neither `VCSettings` nor `MZClockConfig` implements `+supportsSecureCoding`.
It also whitelists only `VCSettings`, while the archive additionally contains an `NSMutableArray`
of `MZClockConfig` objects, which would be rejected even if secure coding were adopted.

So every launch the read throws, the error is logged, and control falls through to line 94 which
allocates a fresh default `VCSettings`. The settings are written to disk correctly. They are
simply never read back.

**Verify:**

```bash
ls -l ~/Library/VistaClock.cfg
log show --predicate 'process == "VistaClock"' --last 10m | grep -i unarchive
```

**Minimal fix.** Replace line 84 with a reader that matches what the writer actually produces:

```objc
NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&unarchiveError];
unarchiver.requiresSecureCoding = NO;
sharedSettings = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
[unarchiver finishDecoding];
```

Commit this alone and confirm settings survive a relaunch before doing anything else.

**Proper fix, as a separate later commit.** Adopt `NSSecureCoding` on both `VCSettings` and
`MZClockConfig`: declare conformance in the headers, add `+ (BOOL)supportsSecureCoding { return YES; }`,
convert every `decodeObjectForKey:` to `decodeObjectOfClass:forKey:`, write with
`requiringSecureCoding:YES`, and read with `unarchivedObjectOfClasses:` passing a set containing
`VCSettings`, `NSMutableArray`, `MZClockConfig`, `NSString`, and `NSNumber`. Keep a fallback that
can still read a legacy non-secure archive so existing configs are not orphaned.

### 2. EventKit full-access usage descriptions are missing (FIXED)

Fixed in commit "Add EventKit full-access usage descriptions." The code calls
`requestFullAccessToEventsWithCompletion:` / `requestFullAccessToRemindersWithCompletion:`;
`VistaClock-Info.plist` now declares `NSCalendarsFullAccessUsageDescription` and
`NSRemindersFullAccessUsageDescription` alongside the legacy keys.

Note: on a machine that has *already* granted access, the full-access request returns immediately
without a prompt, so the dots appeared even before this fix. The missing keys only bite on a clean
install or after a TCC reset, where macOS would try to present the prompt and could terminate the
app instead.

### 3. Migrate the user's existing settings from the old sandbox container

Once item 1 is fixed, the old App Store config can be recovered:

```bash
cp ~/Library/Containers/com.Mazookie.VistaClock/Data/Library/VistaClock.cfg ~/Library/VistaClock.cfg
```

Consider a one-time migration in `+sharedSettings`: if the unsandboxed path is absent and the
container path exists, read from the container and write forward. Do not delete the original.

### 4. Remaining cleanup

- **`CalendarStore.framework` is still imported and linked.** `MZCalendarControl.h` line 3 does
  `#import <CalendarStore/CalendarStore.h>`, and the framework is still in the link phase.
  CalendarStore was deprecated in favor of EventKit long ago and nothing appears to use it.
  Remove the import, unlink the framework, confirm it still builds.
- **`ONLY_ACTIVE_ARCH = YES` in both configurations.** Fine for Debug, wrong for Release. Still open.
- ~~**`CODE_SIGN_IDENTITY = "Mac Developer"`** will not resolve.~~ Fixed — now ad-hoc `-`. See Signing above.
- **Dead code.** `MZStatusItemView.m` (~260 lines) is now genuinely unused: the app delegate uses
  `NSStatusBarButton` (including the stacked secondary-time `attributedTitle`), never this view.
  Still not deleted — confirm and ask before removing. The `SMLoginItemSetEnabled` fallback in
  `MZVistaClockPreferences.m` is unreachable at a 26.0 deployment target. The half-finished
  expandable panel toolbar (`toggleToolbar:`, the goto-date/today/day-details toolbar items) has
  already been removed.

### 5. Visual verification on current macOS

The calendar and clock face are hand-drawn in `drawRect:`. Check both light and dark mode,
confirm the panel still auto-hides on focus loss, confirm "keep on top" behaves, and verify the
loose clock face PNGs render crisply on a Retina display. They predate current display densities.

**Reference for "correct":** local date and time plus a secondary time zone in the menu bar
(GMT+7 for Thailand), a click-away panel with a month calendar carrying event indicator dots,
prev/next/today navigation arrows, and five named world clocks with per-clock second hands.
That is the target behavior. Anything less is a regression.

## Conventions

- Objective-C, ARC enabled, `MZ` class prefix, `.h`/`.m` pairs.
- Existing code style: opening brace on its own line in some files, trailing `// end methodName`
  comments on long methods. Match the surrounding file rather than imposing a global style.
- Prefer fixing a deprecation over silencing the warning.
- When changing anything permission-related (EventKit, login item), say so explicitly in the
  commit message. Those are the failure modes that are hardest to notice.

## Working agreement

- Make one logical change per commit. This fork's value is that its history stays legible.
- After any change to build settings, always re-run the `file` check above to confirm the binary
  is still native arm64. Silently regressing to an Intel build defeats the entire purpose of
  this fork.
- Ask before deleting anything you believe is dead code. "Believed dead" in this repo has already
  been wrong once.
