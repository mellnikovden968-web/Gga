# Noir V6 — Event Horizon full update

This is the synchronized release built from the reconstructed uploaded Parts 1–3. The source, generated parts, and loader are included together; this supersedes the earlier loader-only draft.

## Files

- `Noir_Silent_Aim_v6.lua` — readable, joined source. The source chunks are also under `source_parts/` for editing.
- `release/Noir_Part1.lua`, `release/Noir_Part2.lua`, `release/Noir_Part3.lua` — generated release chunks with their original filenames and V6 release markers.
- `release/Noir_Loader_v6.lua` — loader using the existing GitHub raw URLs. It checks each part's V6 marker before compiling, preventing accidental mixed-version releases.
- `Noir_Blackhole_Menu_Preview.html` — offline, self-contained UI concept preview with an animated event-horizon restore sigil and black-hole collapse/restore transitions.
- `Noir_Blackhole_SpriteSheet.jpg` — the embedded 96-frame accretion-material sheet used by the Main UI and loader; the scripts also carry their own embedded copy.
- `Emotes_Module_Extract.lua` — patched readable Emotes module extracted from Part 2 for review.
- `Release_Manifest.txt` — SHA-256 checksums for the release files.

## Install / publish

1. Back up the current three `Noir_Part1.lua` / `Noir_Part2.lua` / `Noir_Part3.lua` files in the `mellnikovden968-web/Gga` repository.
2. Upload all three files from `release/` to the repository root on the `main` branch, keeping those exact filenames. The loader intentionally refuses stale or mixed chunks.
3. Run `release/Noir_Loader_v6.lua`. If it reports “Build mismatch,” verify all three raw files were replaced and retry after GitHub's raw-content cache updates.

## Update scope

- Main UI restyled in monochrome graphite/silver with an animated black-hole emblem on the N restore button, event-horizon collapse/restore motion, and an always-visible idle pulse/accretion animation.
- Better ODH Speed Glitch is integrated into Main with sideways-only mode, speed 10–1000 (default 150), floating draggable toggle size 40–150 (default 80), the four source emotes, custom emote ID, and one-second UI recovery.
- Emotes pagination arrows are 35×35; its fallback theme is monochrome.
- Notifications are redesigned as timed, animated Noir event-log toasts.
- Existing aim, fling, farming, and combat code was not intentionally changed; no Backshot feature or substitute was added.
- The existing gradient update cadence and gameplay loops were not changed for an FPS cap. UI animation work is time-based and the black-hole sheet is stepped at about 8.3 FPS. 25–30 FPS remains an optimization target, **not a guarantee**; no FPS cap is imposed.

## Validation limits

The parts were rebuilt from the reconstructed source chunks, checked for synchronized markers and deterministic light-obfuscation, and the HTML preview's inline JavaScript passed `node --check`. No Roblox/Luau runtime or executor test was available, so behavior still needs in-game verification. The loader's release-marker check is static; it does not replace a runtime test.
