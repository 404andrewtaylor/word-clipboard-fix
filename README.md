# Word Clipboard Fix

When you copy text from Microsoft Word on a Mac, paste sometimes inserts a **picture** of the text instead of real text. That makes editing hard in other apps.

This small helper watches the Mac clipboard (the place copy/paste stores things). If a copy looks like Word text that also includes a picture fallback, it removes only those picture types. Plain text, RTF, and HTML stay. Screenshots, real image copies, and copies from other apps are left alone.

## What it does

- Runs quietly in the background after you log in
- Detects Word text copies that also carry image or PDF clipboard types
- Removes those image/PDF types so paste prefers text

## What it does not do

- Does not change Microsoft Word itself
- Does not touch screenshots or normal image copies
- Does not change copies from apps other than Word
- Does not need your password or administrator access for a normal install

## Requirements

- A Mac
- Xcode Command Line Tools (so the Mac can compile the helper). The install steps explain how to get them if needed.

## Install

Follow the step-by-step guide:

**[docs/install.md](docs/install.md)** — click-by-click Terminal commands, how to check it is running, and how to uninstall.

Short version if you already have this project folder:

1. Open **Terminal**.
2. Go to the project folder.
3. Run `./install.sh`.

## Check that it is running

In Terminal:

```bash
launchctl print "gui/$(id -u)/com.wordclipboardfix.agent" | head
```

If you see details about `com.wordclipboardfix.agent`, the helper is loaded.

Optional: copy some text in Word that used to paste as a picture, then paste into another app. You should get editable text.

## Uninstall

```bash
./uninstall.sh
```

Details are in [docs/install.md](docs/install.md).

## How it works (brief)

A **LaunchAgent** is a Mac setting that starts a small program when you log in. That program checks the clipboard often. When Word puts both text and a picture on the clipboard, the helper keeps the text formats and drops the picture formats. It ignores its own clipboard writes so it does not loop.

## License

MIT. See [LICENSE](LICENSE).
