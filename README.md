# smoothscroll

I use an MX Master 3S with my MacBook, and scrolling with it always felt jumpy next to the trackpad. smoothscroll fixes that. Each click of the wheel turns into a short glide, so the page moves the way it does under two fingers.

It's a single Swift file that runs in the background through launchd. There's nothing to open and nothing sitting in your menu bar. It uses about 3 MB of memory and only does any work while you're scrolling.

## Install

```sh
git clone https://github.com/hiritikk/smoothscroll.git
cd smoothscroll && ./install.sh
```

The installer opens the Accessibility page in System Settings. Switch smoothscroll on there and give it a few seconds. From then on it starts by itself whenever you log in.

## Adjusting it

If scrolling feels too fast or too slow, run the installer again with your own numbers:

```sh
SPEED=9 SMOOTH=0.15 ./install.sh
```

`SPEED` is how far one click of the wheel scrolls, and it's 9 by default. `SMOOTH` is how long each glide lasts in seconds, 0.15 by default. Anything from about 0.08 to 0.25 feels reasonable, depending on how floaty you like it.

## Things to know

Your trackpad keeps working exactly as before. If you hold Shift, ⌘, Ctrl or Option while scrolling, you get normal scrolling, so shortcuts like sideways scrolling and zooming still work.

If you use Logi Options+, turn off its "Smooth scrolling" setting. Do the same for Mos, SmoothScroll or any other scrolling app, because two of them running at once feels mushy.

I've tested it on macOS 26 Tahoe on an M1 MacBook Pro with an MX Master 3S.

## If it doesn't work

First check that smoothscroll is switched on under System Settings → Privacy & Security → Accessibility. Then open `~/Library/Logs/smoothscroll.log`. It should say `smoothscroll: running`.

To see what it's seeing, run `DEBUG=1 ./install.sh` and scroll a bit. Every scroll event gets written to the log. Run `./install.sh` again to switch the logging off.

## How it works

macOS treats each wheel click as one jump. smoothscroll catches the click before it reaches the app and sends it on as lots of tiny scrolls, one per screen refresh, that start quick and then slow down.

The default speed started from some trackpad math. A slow swipe on my trackpad scrolled about 5.3 pixels per millimetre of finger movement, and one wheel click moves your finger about 3 mm, which works out to roughly 17 pixels per click. That felt too fast in practice, so I dropped it to 9.

## Uninstall

```sh
./uninstall.sh
```

## License

MIT
