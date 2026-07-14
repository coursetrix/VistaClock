# VistaClock ![](VistaClock/Media.xcassets/AppIcon.appiconset/icon_32x32@2x.png)

**VistaClock** is a quick and easy way to show a calendar and analog clock with second hand. It's the missing Windows task clock for MacOS.

Rather than loading a time consuming calendar to simply get the date for next Tuesday, Vista Clock is just a click away.

**Features**:

- Quick access to calendar and analog clock with second hand.
- Start on Login option.
- Week Number Icon in the statusbar (color or monochrome).
- Auto hide when not in focus.
- Keep on Top option.
- Two additional clocks with time zone support.
- Format statusbar clock.
- Custom Clock Control, choice of clock faces.
- Custom Calendar Control.
- Week Number calendar view.
- Automatically hides when not in focus.
- Connects to iCal and Reminders and shows indicators.

## Screenshots
![](Screenshot1.png)

## Install

1. Download **VistaClock.dmg** (see [Versions](#versions) below).
2. Open the DMG and drag **VistaClock** onto the **Applications** shortcut.
3. Eject the DMG and launch VistaClock from Applications.

### First launch: getting past the Apple security warning

VistaClock is signed to run locally but is **not notarized** — notarization needs a paid Apple
Developer account, which this fork intentionally does without. So the first time you open it,
macOS blocks it with a message like *"Apple could not verify VistaClock is free of malware."*
This is expected. You only need to clear it **once**, either way below.

**Option A — System Settings (no Terminal):**

1. Double-click **VistaClock**. On the warning, click **Done** — *not* "Move to Trash".
2. Open **System Settings → Privacy & Security**.
3. Scroll to the **Security** section. You'll see *"VistaClock was blocked to protect your Mac."*
4. Click **Open Anyway** and confirm with Touch ID or your password.
5. VistaClock opens, and it won't warn you again.

**Option B — Terminal (one command):**

Remove the download-quarantine flag, then open the app normally:

```bash
xattr -dr com.apple.quarantine /Applications/VistaClock.app
```

After the first successful launch, VistaClock behaves like any other app. It will separately
ask for Calendar and Reminders access the first time it shows event/reminder dots — that's the
normal macOS privacy prompt, not the Gatekeeper warning above.

## Versions
>[2.3.4](builds/VistaClock_v2.3.4/VistaClock.zip)
>
>    Changes:
>    - Works with Intel and Silicon chip sets

>[2.4.0](builds/VistaClock_v2.4.0/VistaClock.zip)
>
>    Changes:
>    - Open sourced code
>    - Update to support latest MacOS
>    - Updated for Silicon only
>
>    Issues:
>    - Untested
> 

>[2.4.1](https://github.com/coursetrix/VistaClock/releases/tag/v2.4.1) — download **VistaClock.dmg** from the release
>
>    Changes:
>    - Fixed settings not persisting across launches
>    - Fixed a startup crash caused by the secondary time zone setting
>    - Restored the compact panel header (removed the unfinished expandable toolbar)
>    - Restored the stacked secondary time zone display in the menu bar
>    - Added EventKit full-access usage descriptions (calendar event / reminder dots)
>    - Ad-hoc signing so local builds run without a paid Apple account
>    - Removed the dead Mac App Store review link and updated the in-app help
>
>    Tested on Apple Silicon, macOS 26
>

## Fork

A fork of the original VistaClock, updated to run as a native Apple Silicon (arm64) build on
current macOS. Maintained by [Martin Versluis](https://github.com/coursetrix).

Changes in this fork:

- Native arm64 build for current macOS (no Intel / Rosetta).
- Fixed settings not persisting across launches (world clocks, clock faces, menu-bar format)
  and a related startup crash.
- Restored the original compact panel header; removed the half-finished expandable toolbar.
- Restored the stacked secondary time zone display in the menu bar.
- Added EventKit full-access usage descriptions so calendar event / reminder dots work on
  macOS 14+.
- Ad-hoc code signing so it builds and runs locally without a paid Apple Developer account.
- Removed the dead Mac App Store review link and updated the in-app help.

Original app © Mazookie, LLC, released under the MIT License; this fork preserves that license.

## Support

**Bugs and requests?**  Please use the project's [issue tracker].

[![Issues](http://img.shields.io/github/issues/pawong/VistaClock.svg)](https://github.com/pawong/VistaClock/issues)

**Want to contribute?**  Please fork this repository and open a pull request with your new changes.

[![Pull requests](http://img.shields.io/github/issues-pr/pawong/VistaClock.svg?maxAge=3600)](https://github.com/pawong/VistaClock/pulls)

**Do you like it?**  Support the project by starring the repository or [tweet] about it.

## Thanks for looking!
*If you like what you see* [!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/pawong)

**VistaClock** © 2026, Mazookie, LLC. Released under the [MIT License](LICENSE).

[tweet]: https://twitter.com/intent/tweet?
[issue tracker]: https://github.com/pawong/VistaClock/issues/new

![](https://www.mazookie.com/img/Mazookie_full_logo_sticker_small.png)

Q: What is Mazookie?

A: Mazookie is a company that used to put apps on the MacOS App Store. This doesn't happen any more because Apple charges money to be a developer and there's no money in these apps, so the projects have been opensourced. Yeah, free stuff!
