# NetMeter

NetMeter is a native macOS menu bar app that shows live download and upload speeds, plus how much data your Mac has used while the app is running. Click the readout for a quick dashboard; open Settings to choose what appears in the menu bar and review daily usage.

**[Get the latest release](https://github.com/Sudhirkumar136/SpeedMeter/releases)** · **macOS 15 or later** · **Apple silicon and Intel**

> The current downloadable preview is ad hoc signed and has not been notarized by Apple. macOS Gatekeeper may block it on another Mac. See [Build and install](#build-and-install) for the supported local build path. A broadly installable release needs Developer ID signing and notarization.

## At a glance

| Menu bar | Settings | Statistics |
| --- | --- | --- |
| Live speeds and up to three fixed-position metrics | Choose metrics, units, and separate download/upload font styles | Review daily trends and export exact byte counts to CSV |

NetMeter uses SwiftUI, AppKit, Apple's Charts and ServiceManagement frameworks, and system interface counters. It does not run internet speed tests or use third-party runtime packages. Network usage remains stored on your Mac.

## Requirements

- macOS 15 or later
- Xcode 16 or later for building

## Features

- Download and upload speeds updated every 0.5, 1, 2, or 5 seconds (1 second by default)
- Five available menu bar metrics; show up to three at once and drag to change their order
- A compact, fixed-width menu bar readout on a transparent background (for example, `↓   2.4M ↑ 312.5K Σ   1.4G`); in Auto mode, K/M/G abbreviate binary byte units
- Auto, KB/s, MB/s, Mbps, and Gbps speed units; 0 to 2 decimal places; symbol and unit display options
- A visible Font Style tab with menu bar font size, separate download/upload styles, and a live preview
- Session and daily download, upload, and total usage
- Usage Statistics tab in Settings with Today, Yesterday, Last 7 Days, This Month, Previous Month, a daily list, and a 14-day chart
- CSV export of saved daily usage with exact download, upload, and total byte counts
- Local daily history with configurable retention and confirmed reset actions
- Automatic interface selection with optional manual interface inclusion
- Pause and resume, sleep and wake handling, and Launch at Login requested by default
- A Dock-free menu bar app with a Settings window

## Build and install

Open [NetMeter.xcodeproj](NetMeter.xcodeproj) in Xcode and select the `NetMeter` scheme, or run:

```bash
./scripts/build-release.sh
./scripts/install-local.sh
```

The Release app appears at `dist/NetMeter.app`, which links to a signed build under `~/Library/Application Support/NetMeter/Builds`. The build script keeps the signed bundle outside synced Documents folders because file-provider metadata can invalidate a local code signature. The install script copies it into `/Applications/NetMeter.app` and verifies the signature. If your account cannot write to `/Applications`, run the install script with `sudo`.

Launch NetMeter from Finder → Applications. It has no Dock icon; click its speed label in the menu bar for the dashboard, Settings, pause, reset, and Quit actions. Font Style, Usage Statistics, and About are tabs in Settings.

To run unit tests:

```bash
xcodebuild -project NetMeter.xcodeproj -scheme NetMeter -destination 'platform=macOS' test
```

The same core tests can run through Swift Package Manager with `swift test --scratch-path /tmp/netmeter-build`. The separate scratch path avoids file-provider metadata on test bundles in synced Documents directories.

`project.yml` is the editable XcodeGen source for the checked-in Xcode project. XcodeGen is only needed if you want to regenerate the project; it is not needed to build or run NetMeter.

## How measurement works

The monitor reads 64-bit per-interface byte counters from macOS's native routing system data. It compares consecutive samples and divides the byte difference by the elapsed monotonic time. The first sample is a baseline. Interface changes, counter resets, very short intervals, and long sleep gaps produce a fresh baseline instead of a speed spike. The default selection counts active physical interfaces and uses a VPN tunnel only when no physical interface is available, to reduce double counting.

The menu bar's cumulative metrics are saved between launches. Session totals reset when the app starts or when you choose Reset Session Statistics. Daily usage is saved as JSON at `~/Library/Application Support/NetMeter/usage.json`, normally every 15 samples and on a normal quit or sleep. Preferences and cumulative totals use UserDefaults in `~/Library/Preferences`. The Advanced tab can reveal the usage file in Finder. Statistics → Export CSV saves all retained daily rows with exact byte counts; export does not include unsaved time when the app was not running. Usage counts network-interface traffic while the app is running, including local network traffic; they are not carrier billing totals. A VPN can add encapsulation overhead, and manual selection of both a physical interface and its tunnel can count some traffic twice.

If a saved usage file cannot be decoded, NetMeter preserves it as `usage-corrupt-<identifier>.json` in the same folder and starts a fresh history. Save failures are shown in the app; quitting after a failed save asks whether to keep running or quit without the latest usage history.

## Launch at Login and permissions

NetMeter requests Launch at Login on its first run using `SMAppService.mainApp.register()`. If macOS requires approval, NetMeter presents a prompt that opens System Settings → Login Items; the app cannot bypass that approval. Turning Launch at Login off in General is remembered and will not be undone at the next launch. NetMeter needs no special entitlement or privacy permission for interface counters. The local Release build is ad hoc signed for use on this Mac; distribution to other Macs requires an appropriate Developer ID signature and notarization.

## Project layout

- `Sources/NetMeterCore`: byte-counter reading, rate and usage calculation, formatting, settings, and persistence
- `Sources/NetMeterApp`: menu bar app, monitoring coordinator, Settings, dashboard, and statistics views
- `Tests/NetMeterCoreTests`: unit tests for the non-UI logic
- `Resources/Assets.xcassets`: app icon
- `Packaging/Info.plist`: bundle metadata and `LSUIElement`
- `scripts`: Release build and local installation

## Known limits

- Network-interface counters measure all traffic on the chosen interfaces, not only traffic to the public internet.
- Usage cannot be reconstructed for periods when NetMeter was not running.
- A normal quit and sleep flush pending usage. An unexpected crash can lose up to 15 sample intervals of recent usage.
- Manual inclusion of both VPN and physical interfaces can double count the same packets.
