#!/bin/zsh
# Stop smoothscroll and remove it from login.
LABEL=local.smoothscroll
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist" "$HOME/.local/bin/smoothscroll" "$HOME/Library/Logs/smoothscroll.log"
echo "smoothscroll removed."
echo "Optional: remove its entry from System Settings > Privacy & Security > Accessibility (select it, click -)."
