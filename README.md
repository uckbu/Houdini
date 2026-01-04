# Houdini 🎩

A minimal macOS menu bar app that hides your mouse cursor with a global hotkey. Especially useful for presentations, screen recordings, gaming, or any situation where you want the cursor out of the way.

I built this app after a personal frustration with my cursor doubling up in certain applications. In my case, it was the Mac version of tModLoader, which consistently had a second cursor, offset just enough to make it frustrating to use.

## Features

- **Global Hotkey:** Toggle cursor visibility with ⌘⌥H (customizable)
- **Menu Bar App:** Lives in your menu bar, runs in background
- **Instant Toggle:** Cursor stays hidden even when switching apps
- **No Dependencies:** Pure Swift, uses private macOS APIs for reliable hiding

## Installation

### Download Pre-built App
1. Go to [Releases](../../releases)
2. Download `Houdini.app.zip`
3. Unzip and drag `Houdini.app` to your Applications folder
4. On first launch, grant Accessibility permissions when prompted

### Build from Source
```bash
git clone https://github.com/uckbu/Houdini.git
cd Houdini
swift build -c release
```

To create the app bundle:
```bash
mkdir -p Houdini.app/Contents/MacOS
cp .build/release/Houdini Houdini.app/Contents/MacOS/
cp Info.plist Houdini.app/Contents/
```

## Usage

1. Launch Houdini
2. Press **⌘⌥H** to hide the cursor
3. Press **⌘⌥H** again to show the cursor
4. Customize the hotkey in the app window

## Requirements

- macOS 11.0 (Big Sur) or later
- Accessibility permissions (for global hotkey and cursor control)



## License

MIT License - see [LICENSE](LICENSE) for details.
