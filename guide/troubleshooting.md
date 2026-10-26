# Troubleshooting

## No sound / audio stops working

Volume Mixer requires the **Screen & System Audio Recording** permission to capture and route app audio.

1. Open **System Settings** → **Privacy & Security** → **Screen & System Audio Recording**
2. Find Volume Mixer in the list and enable it
3. **Restart Volume Mixer** — the permission doesn't take effect until relaunch

If you previously denied the permission prompt, you'll need to enable it manually from System Settings.

## App not appearing

Volume Mixer only shows apps that are **actively playing audio**. If an app isn't visible:

- Make sure the app is actually producing sound (start playback)
- Check if the app is hidden. Click **Edit** next to Sound and look for the eye icon next to the app name. A crossed-out eye means the app is being ignored.
- Some apps use helper processes for audio. Try restarting the app.

## App causing audio issues

Some apps don't work well with CoreAudio process taps — particularly audio processors, DAWs, VoIP tools, and apps that do their own low-level audio routing. Symptoms include distorted audio, echo, or audio cutting out.

**Fix:** Click **Edit** next to Sound and click the eye icon to ignore the problematic app. This tears down the process tap entirely for that app, so it goes back to normal macOS audio routing.

Common apps that may need to be ignored:
- Audio Hijack, Loopback, and other Rogue Amoeba apps
- Some VoIP/conferencing tools with custom audio engines
- FaceTime, WhatsApp, and other calling apps (tapping can break echo cancellation, causing volume ducking)

## Volume slider not working

There are two cases.

**Per-app slider.** Some apps use helper processes to play audio rather than the main app process, so the slider you see might be controlling the wrong process. Try restarting the app. If the issue persists, click **Edit** to see if the app appears as a different process name.

**Main volume slider.** For each output device, Volume Mixer picks a volume backend automatically:

- **Hardware**: the device reports a native volume control (most USB DACs, AirPods, built-in speakers).
- **DDC**: an external display that responds to the monitor-control protocol.
- **Software**: Volume Mixer attenuates inside its own audio graph.

Auto-detection gets it right for most devices, but some USB DACs and HDMI/DisplayPort outputs advertise a hardware slider that doesn't actually move the output level. If the main slider doesn't change the volume, click **Edit**, open the device's info button, and turn on **Software volume**. Volume Mixer remembers the choice per device. The toggle is hidden when auto-detect already picked Software, because there's no alternative backend to switch to.

## Audio device not switching automatically

Volume Mixer uses a **device priority list** to decide which output device to use. When a device connects, Volume Mixer only switches to it if it's ranked higher than the current device. When a device disconnects, Volume Mixer falls back to the next highest-priority device that's still connected.

By default, devices are added to the bottom of the list in the order they're first seen. Since your Mac's built-in speakers are always connected, they end up at the top (highest priority), so Volume Mixer won't auto-switch to headphones, external speakers, or other devices when they connect.

**This is a one-time setup.** Once you set your preferred order, it's saved permanently and works across app restarts.

**How to reorder:**

1. Click **Edit** next to Sound in the menu bar dropdown
2. **Drag** devices to reorder, or **click the priority number** and type a new position
3. Click **Done** — your order is saved

The device at position 1 has the highest priority. Volume Mixer will always prefer the highest-priority device that's currently connected.

Input and output devices have **separate priority lists**. To reorder inputs, open **Input** first, then click **Edit**.

> **Note:** For AirPods, taking them out of your ears and putting them back in (without the case) is handled by macOS Automatic Ear Detection. Volume Mixer doesn't interfere with that.

## Input devices not showing

Volume Mixer's input device monitoring requires separate microphone permission.

1. Open **System Settings** → **Privacy & Security** → **Microphone**
2. Find Volume Mixer and enable it
3. Restart Volume Mixer

## Media keys don't control Volume Mixer

Media keys (F10 / F11 / F12) are opt-in and require the **Accessibility** permission so Volume Mixer can observe the keystrokes.

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Enable Volume Mixer in the list. If it's already on, toggle it off and back on to clear a rare permission-bootstrap race.
3. Open Volume Mixer Settings → **Shortcuts**, turn on **Media Keys Control**, and pick a **HUD Style**

If the keys still don't work right after launch, a WindowServer handoff can briefly swallow the first keypress. Try once more; subsequent presses are reliable.

## Volume HUD not appearing

- Check Settings → **Shortcuts** → **HUD Style**.
- Switch HUD styles if one isn't rendering. Tahoe uses macOS 26's system HUD look; Classic matches the older translucent rounded-rect style.

## EQ not applying / sounds the same

- Open the app's **⋯** button, then **Equalizer**. Check that the **toggle switch** in the EQ panel header is on.
- The default preset is **Flat** (all bands at 0 dB), which makes no audible changes. Select a different preset or adjust the bands manually.
- EQ is **per-app**, not per-device. Make sure you're adjusting the EQ for the correct app.
- If using AutoEQ headphone correction, that's separate from the 10-band EQ. Verify a profile is assigned to the correct device via the wand icon

## Audio quality sounds degraded

- Check if volume boost is set above 1x — high boost levels can cause clipping on loud passages
- If using EQ, large boosts across multiple bands can push levels too high. Try pulling bands down instead of boosting others up.
- AutoEQ profiles include a preamp gain reduction to prevent clipping; manual EQ does not, so be mindful of total gain
- Try resetting the app to defaults: `open "volumemixer://reset"` in Terminal
