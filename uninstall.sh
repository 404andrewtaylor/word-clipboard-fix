#!/bin/bash
# Uninstall Word Clipboard Fix for the current user only. No sudo.
set -euo pipefail

LABEL="com.wordclipboardfix.agent"
SUPPORT_DIR="${HOME}/Library/Application Support/WordClipboardFix"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_PATH="${LAUNCH_AGENTS_DIR}/${LABEL}.plist"
BINARY_PATH="${SUPPORT_DIR}/WordClipboardFix"
SOURCE_COPY="${SUPPORT_DIR}/WordClipboardFix.swift"

echo "Uninstalling Word Clipboard Fix…"

# Stop the background helper if it is loaded (safe if missing).
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true

if [[ -f "${PLIST_PATH}" ]]; then
  rm -f "${PLIST_PATH}"
  echo "Removed LaunchAgent: ${PLIST_PATH}"
else
  echo "No LaunchAgent plist found at ${PLIST_PATH}"
fi

if [[ -f "${BINARY_PATH}" ]]; then
  rm -f "${BINARY_PATH}"
  echo "Removed binary: ${BINARY_PATH}"
fi

if [[ -f "${SOURCE_COPY}" ]]; then
  rm -f "${SOURCE_COPY}"
fi

# Remove the support folder only if it is empty afterward.
if [[ -d "${SUPPORT_DIR}" ]]; then
  rmdir "${SUPPORT_DIR}" 2>/dev/null || true
fi

echo ""
echo "Uninstall finished."
echo "Log files under ${HOME}/Library/Logs/WordClipboardFix*.log were left in place."
echo "You can delete those logs yourself if you want."
