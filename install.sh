#!/bin/bash
# Install Word Clipboard Fix for the current user only. No sudo.
set -euo pipefail

LABEL="com.wordclipboardfix.agent"
SUPPORT_DIR="${HOME}/Library/Application Support/WordClipboardFix"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_PATH="${LAUNCH_AGENTS_DIR}/${LABEL}.plist"
BINARY_PATH="${SUPPORT_DIR}/WordClipboardFix"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_FILE="${SOURCE_DIR}/WordClipboardFix.swift"
LOG_DIR="${HOME}/Library/Logs"
STDOUT_LOG="${LOG_DIR}/WordClipboardFix.stdout.log"
STDERR_LOG="${LOG_DIR}/WordClipboardFix.stderr.log"

echo "Installing Word Clipboard Fix for your user account…"

if [[ ! -f "${SOURCE_FILE}" ]]; then
  echo "Could not find WordClipboardFix.swift next to this script."
  echo "Expected: ${SOURCE_FILE}"
  exit 1
fi

mkdir -p "${SUPPORT_DIR}"
mkdir -p "${LAUNCH_AGENTS_DIR}"
mkdir -p "${LOG_DIR}"

if command -v swiftc >/dev/null 2>&1; then
  echo "Compiling WordClipboardFix.swift…"
  swiftc -O -o "${BINARY_PATH}" "${SOURCE_FILE}"
else
  echo "swiftc was not found. Install Xcode Command Line Tools, then run this script again."
  echo "You can install them with: xcode-select --install"
  exit 1
fi

chmod +x "${BINARY_PATH}"

# Stop an older copy of this agent if it is already loaded (safe if missing).
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true

cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${LABEL}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${BINARY_PATH}</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>ProcessType</key>
	<string>Background</string>
	<key>StandardOutPath</key>
	<string>${STDOUT_LOG}</string>
	<key>StandardErrorPath</key>
	<string>${STDERR_LOG}</string>
</dict>
</plist>
EOF

launchctl bootstrap "gui/$(id -u)" "${PLIST_PATH}"

echo ""
echo "Install finished."
echo "The helper should now be running in the background."
echo ""
echo "Quick check (optional):"
echo "  launchctl print gui/\$(id -u)/${LABEL} | head"
echo ""
echo "If that command prints details about ${LABEL}, it is loaded."
