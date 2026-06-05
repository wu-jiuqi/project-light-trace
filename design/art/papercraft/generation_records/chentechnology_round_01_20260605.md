# Papercraft Generation Record

## Basic Info

| Field | Value |
|---|---|
| Asset IDs | `id0001_character_chentechnology_*` / `id0001_prop_chentechnology_console` / `id0001_fx_chentechnology_*` |
| Manifest | `assets/papercraft/manifests/id0001.json` |
| Date | 2026-06-05 |
| Operator | Codex |
| References | `design/npcs/0001/npc_02_chentechnology.md`, `assets/papercraft/core/references/ref_character_standard.png`, `assets/papercraft/core/materials/*.png` |
| Method | `isolated_asset` / `effect_composite` |

## Art Direction

Chen Technology is kept distinct from Lin Guide by using a restrained lab-worker silhouette instead of an ornate cloak and flower-bell crown. The identity anchors are:

- White layered lab coat and gray inner uniform.
- Brown angular paper hair and silver glasses with occasional glare.
- Hovering stylus, trembling hand, and small touchpad.
- Three active screen fragments as the 32x48-readable "incomplete hint system" anchor.
- Amber/red console alarm state for unsafe-topic interruption.
- Folded book-page paper for the final off-script help gesture.

## Produced Files

| File | Purpose |
|---|---|
| `assets/papercraft/fragments/id0001/characters/chentechnology_idle_down.png` | Default idle with screen anchor and trembling stylus hand |
| `assets/papercraft/fragments/id0001/characters/chentechnology_walk_down.png` | Runtime walk paper puppet |
| `assets/papercraft/fragments/id0001/characters/chentechnology_talk_down.png` | Scripted dialogue pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_explain_system_down.png` | Hint-system explanation pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_caught_off_guard_down.png` | Alarm-triggered hesitation pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_give_paper_down.png` | Folded-paper handoff pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_alarm_response_down.png` | Red-line alarm response pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_between_scripts_down.png` | Non-script silence pose |
| `assets/papercraft/fragments/id0001/characters/chentechnology_shadow_down.png` | Independent soft shadow layer |
| `assets/papercraft/fragments/id0001/props/chentechnology_console.png` | 64x64 touch console prop |
| `assets/papercraft/fragments/id0001/fx/chentechnology_console_alarm_spritesheet.png` | 4-frame console alarm spritesheet |
| `assets/papercraft/fragments/id0001/fx/chentechnology_finger_tremble_spritesheet.png` | 4-frame enlarged finger tremble spritesheet |

## QA

- [x] All character files are `128x192` transparent RGBA PNG.
- [x] Prop is `64x64` transparent RGBA PNG.
- [x] FX sheets are `256x64` and `128x32` transparent RGBA PNG.
- [x] Corner alpha is fully transparent for all produced PNG files.
- [x] Runtime preview checked at `32x48`.
- [x] Manifest updated with `ready` entries.
- [x] `npm run validate:papercraft` passed.

