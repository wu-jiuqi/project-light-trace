"""
溯光计划 — 开场旁白 TTS 生成脚本
使用 edge-tts (Microsoft Neural TTS) + SSML 精确控制语调参数
"""
import asyncio
import edge_tts
import os
import subprocess
import json

# === 配置 ===
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
VOICE = "zh-CN-XiaoxiaoNeural"
FFMPEG = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffmpeg.exe"

# === SSML 全局参数 ===
# pitch="0%"  → 完全不改变基准音高（压制自然起伏）
# rate="+10%"  → 1.1x 语速
# contour="(0%,+0Hz)(100%,+0Hz)" → 贯穿全程的平坦音高曲线（模拟"非人"播报）
PROSODY_GLOBAL = 'pitch="0%" rate="+10%" contour="(0%,+0Hz)(100%,+0Hz)"'

# === 分段定义 ===
# 每段独立生成，精确控制间隔
segments = [
    {
        "id": "seg1",
        "start": 0.0,
        "text": "编号 TP—2077—03—溯光者。身份确认。",
        "note": "平静、中性、无感情"
    },
    {
        "id": "seg2",
        "start": 3.0,
        "text": "万象——人类迄今最大规模的数字现实平台。四十七亿人的记忆、情感与生活，被安全保存于此。",
        "note": "中性描述，略微正式的宣传片语调"
    },
    {
        "id": "seg3",
        "start": 15.0,
        "text": "2077年3月15日。凌晨3点15分。",
        "note": "降调——像AI切换运行模式",
        "pitch_extra": "contour=\"(0%,+0Hz)(50%,-1.5st)(100%,-1.5st)\""
    },
    {
        "id": "seg4",
        "start": 17.0,
        "text": "核心AI——织女·太一——出现未知异常。万象碎裂为十二个孤立碎片。四十七亿意识——陷入休眠。",
        "note": "新闻播报——客观、不带立场"
    },
    {
        "id": "seg5",
        "start": 25.0,
        "text": "您已被选定为溯光者。任务如下——",
        "note": "读稿模式，语速略快",
        "rate_extra": "+15%"
    },
    {
        "id": "seg6",
        "start": 30.0,
        "text": "进入碎片——找到源印——净化世界——修复万象——",
        "note": "机械念清单，破折号间留0.3秒停顿",
        "list_mode": True
    },
    {
        "id": "seg7",
        "start": 40.0,
        "text_parts": [
            {"text": "注意——", "note": "全文唯一情感破绽：比所有其他词重约15%，音高低0.5半音，停顿0.5秒"},
            {"text": "碎片内的一切均不真实。请勿过度共情其中的居民。请按规范操作。公司将全程提供支援。", "note": "恢复读稿语调"}
        ],
        "note": ""
    },
]

# seg6 的清单模式：每个破折号前停顿 0.3s
SEG6_ITEMS = [
    "进入碎片——",
    "找到源印——",
    "净化世界——",
    "修复万象——",
]


def build_ssml(seg):
    """为单个片段构建 SSML"""
    text = seg.get("text", "")
    rate = seg.get("rate_extra", "+10%")
    
    # seg3 特殊：降调
    if seg["id"] == "seg3":
        prosody = f'pitch="0%" rate="{rate}" contour="(0%,+0Hz)(30%,-1.5st)(100%,-1.5st)"'
    else:
        prosody = f'pitch="0%" rate="{rate}" contour="(0%,+0Hz)(100%,+0Hz)"'
    
    # seg6 清单模式
    if seg.get("list_mode"):
        inner = ""
        for item in SEG6_ITEMS:
            inner += f'{item}<break time="300ms"/>'
        # 移到最后多余的 break
        if inner.endswith('<break time="300ms"/>'):
            inner = inner[:-len('<break time="300ms"/>')]
        body = f'<prosody {prosody}>{inner}</prosody>'
    
    # seg7 特殊：有两部分，"注意" 加重
    elif seg["id"] == "seg7":
        parts = seg["text_parts"]
        # 注意——：加重 15%，音高低 0.5 半音，停顿 0.5 秒
        attention = f'<prosody volume="+15%" pitch="-0.5st">注意——</prosody><break time="500ms"/>'
        rest = parts[1]["text"]
        body = f'<prosody {prosody}>{attention}{rest}</prosody>'
    
    else:
        # 破折号用 break 替代，停顿 0.15 秒
        processed = text.replace("——", '<break time="150ms"/>')
        body = f'<prosody {prosody}>{processed}</prosody>'
    
    ssml = f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="zh-CN">
    <voice name="{VOICE}">
        <mstts:silence type="Leading" value="0ms"/>
        {body}
        <mstts:silence type="Tailing" value="0ms"/>
    </voice>
</speak>'''
    return ssml


async def generate_segment(seg, output_path):
    """生成单个片段的音频"""
    ssml = build_ssml(seg)
    communicate = edge_tts.Communicate(ssml, VOICE)
    await communicate.save(output_path)
    
    # 获取时长
    result = subprocess.run(
        [FFMPEG, "-i", output_path, "-f", "null", "-"],
        capture_output=True, text=True
    )
    duration = 0.0
    for line in result.stderr.split("\n"):
        if "Duration:" in line:
            parts = line.split("Duration: ")[1].split(",")[0].split(":")
            duration = float(parts[0]) * 3600 + float(parts[1]) * 60 + float(parts[2])
            break
    
    print(f"  {seg['id']}: {duration:.3f}s — {seg.get('note', '')}")
    return duration


async def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("=== 溯光计划 开场旁白 TTS 生成 ===\n")
    print(f"Voice: {VOICE}")
    print(f"输出目录: {OUTPUT_DIR}\n")
    
    durations = {}
    
    # 生成所有片段
    print("生成各片段音频...")
    for seg in segments:
        output_path = os.path.join(OUTPUT_DIR, f"narration_{seg['id']}.wav")
        print(f"\n{seg['id']} (目标起始: {seg['start']}s):")
        print(f"  SSML 预览: {build_ssml(seg)[:200]}...")
        
        dur = await generate_segment(seg, output_path)
        durations[seg['id']] = {
            "target_start": seg["start"],
            "duration": dur,
            "file": output_path
        }
    
    # 保存时长数据
    dur_file = os.path.join(OUTPUT_DIR, "narration_durations.json")
    with open(dur_file, "w", encoding="utf-8") as f:
        json.dump(durations, f, ensure_ascii=False, indent=2)
    
    print(f"\n时长数据已保存: {dur_file}")
    print("\n=== 片段生成完成 ===")
    print("\n各段时长:")
    for seg_id, info in durations.items():
        target_end = info["target_start"] + info["duration"]
        print(f"  {seg_id}: 起始={info['target_start']:.1f}s, 时长={info['duration']:.3f}s, 结束={target_end:.3f}s")


if __name__ == "__main__":
    asyncio.run(main())
