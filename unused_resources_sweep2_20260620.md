# 溯光计划 — 第二轮未使用资源扫描报告（修正版）

> 扫描日期：2026-06-20  
> 扫描版本：V3（DirAccess 运行时加载感知）  
> 第一轮已清理：原报告 105 文件（约 212 MB），全部已删除  
> **修正**：V2 误将 NPC 大图（_l.png）标记为未使用，实际通过 `DirAccess.get_files_at()` 由对话系统运行时加载

---

## 扫描统计

| 指标 | 数值 |
|------|------|
| 资源文件总数 | 1,352 |
| 静态引用路径 (tscn/gd/tres) | 463 |
| 运行时加载 (DirAccess) | 974 |
| 未使用文件数 | **67** |
| 可释放空间 | **~154.0 MB** |

---

## 未使用资源清单

### 一、开发/参考素材（13 文件，27.2 MB）

#### 1.1 `core/materials/` — 纸雕材质纹理参考（6 文件，8.3 MB）
| 文件 | 大小 |
|------|------|
| foil.png | 1,745 KB |
| fiber_paper.png | 1,499 KB |
| kraft.png | 1,463 KB |
| gray_card.png | 1,208 KB |
| book_page.png | 1,196 KB |
| tracing_paper.png | 1,173 KB |

#### 1.2 `core/references/` — AI 生成参考图（7 文件，18.9 MB）
| 文件 | 大小 |
|------|------|
| ref_inn_facade.png | 3,387 KB |
| ref_material_board.png | 3,314 KB |
| ref_awakening_collage.png | 3,172 KB |
| ref_star_map.png | 3,089 KB |
| ref_character_standard.png | 2,853 KB |
| ref_street_modules.png | 2,742 KB |
| ref_ui_components.png | 401 KB |

> 两组均为 papercraft 技能的 AI 参考素材，仅在生成阶段使用，不影响运行时。

---

### 二、UI 预览/临时文件（6 文件，5.0 MB）

| 目录 | 文件 | 大小 | 说明 |
|------|------|------|------|
| core/ui/banner/ | 微信图片_20260615171535_21_30_s.png | 8 KB | 微信临时图片 |
| core/ui/dialogue_box/ | name_plate.png | 39 KB | 未引用 |
| core/ui/dialogue_box/ | continue_arrow.png | 15 KB | 未引用 |
| core/ui/extracted_buttons/ | preview_menu_button_states.png | 2,055 KB | 开发预览 |
| core/ui/extracted_buttons/ | preview_extracted_buttons.png | 1,424 KB | 开发预览 |
| core/ui/extracted_menu_buttons/ | preview_extracted_menu_buttons.png | 1,429 KB | 开发预览 |

---

### 三、id0001/environment2/ 孤立资产（48 文件，125.5 MB）

> ⚠️ 最大发现：这些命名的 prop/fx/env 文件均未被任何场景或脚本静态引用，也未通过 DirAccess 动态加载。

| 类别 | 文件数 | 大小 |
|------|--------|------|
| Props（道具） | 17 | ~47 MB |
| Environments（环境） | 14 | ~41 MB |
| FX（特效） | 9 | ~26 MB |
| UI / Misc | 8 | ~17 MB |

**详细清单：**

| 文件 | 大小 | 类别 |
|------|------|------|
| 0001_fx_light_wall_transparent.png | 3,455 KB | FX |
| 0001_fx_dawn_seal_glow.png | 3,384 KB | FX |
| 0001_env_market_ground.png | 3,350 KB | Env |
| 0001_env_exterior_asset_library_contact_sheet.png | 3,313 KB | Env |
| 0001_prop_chamber_chalk_drawing.png | 3,205 KB | Prop |
| door.png | 3,117 KB | Misc |
| 0001_fx_sundial_correct_angle.png | 3,114 KB | FX |
| 0001_prop_sundial_c.png | 3,060 KB | Prop |
| 0001_prop_sundial_b.png | 3,034 KB | Prop |
| 0001_env_plaza_ground.png | 3,018 KB | Env |
| 0001_env_admin_hall.png | 3,018 KB | Env |
| 0001_prop_bakery_window.png | 2,973 KB | Prop |
| 0001_prop_sundial_c_inscription.png | 2,951 KB | Prop |
| 0001_prop_chamber_crack.png | 2,945 KB | Prop |
| 0001_prop_clocktower_secret_door.png | 2,911 KB | Prop |
| 0001_fx_lin_datapad_glitch.png | 2,897 KB | FX |
| 0001_fx_light_wall_ripple.png | 2,833 KB | FX |
| 0001_prop_chentechnology_console.png | 2,818 KB | Prop |
| 0001_env_bakery.png | 2,814 KB | Env |
| 0001_fx_secret_door_open.png | 2,773 KB | FX |
| 0001_fx_sundial_wrong_angle.png | 2,751 KB | FX |
| 0001_prop_clocktower_clock.png | 2,735 KB | Prop |
| 0001_env_research_institute.png | 2,672 KB | Env |
| 0001_prop_admin_screen.png | 2,647 KB | Prop |
| 0001_env_admin_center.png | 2,599 KB | Env |
| 0001_env_lab_room.png | 2,577 KB | Env |
| 0001_prop_npc_badge.png | 2,562 KB | Prop |
| 0001_prop_doorframe_inscription.png | 2,532 KB | Prop |
| 0001_prop_linguide_datapad.png | 2,523 KB | Prop |
| 0001_env_clocktower_interior.png | 2,469 KB | Env |
| 0001_prop_admin_logo.png | 2,426 KB | Prop |
| 0001_ui_compliance_bar.png | 2,409 KB | UI |
| 0001_prop_sundial_d.png | 2,376 KB | Prop |
| 0001_ui_hint_terminal.png | 2,361 KB | UI |
| 0001_prop_zhaosecurity_device.png | 2,328 KB | Prop |
| 0001_prop_boundary_floor_inscription.png | 2,291 KB | Prop |
| 0001_prop_chamber_stone_platform.png | 2,238 KB | Prop |
| 0001_prop_lab_camera_door.png | 2,182 KB | Prop |
| 0001_env_clocktower_stairs.png | 2,147 KB | Env |
| 0001_prop_lab_displays.png | 2,125 KB | Misc |
| 0001_prop_lab_console.png | 2,095 KB | Misc |
| 0001_env_plaza_bench.png | 2,054 KB | Env |
| 0001_prop_patrol_vehicle.png | 2,037 KB | Prop |
| 0001_prop_sundial_a.png | 2,034 KB | Prop |
| 0001_env_plaza_fountain.png | 1,980 KB | Env |
| 0001_prop_newspaper.png | 1,938 KB | Misc |
| 0001_prop_light_wall_pillar.png | 1,799 KB | Misc |
| 0001_prop_lab_camera_sundial.png | 1,611 KB | Misc |

---

## 汇总

| 分类 | 文件数 | 大小 | 建议操作 |
|------|--------|------|----------|
| ① 开发参考素材 | 13 | 27.2 MB | 可选删除 |
| ② UI 预览/临时 | 6 | 5.0 MB | 建议删除 |
| ③ id0001 env2 孤立 | 48 | 125.5 MB | **强烈建议删除** |
| **合计** | **67** | **~157.7 MB** | — |

---

## 修正说明

V2 扫描误将 **14 个 NPC `_l.png` 大图（20.3 MB）**标记为未使用。经核查，这些文件通过 `chat_dialogue.gd` 的 `DirAccess.get_files_at()` 由对话系统运行时加载（与动画帧相同的动态加载模式）。V3 已通过解析 `DirAccess` 调用自动识别此类模式，现已正确排除。
