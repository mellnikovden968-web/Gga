# Noir V6.2 — Compact Event Horizon refresh

This workspace contains a synchronized readable build and upload-ready release set. The current edits reduce UI scale, unify Noir button styling, smooth/trim animation work, optimize the loader, and harden SkinChanger's weapon-audio path without changing firing mechanics.

## Files

- `Noir_Silent_Aim_v6.lua` — full readable source joined from Parts 1–3.
- `Noir_Silent_Aim_Reconstructed.lua` — same joined source without the title header.
- `source_parts/Part1.lua`, `Part2.lua`, `Part3.lua` — editable source chunks.
- `release/Noir_Part1.lua`, `Noir_Part2.lua`, `Noir_Part3.lua` — direct source copies with informational release-marker comments.
- `Noir_Loader_v6.lua` and `release/Noir_Loader_v6.lua` — synchronized loader copies.
- `Noir_Blackhole_SpriteSheet_Compact.jpg` — optimized 8×6 sheet (48 sampled 96×96 frames), used by Part 1, the loader, and the offline preview.
- `Noir_Blackhole_SpriteSheet.jpg` — original sheet retained as the high-quality source asset.
- `Noir_Blackhole_Menu_Preview.html` — offline UI preview using the compact animated sprite and circular image crop.
- `SkinChanger_Module_Extract.lua`, `Emotes_Module_Extract.lua` — readable module extracts, synchronized to their embedded Part 3/Part 2 sources.
- `Reconstructed_Part1.lua`–`Reconstructed_Part3.lua` — compatibility copies of the readable source parts.
- `Release_Manifest.txt` — SHA-256 hashes for the main source, release, module, and asset files.

## Publish / run

1. Back up the existing `Noir_Part1.lua`, `Noir_Part2.lua`, and `Noir_Part3.lua` in `mellnikovden968-web/Gga`.
2. Upload all three matching files from `release/` to the repository root on `main`, preserving those filenames.
3. Run `release/Noir_Loader_v6.lua`.

The loader fetches the three configured raw URLs in parallel, joins the returned bodies, compiles, and launches them. It does **not** inspect or compare part-version strings or marker comments. It still rejects empty/obvious HTTP error pages and reports download/compile/startup errors.

## What changed

- **Smaller interface:** the main `UIScale` is capped at 0.82 on large displays while retaining existing small-screen scaling. The Speed Glitch floater defaults to 64 px; other common floating bind controls default to 8.5% of viewport height, and the generic big button defaults to 168×60 px. Existing explicitly saved bind sizes remain respected within the new safe range.
- **Circular emblem treatment:** the hero mark and restore control use a circular crop instead of a rectangular/square image frame. The preview uses the same compact sprite asset and clips it to a circle.
- **Consistent controls:** the Speed Glitch toggle, floating bind buttons, SkinChanger controls, and general buttons now use the graphite/silver Noir treatment, static metallic strokes, neutral ripples, and short eased press/hover transitions.
- **Smoother / lighter animation:** accretion frames advance at 24 Hz from a 48-frame 8×6 sheet; orbit overlays and the per-frame gradient sweeper were removed. Bind-button feedback is event-driven rather than a continuous RenderStepped ticker. The compact sheet is 69,354 B (59.0% smaller than the original), the loader is 124,233 B (51.9% smaller than the previous release copy), and the offline preview is 232,363 B (87.6% smaller).
- **Broad lag reduction:** target-motion sampling sleeps at 0.2 s while both aim modes are idle and remains at 30 Hz only while active. Skin catalog rendering is lazy-batched (36 cards at a time) with debounced search; the keep-applied worker uses an 8 s interval and event-triggered reapply path. No FPS cap is imposed; these changes are intended to reduce overhead, not to guarantee a particular frame rate.
- **SkinChanger sound safeguard:** the extra `NoirShoot` sound clone / `Tool.Activated` playback hook was removed and legacy clones are cleaned up. Existing native gun sounds remain the default. Skin-specific gun sounds are now opt-in via **Custom gun sounds**, and original `SoundId`, `PlaybackSpeed`, and `Looped` values are restored when the option is disabled. This change affects audio only; it does not call or alter the weapon-fire method. The report of automatic/spam firing could not be reproduced without a Roblox runtime, so no claim is made that game-side firing behavior itself was verified or changed.
- Existing aim, fling, farm, and combat features remain in the build. No Backshot feature or substitute was added. Emotes pagination arrows remain 35×35.
- The earlier Luau ambiguous-call compile correction is retained: the hero-text IIFE is explicitly separated from the preceding black-hole assignment, with guard-owned helper state kept closure-scoped.

## Validation limits

Static checks verify that joined sources and reconstructed copies match Parts 1–3, module extracts match their embedded strings, release parts match their corresponding readable chunks, the loader copies are identical and contain no part-version comparison, sprite dimensions/frame offsets are consistent, and the preview's inline JavaScript parses. No Luau compiler or Roblox/Delta runtime is available here, so there is no in-game compile/run or FPS measurement. The 25–30 FPS goal is an optimization target, not a limit or guarantee.
