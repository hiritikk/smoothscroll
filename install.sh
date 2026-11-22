#!/bin/zsh
# Build smoothscroll into ~/.local/bin and run it at login via launchd.
# Tune by editing SPEED / SMOOTH below and re-running this script.
set -euo pipefail

SPEED=${SPEED:-9}       # px per wheel notch (17 matches trackpad gain exactly; 9 feels better in practice)
SMOOTH=${SMOOTH:-0.15}  # glide time constant in seconds (higher = longer glide)

LABEL=local.smoothscroll
BIN="$HOME/.local/bin/smoothscroll"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/smoothscroll.log"
DIR=${0:A:h}

if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "The Swift compiler is missing. Install Apple's command line tools, then re-run:"
  echo "  xcode-select --install"
  xcode-select --install 2>/dev/null || true
  exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
# Signing with a real certificate (e.g. the free "Apple Development" one Xcode creates)
# keeps the Accessibility grant across rebuilds. Override with CODESIGN_ID=<hash or name>.
# Without one we fall back to ad-hoc signing, which must be re-granted after each rebuild.
CODESIGN_ID=${CODESIGN_ID:-$(security find-identity -v -p codesigning 2>/dev/null \
  | grep -v CSSMERR | awk '/"(Apple Development|Developer ID Application)/ { print $2; exit }')}

# Only rebuild when the source changed.
if [[ ! -x "$BIN" || "$DIR/smoothscroll.swift" -nt "$BIN" ]]; then
  swiftc -O "$DIR/smoothscroll.swift" -o "$BIN"
  if [[ -n "$CODESIGN_ID" ]] && codesign -s "$CODESIGN_ID" -f -i "$LABEL" "$BIN" 2>/dev/null; then
    echo "Rebuilt $BIN (signed with your development certificate)"
  else
    codesign -s - -f -i "$LABEL" "$BIN"
    echo "Rebuilt $BIN (ad-hoc signed: re-enable it in Privacy & Security > Accessibility)"
  fi
fi

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN</string>
    <string>--speed</string><string>$SPEED</string>
    <string>--smooth</string><string>$SMOOTH</string>
    ${DEBUG:+<string>--debug</string>}
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ProcessType</key><string>Interactive</string>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/smoothscroll.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/smoothscroll.log</string>
</dict>
</plist>
EOF

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
: > "$LOG"
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed $BIN (speed $SPEED, smooth $SMOOTH); log: $LOG"

sleep 2
if grep -q "no Accessibility permission" "$LOG"; then
  echo
  echo "One last step: turn on 'smoothscroll' in the Accessibility list that just opened."
  echo "If it isn't listed, click +, press Cmd-Shift-G and paste: $BIN"
  echo "It starts smoothing within ~10 seconds, no restart needed."
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
else
  echo "Running. Scroll away."
fi
