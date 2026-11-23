# Contributing

Thanks for wanting to help. Bug reports, fixes and ideas are all welcome.

If something's broken, open an issue and include your mouse, your mouse software and your macOS version. The bug report form asks for these. A debug log helps a lot, since different mice and drivers send scroll events in surprisingly different ways.

Questions and ideas are welcome as issues too, and so are settings that work well for your mouse.

## Making changes

Everything lives in `smoothscroll.swift`, and `install.sh` builds it. After editing, run `./install.sh` to rebuild and restart it, then scroll around to check it still feels right. Try it with both a mouse wheel and the trackpad, because the trackpad should stay exactly as it was.

I'd like smoothscroll to stay small and light, so I'll probably say no to changes that add a UI or a lot of new settings. If you're planning something big, open an issue first so we can talk it through before you spend time on it.

By contributing, you agree that your work is released under the MIT license.
