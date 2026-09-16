# MouseMover

A tiny native macOS **menu bar app** that keeps your Mac's screen awake and
unlocked, so a long-running session is never interrupted by the display going to
sleep or the lock screen kicking in.

## Why it exists

It started with long Claude Code sessions. When you leave an agent working on its
own for a while, macOS eventually dims the display, starts the screen saver, and
locks the screen. That interrupts what you are watching and, depending on your
setup, can get in the way of a session you wanted to run unattended. MouseMover
keeps the machine awake so the work keeps running and stays on screen. Every
interval it also draws a quick, visible circle with the cursor and injects a real
mouse-move event, so at a glance you can see it is doing its job.

Keeping status apps like Teams or Slack showing "active" was never the point. It
is only a side effect of the same mechanism (see below).

No Python, no Homebrew packages, no dependencies. Just Swift compiled locally
with the tools that ship with macOS.

![icon](icon.svg)

## What it does

Two independent layers:

| Layer | Needs permission? | Effect |
| --- | --- | --- |
| Keep the display awake + move the cursor (visible circle) | No | The screen does not sleep or lock on you, and you can see it working |
| Register as real user input | **Yes, Accessibility** | Also resets the system input idle timer, for stricter lock or idle policies |

The visible movement uses `CGWarpMouseCursorPosition`, which needs no permission
and is enough on most setups to stop the display sleeping and locking. If your
Mac is configured to lock based on real input activity, granting
**Accessibility** lets the injected event reset that timer as well.

As a side effect, the injected input also keeps idle-aware apps such as Teams or
Slack showing you as active. That is not the goal, just something it happens to
do. If that is what you are after, note that it is the one case where you have to
grant Accessibility (see Install).

## Requirements

- macOS 12 or later
- Xcode **Command Line Tools** (for `swiftc`). If you do not have them:
  `xcode-select --install`

## Install

```bash
git clone https://github.com/Raulster24/mousemover.git
cd mousemover
./install.sh
```

`install.sh` builds the app, copies it to `/Applications`, sets it to launch at
login, and opens the Accessibility settings pane. The screen-stays-awake layer
already works at this point, with no permission. Only if you are using it for
"active" status in Teams, Slack, or similar idle-aware apps, which is not the
primary intent, do you have to grant Accessibility:

1. **System Settings, Privacy & Security, Accessibility, turn ON "MouseMover"**
2. Reload it so the permission takes effect:
   ```bash
   launchctl kickstart -k gui/$(id -u)/local.rahul.mousemover
   ```

## Usage

Click the coffee-cup icon (☕︎) in the menu bar:

- **Start / Stop** (⌘S)
- **Move now (test)** (⌘M), fire a circle immediately to confirm it works
- **Move every**, 15 / 30 / 60 / 120 / 300 seconds (default 60)
- **Quit** (⌘Q)

The default interval is 60s, which comfortably stays ahead of typical
display-sleep and lock timers. If you set it very high (300s), the screen could
briefly dim or lock between nudges, depending on your Energy Saver settings.

## Uninstall

```bash
./uninstall.sh
```

Removes the app, the login item, and the Accessibility entry.

## Note on permissions (important)

This app is **ad-hoc signed** (no paid Apple Developer account). macOS ties the
Accessibility grant to the app's exact signature, so:

- You grant Accessibility **once per machine**.
- If you rebuild or reinstall (for example `git pull` then `./install.sh`), the
  signature changes and the grant resets. Just turn the toggle on again.
  `install.sh` already resets the stale grant for you so the prompt is clean.

## How it verifies itself

macOS keeps two idle timers: a hardware one (IOKit) and a CoreGraphics event
timer. Warping the cursor keeps the display awake and resets the hardware timer;
the injected event is what resets the CoreGraphics timer, which is what governs
the screen saver and input-based lock. If the screen still locks on you,
Accessibility is not effective. Re-grant it as above.

## License

MIT, do whatever you want.
