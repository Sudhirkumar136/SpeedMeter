# NetMeter

NetMeter is a native macOS menu bar app that shows current network download and upload speed and tracks local usage. It uses SwiftUI, AppKit, Apple's Charts and ServiceManagement frameworks, and system interface counters. It does not run internet speed tests or use third-party runtime packages.

## Requirements

- macOS 15 or later
- Xcode 16 or later for building

## Features

- Download and upload speeds updated every 0.5, 1, 2, or 5 seconds (1 second by default)
- Five available menu bar metrics; show up to three at once and drag to change their order
- A compact, fixed-width menu bar readout on a transparent background (for example, `↓   2.4M ↑ 312.5K Σ   1.4G`); in Auto mode, K/M/G abbreviate binary byte units
- Auto, KB/s, MB/s, Mbps, and Gbps speed units; 0 to 2 decimal places; symbol and unit display options
- Session and daily download, upload, and total usage
- Usage Statistics tab in Settings with Today, Yesterday, Last 7 Days, This Month, Previous Month, a daily list, and a 14-day chart
- Local daily history with configurable retention and confirmed reset actions
- Automatic interface selection with optional manual interface inclusion
- Pause and resume, sleep and wake handling, and Launch at Login
- A Dock-free menu bar app with a Settings window

## Build and install

Open [NetMeter.xcodeproj](NetMeter.xcodeproj) in Xcode and select the `NetMeter` scheme, or run:

```bash
./scripts/build-release.sh
./scripts/install-local.sh
```

The Release app appears at `dist/NetMeter.app`, which links to a signed build under `~/Library/Application Support/NetMeter/Builds`. The build script keeps the signed bundle outside synced Documents folders because file-provider metadata can invalidate a local code signature. The install script copies it into `/Applications/NetMeter.app` and verifies the signature. If your account cannot write to `/Applications`, run the install script with `sudo`.

Launch NetMeter from Finder → Applications. It has no Dock icon; click its speed label in the menu bar for the dashboard, Settings, statistics, pause, reset, About, and Quit actions.

To run unit tests:

```bash
xcodebuild -project NetMeter.xcodeproj -scheme NetMeter -destination 'platform=macOS' test
```

The same core tests can run through Swift Package Manager with `swift test --scratch-path /tmp/netmeter-build`. The separate scratch path avoids file-provider metadata on test bundles in synced Documents directories.

`project.yml` is the editable XcodeGen source for the checked-in Xcode project. XcodeGen is only needed if you want to regenerate the project; it is not needed to build or run NetMeter.

## How measurement works

The monitor reads 64-bit per-interface byte counters from macOS's native routing system data. It compares consecutive samples and divides the byte difference by the elapsed monotonic time. The first sample is a baseline. Interface changes, counter resets, very short intervals, and long sleep gaps produce a fresh baseline instead of a speed spike. The default selection counts active physical interfaces and uses a VPN tunnel only when no physical interface is available, to reduce double counting.

The menu bar's cumulative metrics are saved between launches. Session totals reset when the app starts or when you choose Reset Session Statistics. Daily usage is saved as JSON at `~/Library/Application Support/NetMeter/usage.json`, normally every 15 samples and on a normal quit or sleep. Preferences and cumulative totals use UserDefaults. Usage counts network-interface traffic while the app is running, including local network traffic; they are not carrier billing totals. A VPN can add encapsulation overhead, and manual selection of both a physical interface and its tunnel can count some traffic twice.

## Launch at Login and permissions

The General setting calls `SMAppService.mainApp.register()` or `.unregister()` immediately. macOS may require the user to approve the login item in System Settings. NetMeter needs no special entitlement or privacy permission for interface counters. The local Release build is ad hoc signed for use on this Mac; distribution to other Macs requires an appropriate Developer ID signature and notarization.

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
