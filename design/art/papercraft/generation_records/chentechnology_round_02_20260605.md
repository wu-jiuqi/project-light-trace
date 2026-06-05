# Papercraft Generation Record

## Basic Info

| Field | Value |
|---|---|
| Asset IDs | `id0001_character_chentechnology_*` / `id0001_prop_chentechnology_console` / `id0001_fx_chentechnology_*` |
| Manifest | `assets/papercraft/manifests/id0001.json` |
| Date | 2026-06-05 |
| Operator | Codex |
| Style Reference | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_02/linguide_r02_idle_down.png` |
| Character Reference | `design/npcs/0001/npc_02_chentechnology.md` |
| Method | `isolated_asset` / `effect_composite` |

## Redesign Reason

Round 01 was readable but too close to a plain lab worker. Round 02 follows the formal Lin Guide asset's production language while avoiding its concrete motifs.

Inherited from the style reference:

- Thick irregular off-white standee outline.
- Dense layered paper surfaces.
- Large dark outer silhouette around a pale central body.
- Head/shoulder structure that reads as a character-specific crown or apparatus.
- Small dangling paper/metal elements and visible craft fasteners.

Explicitly avoided:

- Bellflower or floral head shapes.
- Key charms.
- Lin Guide's handheld datapad.
- Training-uniform identity marks.
- Any readable text or copied ornament layout.

Chen-specific replacements:

- Touch-console halo above and behind the head.
- Three incomplete hint-system screens.
- Cable arcs and brass rivets.
- Dangling terminal cards.
- Chest-mounted touch console.
- Silver glasses/glare.
- Amber/red warning lamp.
- Folded blank paper for the off-script help gesture.

## Produced Files

| File | Purpose |
|---|---|
| `assets/papercraft/fragments/id0001/characters/chentechnology_idle_down.png` | Ornate idle with console halo and chest touch console |
| `assets/papercraft/fragments/id0001/characters/chentechnology_walk_down.png` | Simplified runtime walk pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_talk_down.png` | Scripted dialogue pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_explain_system_down.png` | Stylus explanation pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_caught_off_guard_down.png` | Alarm interruption pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_give_paper_down.png` | Folded-paper handoff pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_alarm_response_down.png` | Red-line warning response pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_between_scripts_down.png` | Off-script silent pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_shadow_down.png` | Independent soft shadow layer |
| `assets/papercraft/fragments/id0001/props/chentechnology_console.png` | 64x64 touch console prop |
| `assets/papercraft/fragments/id0001/fx/chentechnology_console_alarm_spritesheet.png` | 4-frame console alarm spritesheet |
| `assets/papercraft/fragments/id0001/fx/chentechnology_finger_tremble_spritesheet.png` | 4-frame enlarged finger tremble spritesheet |

## QA

- [x] Style reference used for silhouette density and paper-craft treatment only.
- [x] Lin Guide-specific motifs were not reused.
- [x] Character elements are sourced from Chen Technology's design: console, partial screens, warning alarm, glasses, trembling hand, folded paper.
- [x] All character files are `128x192` transparent RGBA PNG.
- [x] Runtime preview checked at `32x48`.
- [x] Manifest descriptions updated.
- [x] `npm run validate:papercraft` passed.

