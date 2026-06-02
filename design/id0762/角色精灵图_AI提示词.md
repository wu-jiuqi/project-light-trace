# 碎片 #0762「颜色的葬礼」—— 旧像素 Prompt 封存说明

> 状态：已废弃，不再用于正式资产生成。  
> 原因：项目美术路线已从 `32×32` 像素精灵表升级为高分辨率整片纸偶。  
> 保留文件名：兼容既有文档链接，避免误用旧版本。

## 当前规范

正式纸工资产生产请使用：

```text
design/art/papercraft/style_bible.md
design/art/papercraft/image2_workflow.md
design/art/papercraft/qa_checklist.md
assets/papercraft/manifests/id0762.json
```

## 当前角色生产方式

- 玩家制作 `down`、`up`、`left`、`right` 四张基础纸偶。
- NPC 只制作实际需要的方向。
- 移动不制作逐帧精灵表，通过完整纸片的摇摆、弹跳和阴影错位表达。
- 开心、悲伤、恐慌、觉醒等剧情动作使用独立姿态纸片。
- 基础资产只维护彩色版本；灰阶与残留色由 Shader 和 `_sp_mask.png` 处理。

## Image2 Prompt

角色、姿态、环境、UI 和异常拼贴 Prompt 模板统一维护在：

```text
design/art/papercraft/image2_workflow.md
```

角色外观、故事身份和视觉锚点继续参考：

```text
design/id0762/art_spec_角色美术规格.md
```
