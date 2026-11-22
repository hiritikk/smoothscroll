# smoothscroll

Trackpad-smooth scrolling for any mouse wheel on macOS.

Mouse wheels on a Mac scroll in jumps: every notch teleports the page a few lines. smoothscroll turns each notch into a short glide, so a wheel feels like two fingers on a trackpad. It's one Swift file that runs in the background. There's no app, no menu bar icon and no settings window.

## Install

```sh
git clone https://github.com/hiritikk/smoothscroll.git
cd smoothscroll && ./install.sh
```

The first time, the installer opens **System Settings → Privacy & Security → Accessibility**. Turn on **smoothscroll** and it starts working within about 10 seconds. That's the whole setup. It starts automatically at every login.

You need Apple's command line tools for the Swift compiler. If you don't have them, the installer offers to install them.

## Tuning

Re-run the installer with new values. This doesn't rebuild anything, so the permission stays.

```sh
SPEED=9 SMOOTH=0.15 ./install.sh
```

| Setting | Default | What it does |
|---|---|---|
| `SPEED` | `9` | Pixels scrolled per wheel notch. Higher is faster. |
| `SMOOTH` | `0.15` | How long each glide lasts, in seconds. `0.08` is snappy, `0.25` is floaty. |

Fast spins still scroll further than slow clicks, because macOS's own wheel acceleration is kept.

## How it works

smoothscroll installs an event tap that watches scroll events. For every wheel notch it:

1. Swallows the original event, so the page doesn't jump.
2. Adds the notch's distance (`lines × SPEED`) to a "still to scroll" amount.
3. Once per display frame, posts a small pixel scroll that covers part of the remaining distance. The frame rate comes from the screen under the cursor, so a 60 Hz monitor gets 60 steps a second and a 120 Hz ProMotion display gets 120.

   ```
   step = remaining × (1 − e^(−dt / SMOOTH))
   ```

   That's exponential easing. The page starts fast and settles gently, the way a trackpad scroll does. Because each step uses the real time since the last one (`dt`), a glide feels the same at any refresh rate. The timer only runs while a glide is in progress.

Trackpad and Magic Mouse scrolling is left alone. Those events always carry a gesture or momentum phase, while wheel notches never do. Scrolls with Shift, ⌘, Ctrl or Option held also pass through untouched, so shortcuts like ⌘-scroll zoom and Shift-scroll keep working.

### Why 9 px per notch?

The starting point was to make a wheel move the page about as far as a trackpad does for the same finger movement:

- **Trackpad:** a slow two-finger swipe on a 13" MacBook Pro scrolled about 362 points over about 68 mm of finger travel, so about **5.3 points per mm**.
- **Wheel:** a wheel about 24 mm across with 24 notches per turn moves your fingertip π × 24 ÷ 24 ≈ **3.14 mm per notch**.
- **Result:** 5.3 × 3.14 ≈ **17 px per notch**.

That exact match turned out to feel too fast on a wheel, so the default is about half of it: **9 px**. Your trackpad, wheel and taste will differ, so tune `SPEED` to suit.

## Footprint

About **3 MB of RAM** and **0% CPU** when you're not scrolling. It's a single small process managed by `launchd`, with no app bundle and no UI.

## Works with

- **Logi Options+** (tested with an MX Master 3S): Options+ re-sends wheel events, and smoothscroll handles them. Keep **Smooth scrolling** turned off in Options+ so the two don't fight.
- **Other smoothing apps** (Mos, SmoothScroll, LinearMouse's smoothing): turn them off. Two smoothers stacked feel mushy.

Tested on macOS 26 Tahoe with an Apple Silicon MacBook Pro.

## Troubleshooting

- **Nothing changed:** make sure smoothscroll is turned on in Accessibility. Check the log at `~/Library/Logs/smoothscroll.log`, which should say `smoothscroll: running`.
- **See what it sees:** run `DEBUG=1 ./install.sh` and scroll. Every event is logged, marked `-> smoothed` if smoothscroll took it over. Run `./install.sh` again to turn logging off.
- **Asked for permission again after editing the code:** macOS ties the permission to the binary's signature. If you have a free Apple Development certificate (Xcode creates one when you sign in with your Apple ID), the installer signs with it and the permission survives rebuilds. Without one, re-enable smoothscroll in Accessibility after each rebuild.

## Uninstall

```sh
./uninstall.sh
```

## License

MIT
