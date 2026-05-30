# Lanternhouse Playable Demo Script

Use this route for a short pullable/demoable GitHub build check.

## Setup

1. Launch the project from the title screen.
2. Choose `New Game` for a solo demo, or `Host LAN Game` on one machine and `Join LAN Game` on another machine on the same network.
3. Start in the overworld near Brindlewick with the party initialized.

## Five-Minute Demo Route

1. Show the title screen and point out the LAN host/join entries.
2. Start a new game and pause on the overworld HUD.
   - Confirm money, Tonics, danger, exploration percentage, command menu hint, and waypoint labels are readable.
   - Confirm fog/fog-of-war is active, not disabled.
3. Open the command menu with `M` or `Esc`.
   - Show Party, Journal, Items, Settings, Save, and Load entries.
4. Walk to Brindlewick and enter town.
   - Talk to the elder or shop-facing NPC.
   - Confirm the dialog panel remains readable against dark ground.
5. Visit a shop and show item/money readability.
6. Return to the overworld and trigger or load into a basic battle.
   - Show side-view battle background, party sprites, enemy grounding, command selection, and victory flow.
7. If demonstrating LAN, keep the host running while a client joins; verify the host reports a connected peer and both sessions reach overworld play.

## Smoke Tests

Focused checks for this demo state:

```bash
timeout 60 ~/.local/bin/godot4 --headless --audio-driver Dummy --path . --quit
timeout 60 ~/.local/bin/godot4 --headless --audio-driver Dummy --path . scenes/dev/smoke_playable_demo_flow.tscn
timeout 60 ~/.local/bin/godot4 --headless --audio-driver Dummy --path . scenes/dev/smoke_overworld_command_menu.tscn
timeout 60 ~/.local/bin/godot4 --headless --audio-driver Dummy --path . scenes/dev/smoke_first_route_guidance.tscn
timeout 60 ~/.local/bin/godot4 --headless --audio-driver Dummy --path . scenes/dev/smoke_town_doors.tscn
```

For LAN smoke, run the host and client scenes at the same time from two shell processes. The host should print `SMOKE_LAN_HOST_OK`; the client should print `SMOKE_LAN_CLIENT_OK`.
