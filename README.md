# smoothscroll

Makes any mouse wheel on macOS scroll as smoothly as a trackpad.

No app, no menu bar icon, no settings window. It runs quietly in the background and uses about 3 MB of RAM.

## Install

```sh
git clone https://github.com/hiritikk/smoothscroll.git
cd smoothscroll && ./install.sh
```

System Settings opens to **Accessibility**. Turn on **smoothscroll**. Done.

It starts by itself every time you log in.

## Adjust

```sh
SPEED=9 SMOOTH=0.15 ./install.sh
```

- `SPEED`: how far each wheel click scrolls. Higher is faster. Default `9`.
- `SMOOTH`: how long each glide lasts, in seconds. Default `0.15`. Try `0.08` for snappy, `0.25` for floaty.

## Good to know

- **Trackpad and Magic Mouse** scrolling isn't touched.
- **Shift, ⌘, Ctrl or Option + scroll** work as normal.
- **Logi Options+:** works fine. Turn off its own "Smooth scrolling" option.
- **Mos, SmoothScroll and similar apps:** turn them off. Two smoothers fight.
- Tested on macOS 26 Tahoe, Apple Silicon, with an MX Master 3S.

## Not working?

1. Check that **smoothscroll** is on in System Settings → Privacy & Security → Accessibility.
2. Look at `~/Library/Logs/smoothscroll.log`. It should say `smoothscroll: running`.
3. Run `DEBUG=1 ./install.sh`, scroll, and check the log again to see every scroll event. Run `./install.sh` to turn logging off.

## How it works

Each wheel click normally jumps the page. smoothscroll catches the click and replays it as a quick glide, one small step per screen frame, that slows down as it finishes.

The speed comes from trackpad maths. A slow trackpad swipe scrolls about 5.3 px per mm of finger travel, and a wheel click moves your finger about 3.14 mm, so a perfect match is about 17 px per click. That felt too fast on a wheel, so the default is about half that.

## Uninstall

```sh
./uninstall.sh
```

## License

MIT
