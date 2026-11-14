# Art Standards

Owner: SVTLW-49. Applies to every sprite, tile, icon and effect in the game, placeholder or final.

## Resolution and scale

- Logical resolution: 1280×720 (set in `game/project.godot`). Stretch mode `canvas_items`, aspect `keep`.
- Pixel grid: art is drawn on a 1-pixel base grid, scaled by whole numbers in the game (2× or 3×) so pixels stay sharp.
- Unit sprites: 32×32 base cells. Enemies may be up to 64×64 base (2× cell) for large types. Bosses may be larger, with a note in their ticket.
- Wall and fortress pieces: drawn in 32-pixel-high tiers so they stack cleanly. Wall tile width 40 px at base scale, as in the battlefield scene.
- Icons (HUD and menus): 24×24 base, one consistent style.

## Colour

- A single palette file, `game/ui/palette.tres` (to be added with the final art pass), defines every colour the game uses. Code refers to palette entries, not hard-coded values.
- Dark medieval base: stone and wood browns, desaturated greens for undead, muted red for danger and enemy markers.
- Damage states on the wall use the colour ramp in `battlefield.gd` (`WALL_COLOURS`): intact, cracked, damaged, critical, destroyed. Critical uses the warning red.
- Text on dark backgrounds must have a contrast ratio of at least 4.5:1. Warning and status colours must not be the only way information is shown (see accessibility, SVTLW-89).

## Enemy silhouettes

- Each enemy type is identifiable from its outline alone at 32 px, without colour.
- Roles and counters: pressure (Undead Infantry) has a rounded, hunched outline; swarm (Runner) is narrow and leaning forward; wall_breaker (Armoured Brute) is wide and blocky.
- No two enemy types share a silhouette.

## Animation conventions

- Idle: 4 frames. Attack: 4 frames, with the hit frame at frame 2. Death: 4 frames, final frame held for a short fade.
- Animation names: `idle`, `attack`, `move`, `death`, `impact`, lower case, same across all units.
- Frame rate: 8 fps for idle and move, 12 fps for attack and death. Frames advance on simulation ticks where the animation affects gameplay (attack hit timing), otherwise on real time.

## Effects

- Projectiles: 8×8 base, simple two-tone, readable at speed.
- Damage numbers: system font, 14 pt, colour from the palette by damage type. Off when the setting is off.
- Screen shake is decided by the setting only and never by art.

## UI icons

- One outline style: 2 px base outline, flat fill, no gradients.
- Resource icons: gold, wood, stone, iron, research. Same size and padding.
- Icons never replace text labels in the top bar. They sit beside them.

## Placeholder rules (M1 to M6)

- Placeholders are coloured rectangles that follow the sizes above, so the final art drops in without layout changes.
- A placeholder must still show the silhouette rules: a shape that is wrong for the role is a bug, even as a placeholder.
- The final art pass (SVTLW-86) replaces every placeholder. No placeholder ships in a release candidate (SVTLW-92 onwards).

## Licensing and credits

- Every external asset is listed in `assets/CREDITS.md` at the repo root, with its source URL, author, licence and the date it was added.
- Only assets with licences that allow commercial use in a paid game are used.
- No spend on assets without owner approval.

## Review checklist

- [ ] Sprite is on the base grid and at a whole-number scale.
- [ ] Silhouette matches the role.
- [ ] Animation names follow the convention.
- [ ] Colours come from the palette.
- [ ] Licence and source recorded in CREDITS.md.
