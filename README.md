# ActionCamGamepad

A small WoW Forever (Camelot) addon that provides an action-camera-style
horizontal shoulder offset. The native UI normally applies a temporary
character-centering setting; this addon replaces it only while the Gamepad UI
is active, so the offset remains in effect alongside the native gamepad action
bars and UI.

It does not replace or modify Blizzard gamepad bindings, secure frames, or
action bars.

## Install

Run `./install.sh` from the repo root. It symlinks the `ActionCamGamepad`
folder into the AddOns directory, so edits in the repo show up in-game after a
`/reload`. The default target is
`~/Games/Battle.net/World of Warcraft/_classic_beta_/Interface/AddOns`; set
`WOW_ADDONS_DIR` to use a different one:

```
WOW_ADDONS_DIR="/path/to/Interface/AddOns" ./install.sh
```

Alternatively, copy `ActionCamGamepad` into the AddOns directory by hand.

Enable the addon at character select, then reload or log in. It is enabled by
default.

## Settings

Open **Options → AddOns → ActionCamGamepad** (or type `/acg config`):

- **Enable camera offset** — apply the offsets while the Gamepad UI is active.
- **Horizontal offset** — `-5` (left shoulder) to `5` (right shoulder).
  The default is `1`.
- **Vertical offset** — `0` to `1`. Higher values put the character lower on
  the screen. The default `0` leaves the vertical framing alone.

The client has no direct vertical-offset setting. The vertical offset
turns on the camera's dynamic pitch (`test_cameraDynamicPitch`) and sets its
field-of-view pad, so the camera also tilts a little as you zoom.

## Commands

- `/acg` — show status and help.
- `/acg config` — open the settings panel.
- `/acg on` / `/acg off` — enable or disable the offsets and remember the choice.
- `/acg horizontal <number>` — set the horizontal offset (`/acg offset` also works).
- `/acg vertical <number>` — set the vertical offset.
- `/acg apply` — apply the saved choice again.
