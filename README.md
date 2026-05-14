# SystemWatch

SystemWatch is a native macOS system monitor inspired by Task Manager. It shows live system status, process details, filtering and sorting controls, and safe process termination actions.

## Features

- Live CPU, memory, process count, and uptime overview
- CPU and memory history charts
- Process list with application icons, search, sorting, and filters
- Process detail panel with PID, parent PID, user, state, memory, start time, Bundle ID, and path
- Right-click process actions for ending or force quitting a process
- Safer termination rules for SystemWatch itself and critical system processes
- Menu bar status item with CPU and memory summary
- Refresh rate control: 1 second, 3 seconds, 5 seconds, or paused
- Built-in Chinese and English UI switching
- Terminal diagnostics for troubleshooting process and system sampling

## Screenshots

Place screenshots in `docs/screenshots/` using these filenames:

![Overview](docs/screenshots/overview.png)

![Processes](docs/screenshots/processes.png)

![Menu Bar](docs/screenshots/menu-bar.png)

Suggested captures:

- `overview.png`: Overview page with CPU and memory charts
- `processes.png`: Process list with detail panel and right-click menu
- `menu-bar.png`: Menu bar status popover

## Requirements

- macOS 14 or newer
- Xcode Command Line Tools
- Swift 5.9 compatible toolchain

## Build and Run

```bash
cd "/Users/sep229/Documents/New project"
./script/build_and_run.sh
```

Useful modes:

```bash
./script/build_and_run.sh --foreground
./script/build_and_run.sh --diagnose
./script/build_and_run.sh --diagnose-snapshot
```

`--foreground` runs the app binary directly and prints refresh diagnostics to the terminal.

## Release Package

Create a release build and zip package:

```bash
cd "/Users/sep229/Documents/New project"
./script/package_release.sh
```

The script writes:

- `dist/release/SystemWatch.app`
- `dist/release/SystemWatch-macOS.zip`

The package uses ad-hoc signing for local distribution. For public distribution, use a Developer ID certificate and notarization.

## GitHub Release Checklist

1. Build the release package:

   ```bash
   ./script/package_release.sh
   ```

2. Capture screenshots and place them in `docs/screenshots/`.
3. Commit the updated README, scripts, and screenshots.
4. Create a GitHub release and upload `dist/release/SystemWatch-macOS.zip`.

## Notes

SystemWatch uses macOS-native APIs such as `proc_listpids`, `proc_pidinfo`, `host_processor_info`, and `host_statistics64`. macOS may still refuse termination requests for protected or other-user processes.
