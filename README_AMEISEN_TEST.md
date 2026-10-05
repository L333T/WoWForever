# Master Farmer Bot — Ameisen navigation test

A local test copy of **Master Farmer - Grindbot 2.235.0**. Out-of-combat travel goes
through **AmeisenNav** (`_G.AmeisenNav.client`) instead of Sentinel. Version `2.235.0-ameisen`.
It is a plain Sylvanas folder plugin: it does not download anything from GitHub.

## Run it

1. **Start the nav server first:** `scripts\Ameisen\Start-Ameisen.bat`. Leave the window open.
   It listens on `http://127.0.0.1:47110` and forwards to TCP `127.0.0.1:47111`.
2. **Disable Master Farmer - Grindbot** (and its loader plugin `ext_plugin_masterfarmer_beta_test`).
   **Do not run both at the same time.** They drive the same character and the same keys.
3. **Reload Sylvanas scripts.**
4. **AmeisenNav menu:** it should say *Server: connected*.
5. **Master Farmer Bot window, status panel:**
   - **Ameisen:** `Ameisen ready` (green).
     - `server down - start Ameisen\Start-Ameisen.bat` means the server isn't running.
     - `AmeisenNav not loaded` means `scripts\AmeisenNav` is missing or failed to load.
   - **Movement** shows `(Ameisen)` while an Ameisen leg is walking.

## What to test

- **Out-of-combat travel:** start Grind or Quest mode and let it walk between grind nodes and quest waypoints.
- **Walk to a mob:** a target 30+ yd away out of combat is approached on an Ameisen path. Combat itself still uses the local walker (chase, melee, kiting).
- **Stuck recovery:** Ameisen runs its own ladder (jump, repath, detour, back off). The bot waits while Ameisen recovers, and steps in only if the character hasn't moved for 6 s.
- **Destination checks:** grind nodes and mobs Ameisen calls unreachable are skipped.
- **Server down mid-session:** close the Ameisen window. The bot logs `server_down - walking this leg without Ameisen` and carries on with the walker. Restart the server and it picks Ameisen up again within about 30 s.

## Logs

- Session logs: `scripts_log\MASTER_FARMER_BOT_ERRORS\` (separate from the Grindbot's `MASTER_FARMER_ERRORS`).
- Settings: `scripts_data\mfb\` (separate from the Grindbot's `mfg\`). Learned bad terrain: `scripts_data\mfb\hazards_<map>.txt`.
- Grind profiles are shared with the Grindbot (`scripts_data\mfg_profiles\`).
- Useful lines:
  - `ameisen: leg '…' failed: <code>` gives Ameisen's failure codes: `no_path`, `end_off_mesh`, `start_off_mesh`, `map_not_loaded`, `server_down`, `max_stuck_exceeded`, …
  - `ameisen: map A -> B` means the zones and caches were reset on a map change.
  - `ameisen requests N issued` (MEM line) counts nav requests. The limit is 1 per second.

## What differs from the Sentinel build

| Sentinel feature | In this build |
|---|---|
| `find_path_avoid` (route around blacklisted / hazard zones) | Built locally from Ameisen `find_path`: plan the direct path; if it crosses a zone, plan via a detour point beside the zone. |
| Obstacle-service mirror of the zones | None (Ameisen has no obstacle list). The zones reach Ameisen through the detour planner above. |
| `check_path`, `probe_path_ahead`, corridor re-plan | Not available. Ameisen's follower re-paths when the character drifts more than 8 yd off the path, and its stuck ladder handles doorways. |
| Navmesh height of far quest waypoints (`get_all_heights`) | Not available (this Ameisen server has no height query). Far waypoints use the player's height until they're close. A wrong height answered with `end_off_mesh` / `no_path` is retried at the floor heights there. |
| Continent change via `get_continent_id` | `core.get_map_id()` change: zones, caches and learned hazards are reset and reloaded for the new map. |
| "Cancelled" | Ameisen reports `cancelled` when the bot stops or replaces a route. It is ignored, never counted as a failure. |

## 2.235.1-ameisen (after the 11:22 test session)

- **No `/raycast` to Ameisen.** The bot's first short direct move sent `/raycast` (nav log t=3127). The nav server never answered it, and `http_bridge.py` holds one lock for every request, waiting up to 30 s and retrying once. `/health` and everything after it timed out for the rest of the session. The bot still ran on its walker, but Ameisen was gone. The straight-line check before a short direct move now uses the bot's local line test only.
- **No "skip the waypoint underfoot" re-route.** That was a Sentinel workaround. With Ameisen it handed over a fresh `follow_path` every 1-2 s ("walking N points (route" followed by "repath #1 (deviated)" in the nav log), restarting the walk each time. Ameisen's follower reaches its waypoints by itself.

## 2.235.2-ameisen (smooth grind path)

- **The grind path is walked as one long route.** It used to be one move per recorded node (6-7 yd apart). Ameisen reported "arrived" at each node and stopped, and the next move began ~0.3 s later. Now the next 60 nodes in the walking direction go to Ameisen as a single route. On a loop it wraps round; on an open path it turns round at the end. The node counter advances as nodes are passed (within 5 yd), and with 4 nodes left the next route replaces the running one, so it never stops. Fights, looting and the walk back to the path work as before.
- **No look-ahead detours on Ameisen legs.** A Sentinel-era check tested the straight line to the destination while a planned route was being walked. Routes bend, so it kept "finding walls" and swapping Ameisen's route for detour hops (a new route every ~2 s, each flagged "deviated"). Ameisen avoids walls and objects itself.
- **Re-targeting uses Ameisen's seamless `move_to`** (`{ seamless = true }`). Ameisen plans from the current position and the walk carries on without releasing a key. Before, the bot handed over a path planned up to 2.5 s earlier, which Ameisen flagged "deviated".
- **What to look for in the nav log:** long `walking N points (route …)` lines with no `arrived` per node, and far fewer `repath #1 (deviated)`.

## 2.235.3-ameisen (from github.com/L333T/AmeisenNavigation)

**Done in this build:**
- **Smoothed routes.** Every Ameisen path request (`move_to`, seamless re-targets, `find_path` for avoid plans, prefetch and chase paths) now sends `flags = 17`, which is `SMOOTH_CHAIKIN (1) | VALIDATE_MAS (16)` (`Server/src/Protocol.hpp`, `Main.hpp` `HandlePathFlagsAndSendData`).
  - Without flags the server returns Detour's corner-to-corner path. Those sharp corners are where the character clips rocks, trees and walls.
  - Chaikin rounds the corners without overshooting past a waypoint. `VALIDATE_MAS` slides every smoothed point along the navmesh in steps of 25 yd or less, so none leaves walkable ground.
  - The installed 1.8.3.2 server supports these flags (its `config.cfg` already has the smoothing settings). Recorded grind routes are still walked exactly as recorded.

**Found in the repo; not changed (your call):**

| Finding | Effect today | Fix |
|---|---|---|
| The server sends **no reply** to a message type it doesn't handle, or to a packet it rejects as too small (`Main.cpp`: callbacks just `return`). | `http_bridge.py` then waits its full `TCP_TIMEOUT = 30` s, retried once, while holding the one lock every request needs, including `/health`. That is the hang of the 11:39 session. | In the bridge: `TCP_TIMEOUT` of about 5 s; make `/health` check the TCP socket without taking the RPC lock; never send message types the server lacks. |
| The installed server is **1.8.3.2** (the latest binary release). The repo source is **1.8.4.0**. | 1.8.3.2 has no `GET_HEIGHT` and no `CONFIGURE_FILTER`. | Build 1.8.4.0 from source (Visual Studio C++, `AmeisenNavigation.sln`), then add message types 7 and 8 to the bridge. |
| `GET_HEIGHT` (1.8.4.0) is `findNearestPoly` with ±2500 yd vertical reach. | Far quest waypoints have no navmesh height (bridge: "height is not supported"), so they use the player's height until close. | With 1.8.4.0, AmeisenNav's `get_height` works and waypoint heights can come from the mesh again, as they did with Sentinel. |
| Default query filter: `GROUND_STEEP` excluded (good), **water cost only 1.3**, magma/slime 4.0. | Routes cross lakes and rivers readily, and the character swims slowly. | With 1.8.4.0, `CONFIGURE_FILTER` per client: raise the water cost (e.g. 4-6) so the route walks round water. |
| AmeisenNav sends `&state=alliance`, but **the bridge ignores it**. `ClientState` (Normal / Alliance / Horde / Dead) is only set through `CONFIGURE_FILTER`. | No faction or ghost filter is applied. | Needs 1.8.4.0 plus bridge support (same change as the row above). |
