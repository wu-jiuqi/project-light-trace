"""
溯光计划 — 开场旁白 TTS 生成脚本 v2
使用 edge-tts Communicate (纯文本模式，非 SSML) + ffmpeg 后期合成
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
FFPROBE = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffprobe.exe"

# === 全局 TTS 参数 ===
# rate="+10%" → 1.1x 语速
# pitch="+0Hz" → 完全不变音高（模拟"非人"播报）
# 纯文本模式：无 SSML，用 API 参数控制
TTS_RATE = "+10%"
TTS_PITCH = "+0Hz"
TTS_VOLUME = "+0%"

# === 片段定义 ===
# 每个片段生成独立音频，后期用 ffmpeg 精确对齐时间轴
segments = [
    {
        "id": "seg1",
        "target_start": 0.0,
        "text": "编号 TP—2077—03—溯光者。身份确认。",
        "rate": "+10%",
        "pitch": "+0Hz",
        "volume": "+0%",
        "note": "0.0s: 平静、中性、无感情"
    },
    {
        "id": "seg2",
        "target_start": 3.0,
        "text": "万象——人类迄今最大规模的数字现实平台。四十七亿人的记忆、情感与生活，被安全保存于此。",
        "rate": "+10%",
        "pitch": "+0Hz",
        "volume": "+0%",
        "note": "3.0s: 中性描述，略微正式"
    },
    {
        "id": "seg3",
        "target_start": 15.0,
        "text": "2077年3月15日。凌晨3点15分。",
        "rate": "+5%",
        "pitch": "-10Hz",  # 微降——模拟"AI切换运行模式"
        "volume": "+0%",
        "note": "15.0s: 降调——像AI切换运行模式"
    },
    {
        "id": "seg4",
        "target_start": 17.0,
        "text": "核心AI——织女·太一——出现未知异常。万象碎裂为十二个孤立碎片。四十七亿意识——陷入休眠。",
        "rate": "+10%",
        "pitch": "+0Hz",
        "volume": "+0%",
        "note": "17.0s: 新闻播报——客观、不带立场"
    },
    {
        "id": "seg5",
        "target_start": 25.0,
        "text": "您已被选定为溯光者。任务如下——",
        "rate": "+15%",
        "pitch": "+0Hz",
        "volume": "+0%",
        "note": "25.0s: 读稿模式，语速略快"
    },
    {
        "id": "seg6",
        "target_start": 30.0,
        "text": "进入碎片——找到源印——净化世界——修复万象——",
        "rate": "+10%",
        "pitch": "+0Hz",
        "volume": "+0%",
        "note": "30.0s: 机械念清单"
    },
    {
        "id": "seg7_注意",
        "target_start": 40.0,
        "text": "注意——",
        "rate": "+8%",
        "pitch": "-10Hz",  # 微降 0.5 半音
        "volume": "+15%",  # 加重 15%
        "note": "40.0s: 唯一情感破绽——注意加重15%，音高低0.5半音"
    },
    {
        "id": "seg7_正文",
        "target_start": None,  # 紧跟 seg7_注意
        "text": "碎片内的一切均不真实。请勿过度共情其中的居民。请按规范操作。公司将全程提供支援。",
        "rate": "+10%",
        "pitch": "+0Hz",
        "volume": "+0%",
        "note": "恢复读稿语调"
    },
]


def get_duration(filepath):
    """获取音频文件时长（秒）"""
    result = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", filepath],
        capture_output=True, text=True
    )
    return float(result.stdout.strip())


async def generate_segment(seg, output_path):
    """使用 edge-tts Communicate 生成单个片段（纯文本模式）"""
    text = seg["text"]
    rate = seg.get("rate", TTS_RATE)
    pitch = seg.get("pitch", TTS_PITCH)
    volume = seg.get("volume", TTS_VOLUME)
    
    print(f"  文本: {text}")
    print(f"  参数: rate={rate}, pitch={pitch}, volume={volume}")
    
    communicate = edge_tts.Communicate(
        text=text,
        voice=VOICE,
        rate=rate,
        pitch=pitch,
        volume=volume
    )
    await communicate.save(output_path)
    
    dur = get_duration(output_path)
    print(f"  时长: {dur:.3f}s")
    return dur


async def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print("=" * 60)
    print("  溯光计划 开场旁白 TTS 生成 v2")
    print("=" * 60)
    print(f"\nVoice: {VOICE}")
    print(f"模式: 纯文本 (无 SSML)")
    print(f"输出: {OUTPUT_DIR}\n")
    
    durations = {}
    
    for seg in segments:
        seg_id = seg["id"]
        output_path = os.path.join(OUTPUT_DIR, f"narration_{seg_id}.mp3")
        
        print(f"\n--- {seg_id} ---")
        print(f"  {seg['note']}")
        
        dur = await generate_segment(seg, output_path)
        durations[seg_id] = {
            "target_start": seg["target_start"],
            "duration": dur,
            "file": output_path,
            "note": seg.get("note", "")
        }
    
    # 保存时长数据
    dur_file = os.path.join(OUTPUT_DIR, "narration_durations.json")
    with open(dur_file, "w", encoding="utf-8") as f:
        json.dump(durations, f, ensure_ascii=False, indent=2)
    
    print(f"\n时长数据: {dur_file}")
    
    # 汇总
    print("\n" + "=" * 60)
    print("  片段时长汇总")
    print("=" * 60)
    for seg_id, info in durations.items():
        ts = info["target_start"]
        dur = info["duration"]
        end = ts + dur if ts is not None else None
        ts_str = f"{ts:.1f}s" if ts is not None else "紧跟"
        end_str = f"→ {end:.1f}s" if end is not None else ""
        print(f"  {seg_id:20s} @{ts_str:>6s}  dur={dur:.3f}s {end_str}  {info['note']}")
    
    total_dur = sum(d["duration"] for d in durations.values())
    print(f"\n  总音频时长 (不含间隔): {total_dur:.3f}s")


if __name__ == "__main__":
    asyncio.run(main())
