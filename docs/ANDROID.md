# JS Engine – Android (Mobile Port)

## Install
1. Download `JS-Android.apk` from the **Releases** page.
2. Install it (allow "install unknown apps" for your browser/file manager if Android asks).
3. First launch: the game asks for access to files (needed to create the `.JSEMobile` folder), then copies its files out of the APK ("Preparing game files"). This only happens the first time and after an update.

One APK works on every phone: it contains 32-bit (armeabi-v7a) and 64-bit (arm64-v8a) code, Android 6.0 or newer.

## Where are my files?
`/storage/emulated/0/.JSEMobile/` (hidden folder in the phone's main storage; turn on "show hidden files" in your file manager)

- `assets/` – game files (extracted automatically, do not edit)
- `mods/` – drop your mods here (same folders as the desktop version)
- `crash/` – crash logs

Only the shared storage is used. If you deny the permission the game waits on the permission screen; tap the screen to open it again.

## Controls
Every screen only shows the buttons it uses, with a caption on each one.
- **Intro and title screen:** no buttons, tap anywhere to skip / start.
- **Menus:** D-pad, **A** (OK) and **B** (Back). The Main Menu also has an **Editors** button; Story Mode and Freeplay add **Changers** (X), **Reset** (Y) and, in Freeplay, **Listen** (C); Options, Achievements and Note Offset have **Reset**.
- **Songs:** the screen is split into four lanes (the hitbox). Hold a lane for sustain notes, slide a finger between lanes, use as many fingers as you want. The pause button sits in the right black bar when your phone is wider than 16:9 (Bot Energy goes in the left one); on a 16:9 screen it stays in the top-right corner.
- **Editors:** a grid of keyboard keys (Space, W/A/S/D, arrows, Enter, Esc, Tab, Ctrl/Shift/Alt...) is shown at the bottom right, different for each editor. Ctrl / Shift / Alt are sticky: tap once to hold, again to release. The **Keys** tab hides/shows the grid. The Android Back gesture works as Esc.
- The Android **Back** button/gesture goes back in menus and pauses in songs.
- Opening the pause menu, game over, or any cutscene swaps the lanes for the menu buttons automatically. Hold a finger on a video cutscene to skip it.

## Mobile Options (Options → Mobile Options)
| Option | What it does |
|---|---|
| Pad Opacity | how visible the menu buttons are |
| Hitbox Opacity | how visible the lanes are (0% = invisible but still working) |
| Hitbox Style | Gradient / Flat / Outline |
| Hitbox Position | Full height or Bottom only |
| Hide Hitbox Hints | never draw the lanes (they keep working) |
| Extra Button | Bot Energy button during songs |
| Vibration | short vibration on every press |
| Screen | **Ratio**: normal 16:9, black bars on wide phones. **Full Screen**: no black bars and nothing stretched (a thin strip at the top and bottom is cut; the buttons stay inside the visible part). **Stretched**: distorts the picture to fill the display |

A small hitbox preview is shown in the top-right corner while you change the options.

## Building it yourself
Run the **Android Build** workflow (Actions tab → *Run workflow*). It builds the APK with both CPU types and, if "publish" is ticked, creates the GitHub Release with only the APK attached.

To keep the same signature between releases (so an installed copy can be *updated* instead of reinstalled) add these repository secrets:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`.

Local build (needs Android SDK + NDK r27 and JDK 17 configured with `lime config`):
```
haxelib run lime build android -armv7 -arm64 -release
```

## Known limits (V1)
- The editors are made for mouse and keyboard: touch drives the mouse part and the on-screen key grid covers the shortcuts, but they are still cramped on a small screen.
- Text boxes use the on-screen keyboard.
- Discord Rich Presence and native file dialogs are desktop-only.

## Mods and scripts
- Lua scripts and `runHaxeCode` work as on desktop. Common classes (Math, Std, FlxColor, FlxMath, FlxText, FlxTrail, Note, StrumNote...) are available to Haxe code without `addHaxeLibrary`.
- Android file names are case sensitive. The game now finds a mod file even when its name is written with different upper/lower case than the file on disk (`Images/BF.png` vs `images/bf.png`).

## Keyboard
A USB or Bluetooth keyboard works everywhere (menus, songs, editors). Open **Options > Controls** to set your own keys, the same screen as on a computer: pick an action with the D-pad + A, press the new key on the keyboard, press B to cancel. Keys are saved with the other options.

The FPS / memory counter is larger and kept away from the screen corner so notches and rounded corners do not hide it.
