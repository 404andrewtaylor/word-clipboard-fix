# Install Word Clipboard Fix (Mac)

This guide assumes you already have the project folder on your Mac (for example after downloading or cloning it).

You will use **Terminal**. Terminal is the Mac app where you paste commands. You do not need to be a developer.

---

## 1. Open Terminal

1. Press **Command (⌘) + Space** to open Spotlight.
2. Type `Terminal`.
3. Press **Return**.

A window with a text prompt appears. That is Terminal.

---

## 2. Go to the project folder

In Terminal, type `cd` (that means “change directory”), a space, then drag the project folder from Finder into the Terminal window. Press **Return**.

Example shape (your folder path will differ):

```bash
cd /path/to/word-clipboard-fix
```

Check you are in the right place:

```bash
ls
```

You should see files such as `install.sh`, `WordClipboardFix.swift`, and `README.md`.

---

## 3. Install the compiler tools (if needed)

The install script needs `swiftc`, Apple’s Swift compiler. A **compiler** turns the source file into a program your Mac can run.

Check:

```bash
xcode-select -p
```

- If you see a path, you likely already have the tools. Continue to step 4.
- If you see an error, install the tools:

```bash
xcode-select --install
```

A system window may ask you to confirm. Agree and wait until the install finishes, then come back to Terminal.

---

## 4. Run the install script

Make the script runnable, then run it:

```bash
chmod +x install.sh uninstall.sh
./install.sh
```

### What success looks like

You should see messages like:

- `Compiling WordClipboardFix.swift…`
- `Install finished.`
- `The helper should now be running in the background.`

The script installs only for **your** user account. It does not use `sudo` and does not ask for an administrator password.

It places:

- The program under `~/Library/Application Support/WordClipboardFix/`
- A LaunchAgent file under `~/Library/LaunchAgents/com.wordclipboardfix.agent.plist`

(`~` means your home folder.)

---

## 5. Check that it is running

Paste this into Terminal and press **Return**:

```bash
launchctl print "gui/$(id -u)/com.wordclipboardfix.agent" | head
```

### What success looks like

You should see output that mentions `com.wordclipboardfix.agent` and state information. That means MacOS has loaded the helper.

If the command says it could not find the service, run `./install.sh` again and check for error messages.

---

## 6. Try a real copy from Word

1. Open Microsoft Word.
2. Copy some text that used to paste as a picture.
3. Paste into another app (Notes, Mail, a browser, and so on).

You should get editable text, not a picture of the text.

Screenshots and image copies from other apps should still paste as images.

---

## Uninstall

Open Terminal, go to the project folder (same as step 2), then run:

```bash
./uninstall.sh
```

### What success looks like

You should see `Uninstall finished.` The background helper stops. The LaunchAgent file and program copy are removed.

Log files under `~/Library/Logs/` may remain. You can delete files named like `WordClipboardFix*.log` yourself if you want.

---

## Troubleshooting

**“swiftc was not found”**  
Run `xcode-select --install`, wait for it to finish, then run `./install.sh` again.

**Permission or “Operation not permitted”**  
Make sure you are not using `sudo`. This install is user-level only. Quit and reopen Terminal, then try again.

**Still pasting as a picture**  
Confirm the helper is loaded (step 5). Copy again from Word after install. Some apps prefer images for other reasons; try pasting into Notes first as a simple test.
