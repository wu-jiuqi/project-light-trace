# 纸工拼贴美术管线

本目录是《溯光计划》的纸工拼贴美术规范入口。它定义后续美术资产的生产方式，不直接替换当前 Godot 原型中的像素占位资源。

## 阅读顺序

1. `style_bible.md`：全项目视觉规则、运行时约束和 UI 规范。
2. `image2_workflow.md`：Image2 交互生成、参考图编辑和入库流程。
3. `asset_manifest_format.md`：机器可读资产清单格式。
4. `qa_checklist.md`：候选图进入正式资源库前的检查项。
5. `generation_record.template.md`：每轮生成记录模板。

## 文档优先级

发生冲突时按以下顺序执行：

1. `design/art/papercraft/style_bible.md`：决定全局画风、尺度、材质、动画方式和文件规范。
2. `assets/papercraft/manifests/*.json`：决定实际需要生产和验收的文件。
3. `design/id0762/art_spec_角色美术规格.md` 与 `design/id0762/art_spec_地图美术规格.md`：决定 #0762 的角色外观、空间尺寸、剧情锚点和区域细节。
4. `design/id0762/角色精灵图_AI提示词.md`：仅保留为旧链接入口，不包含现役 Prompt。

## 资产清单

- `assets/papercraft/manifests/core.json`：全局材质、UI、标题页和星图。
- `assets/papercraft/manifests/id0001.json`：碎片 #0001 角色立绘。
- `assets/papercraft/manifests/id0762.json`：碎片 #0762「颜色的葬礼」。

## 当前生产范围

当前阶段只生产人物立绘资产：单张透明背景 PNG、完整角色、白色 / 米白立牌描边、脚底锚点居中。暂不生产 walk、talk、方向变体、独立阴影、道具、FX、UI、环境模块或星图碎片。

运行以下命令检查目录和清单格式：

```powershell
npm run validate:papercraft
```

## 现有文档关系

- `design/id0762/art_spec_角色美术规格.md` 和 `design/id0762/art_spec_地图美术规格.md` 已升级为纸工版，继续作为 #0762 的叙事、角色锚点和地图内容依据。
- `design/id0762/角色精灵图_AI提示词.md` 是旧像素管线记录。纸工资产不再使用其中的 `32x32` 精灵表约束。
- `assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` 是第一张气氛锚点，不可直接切片当作正式资产。
