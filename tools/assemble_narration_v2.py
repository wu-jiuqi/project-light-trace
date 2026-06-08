"""
溯光计划 — 旁白音频合成与后期处理 v2
修复：先转 WAV 再拼接（避免 MP3 concat 兼容性问题）
"""
import subprocess
import os
import json

FFMPEG = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffmpeg.exe"
FFPROBE = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffprobe.exe"
AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
OUTPUT = os.path.join(AUDIO_DIR, "narration_intro_final.ogg")

SEGMENTS_ORDER = [
    "narration_seg1.mp3",
    "narration_seg2.mp3",
    "narration_seg3.mp3",
    "narration_seg4.mp3",
    "narration_seg5.mp3",
    "narration_seg6.mp3",
    "narration_seg7_注意.mp3",
    "narration_seg7_正文.mp3",
]

GAP_TRACK_SWITCH = 0.050
GAP_ATTENTION_PAUSE = 0.500
TOTAL_TARGET = 55.0


def get_duration(filepath):
    result = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", filepath],
        capture_output=True, text=True
    )
    return float(result.stdout.strip())


def mp3_to_wav(input_mp3, output_wav):
    """MP3 → PCM WAV 转换"""
    subprocess.run([
        FFMPEG, "-y",
        "-i", input_mp3,
        "-c:a", "pcm_s16le",
        "-ar", "44100",
        "-ac", "1",
        output_wav
    ], capture_output=True)


def create_silence_wav(output_path, duration_sec):
    """生成静音 WAV"""
    subprocess.run([
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", f"anullsrc=r=44100:cl=mono",
        "-t", str(duration_sec),
        "-c:a", "pcm_s16le",
        output_path
    ], capture_output=True)


def main():
    print("=" * 60)
    print("  溯光计划 旁白音频合成 v2")
    print("=" * 60)
    
    # === Step 1: MP3 → WAV ===
    print("\n[1/4] MP3 → WAV 转换...")
    wav_files = {}
    for fname in SEGMENTS_ORDER:
        mp3_path = os.path.join(AUDIO_DIR, fname)
        wav_path = os.path.join(AUDIO_DIR, fname.replace(".mp3", ".wav"))
        if not os.path.exists(wav_path):
            mp3_to_wav(mp3_path, wav_path)
        dur = get_duration(wav_path)
        wav_files[fname] = {"path": wav_path, "duration": dur}
        print(f"  {fname}: {dur:.3f}s")
    
    # === Step 2: 计算时间轴 + 生成静音 ===
    print("\n[2/4] 计算时间轴 + 生成静音片段...")
    
    concat_inputs = []  # for ffmpeg concat filter
    timeline = []
    current_time = 0.0
    
    for i, fname in enumerate(SEGMENTS_ORDER):
        wav_path = wav_files[fname]["path"]
        dur = wav_files[fname]["duration"]
        
        # 间隙
        if fname == "narration_seg7_注意.mp3":
            gap_dur = GAP_ATTENTION_PAUSE
            gap_note = "注意前0.5s"
        elif fname == "narration_seg7_正文.mp3":
            gap_dur = 0.0
            gap_note = "无间隙"
        else:
            gap_dur = GAP_TRACK_SWITCH
            gap_note = "轨道切换0.05s"
        
        if gap_dur > 0:
            sil_path = os.path.join(AUDIO_DIR, f"_sil_{i}.wav")
            create_silence_wav(sil_path, gap_dur)
            timeline.append({"type": "silence", "start": current_time, "dur": gap_dur, "note": gap_note})
            concat_inputs.append(sil_path)
            current_time += gap_dur
        
        timeline.append({"type": "audio", "start": current_time, "dur": dur, "name": fname})
        concat_inputs.append(wav_path)
        current_time += dur
    
    # 尾部静音
    if current_time < TOTAL_TARGET:
        end_sil_dur = TOTAL_TARGET - current_time
        sil_path = os.path.join(AUDIO_DIR, "_sil_end.wav")
        create_silence_wav(sil_path, end_sil_dur)
        timeline.append({"type": "silence", "start": current_time, "dur": end_sil_dur, "note": "尾部静音"})
        concat_inputs.append(sil_path)
        current_time += end_sil_dur
    
    print(f"\n  时间轴 ({len(timeline)} 项, 总长 {current_time:.3f}s):")
    for item in timeline:
        label = item.get("name", item.get("note", ""))
        print(f"    [{item['start']:7.3f}s] {item['type']:7s} {item['dur']:7.3f}s  {label}")
    
    # === Step 3: concat 拼接 ===
    print("\n[3/4] ffmpeg concat 拼接...")
    
    # 构建 concat filter
    filter_parts = []
    for idx, path in enumerate(concat_inputs):
        filter_parts.append(f"[{idx}:a]")
    
    n = len(concat_inputs)
    concat_filter = "".join(filter_parts) + f"concat=n={n}:v=0:a=1[assembled]"
    
    cmd = [FFMPEG, "-y"]
    for path in concat_inputs:
        cmd.extend(["-i", path])
    cmd.extend([
        "-filter_complex", concat_filter,
        "-map", "[assembled]",
        "-c:a", "pcm_s16le",
        "-ar", "44100",
        "-ac", "1",
        os.path.join(AUDIO_DIR, "_assembled_temp.wav")
    ])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  拼接失败! {result.stderr[:500]}")
        return
    
    assembled_path = os.path.join(AUDIO_DIR, "_assembled_temp.wav")
    assembled_dur = get_duration(assembled_path)
    print(f"  拼接完成: {assembled_dur:.3f}s")
    
    # === Step 4: 数字底噪 + 导出 .ogg ===
    print("\n[4/4] 添加底噪 + 导出 .ogg...")
    
    # 主音频归一化到 -6dB, 混合极低粉噪
    cmd_final = [
        FFMPEG, "-y",
        "-i", assembled_path,
        "-filter_complex",
        (
            f"[0:a]volume=0.5[a0];"
            f"anoisesrc=d={assembled_dur}:c=pink:r=44100:a=0.0005,volume=0.003[a1];"
            f"[a0][a1]amix=inputs=2:duration=first:weights=1 0.15[out]"
        ),
        "-map", "[out]",
        "-c:a", "libvorbis",
        "-q:a", "6",
        OUTPUT
    ]
    
    result = subprocess.run(cmd_final, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  导出失败! {result.stderr[:500]}")
        return
    
    final_dur = get_duration(OUTPUT)
    file_size = os.path.getsize(OUTPUT)
    
    print(f"  输出: {OUTPUT}")
    print(f"  时长: {final_dur:.3f}s")
    print(f"  大小: {file_size / 1024:.1f} KB")
    
    # === 时间轴参考 ===
    print("\n" + "=" * 60)
    print("  AnimationPlayer 时间轴参考")
    print("=" * 60)
    for item in timeline:
        if item["type"] == "audio":
            end = item["start"] + item["dur"]
            print(f"  [{item['start']:7.3f}s → {end:7.3f}s]  {item['name']}")
    
    # 特殊标记
    print(f"\n  关键时间点:")
    for item in timeline:
        if item["type"] == "audio":
            if "zhu yi" in item.get("name", "").lower() or "注意" in item.get("name", ""):
                print(f"    [注意] 起始: {item['start']:.3f}s")
            if "zheng wen" in item.get("name", "").lower() or "正文" in item.get("name", ""):
                end = item["start"] + item["dur"]
                print(f"    [旁白结束] {end:.3f}s -> 之后为无声画面")
    
    print(f"\n  总时长: {final_dur:.3f}s")
    
    # 清理
    print("\n[清理]")
    # 保留 mp3 和最终 ogg，删除临时 wav
    for f in os.listdir(AUDIO_DIR):
        if f.startswith("_sil_") or f.startswith("_assembled_temp"):
            os.remove(os.path.join(AUDIO_DIR, f))
            print(f"  删除: {f}")
    
    print("\n  ✅ 完成!")
    return timeline


if __name__ == "__main__":
    main()
