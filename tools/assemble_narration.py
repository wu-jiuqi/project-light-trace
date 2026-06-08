"""
溯光计划 — 旁白音频合成与后期处理
使用 ffmpeg 精确组装片段 + 数字底噪 + 微断效果
"""
import subprocess
import os
import json

FFMPEG = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffmpeg.exe"
FFPROBE = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffprobe.exe"
AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
OUTPUT = os.path.join(AUDIO_DIR, "narration_intro_final.ogg")

# 片段文件（按拼接顺序）
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

# 间隙配置
# - "track_switch": 0.05s — 模拟系统切换音频轨道
# - "pause_before_attention": 0.5s — "注意"前的特殊停顿
# - "end_silence": 填充到 55.0s 总时长

GAP_TRACK_SWITCH = 0.050  # 画面切换点的极短静音
GAP_ATTENTION_PAUSE = 0.500  # "注意"前的停顿
TOTAL_TARGET = 55.0  # 目标总时长


def get_duration(filepath):
    """获取音频时长"""
    result = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", filepath],
        capture_output=True, text=True
    )
    return float(result.stdout.strip())


def create_silence(output_path, duration_sec):
    """生成指定时长的静音音频"""
    subprocess.run([
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", f"anullsrc=r=44100:cl=mono",
        "-t", str(duration_sec),
        "-c:a", "pcm_s16le",
        output_path
    ], capture_output=True)
    return output_path


def create_white_noise(output_path, duration_sec, volume_db=-50):
    """生成指定时长的白噪（用于底噪混合）"""
    subprocess.run([
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", f"anoisesrc=d={duration_sec}:c=pink:r=44100:a=0.003",  # pink noise, very quiet
        "-c:a", "pcm_s16le",
        output_path
    ], capture_output=True)
    return output_path


def main():
    print("=" * 60)
    print("  溯光计划 旁白音频合成与后期处理")
    print("=" * 60)
    
    # === Step 1: 读取各片段时长 ===
    print("\n[1/5] 读取片段时长...")
    seg_durations = {}
    for fname in SEGMENTS_ORDER:
        fpath = os.path.join(AUDIO_DIR, fname)
        dur = get_duration(fpath)
        seg_durations[fname] = dur
        print(f"  {fname}: {dur:.3f}s")
    
    # === Step 2: 计算时间轴 ===
    print("\n[2/5] 计算时间轴...")
    timeline = []
    current_time = 0.0
    
    for i, fname in enumerate(SEGMENTS_ORDER):
        fpath = os.path.join(AUDIO_DIR, fname)
        dur = seg_durations[fname]
        
        # 决定间隙类型
        if fname == "narration_seg7_注意.mp3":
            # 特殊停顿: 0.5s 在 "注意" 之前
            gap_name = f"pause_{i}"
            gap_dur = GAP_ATTENTION_PAUSE
            gap_note = "注意前0.5s停顿"
        elif fname == "narration_seg7_正文.mp3":
            # 紧跟 注意，无间隙
            gap_name = None
            gap_dur = 0.0
            gap_note = "无间隙（紧跟注意）"
        else:
            gap_name = f"gap_{i}"
            gap_dur = GAP_TRACK_SWITCH
            gap_note = "轨道切换 0.05s"
        
        if gap_name and gap_dur > 0:
            timeline.append({
                "type": "silence",
                "name": gap_name,
                "duration": gap_dur,
                "note": gap_note,
                "start": current_time
            })
            current_time += gap_dur
        
        timeline.append({
            "type": "audio",
            "name": fname,
            "file": fpath,
            "duration": dur,
            "start": current_time
        })
        current_time += dur
    
    # 填充尾部静音到 55s
    if current_time < TOTAL_TARGET:
        end_silence = TOTAL_TARGET - current_time
        timeline.append({
            "type": "silence",
            "name": "end_silence",
            "duration": end_silence,
            "note": f"尾部静音 ({end_silence:.3f}s)",
            "start": current_time
        })
        current_time += end_silence
    
    # 打印时间轴
    print("\n  最终时间轴:")
    print(f"  {'开始':>8s}  {'结束':>8s}  {'时长':>8s}  类型      内容")
    print(f"  {'-'*8}  {'-'*8}  {'-'*8}  {'-'*20}")
    for item in timeline:
        end_t = item["start"] + item["duration"]
        print(f"  {item['start']:8.3f}  {end_t:8.3f}  {item['duration']:8.3f}  {item['type']:8s}  {item.get('name', '')}")
    print(f"\n  总时长: {current_time:.3f}s")
    
    # === Step 3: 生成静音片段 ===
    print("\n[3/5] 生成静音片段...")
    silence_files = []
    for item in timeline:
        if item["type"] == "silence" and item["duration"] > 0:
            sil_path = os.path.join(AUDIO_DIR, f"_{item['name']}.wav")
            create_silence(sil_path, item["duration"])
            silence_files.append(sil_path)
            print(f"  {item['name']}: {item['duration']:.3f}s → {sil_path}")
    
    # === Step 4: ffmpeg concat 拼接 ===
    print("\n[4/5] 拼接所有片段...")
    
    # 构建 concat 输入列表
    concat_inputs = []
    concat_files_for_demuxer = []
    temp_concat_list = os.path.join(AUDIO_DIR, "_concat_list.txt")
    
    with open(temp_concat_list, "w", encoding="utf-8") as f:
        for item in timeline:
            if item["type"] == "audio":
                abs_path = os.path.abspath(item["file"]).replace("\\", "/")
                f.write(f"file '{abs_path}'\n")
                f.write(f"duration {item['duration']:.6f}\n")
            elif item["type"] == "silence":
                sil_path = os.path.join(AUDIO_DIR, f"_{item['name']}.wav")
                abs_path = os.path.abspath(sil_path).replace("\\", "/")
                f.write(f"file '{abs_path}'\n")
                f.write(f"duration {item['duration']:.6f}\n")
    
    assembled_wav = os.path.join(AUDIO_DIR, "_narration_assembled.wav")
    cmd_concat = [
        FFMPEG, "-y",
        "-f", "concat",
        "-safe", "0",
        "-i", temp_concat_list,
        "-c:a", "pcm_s16le",
        "-ar", "44100",
        "-ac", "1",
        assembled_wav
    ]
    result = subprocess.run(cmd_concat, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  拼接失败!")
        print(f"  stderr: {result.stderr}")
        return
    
    assembled_dur = get_duration(assembled_wav)
    print(f"  拼接完成: {assembled_wav}")
    print(f"  时长: {assembled_dur:.3f}s")
    
    # === Step 5: 添加数字底噪 + 导出 .ogg ===
    print("\n[5/5] 添加数字底噪 + 导出 .ogg...")
    
    # 使用 ffmpeg 滤镜链：
    # 1. 生成粉噪（pink noise）
    # 2. 衰减到 -50dB
    # 3. 与主音频混合
    # 4. 导出为 .ogg (q=6, ~192kbps VBR)
    
    # 方法：用 amix 混合两路音频
    cmd_final = [
        FFMPEG, "-y",
        "-i", assembled_wav,
        "-filter_complex",
        (
            # 主音频归一化到 -3dB（留余量给底噪混合）
            "[0:a]volume=-3dB[a0];"
            # 生成粉噪并衰减到极低音量
            f"anoisesrc=d={assembled_dur}:c=pink:r=44100:a=0.001,volume=-50dB[a1];"
            # 混合两路
            "[a0][a1]amix=inputs=2:duration=first:weights=1 0.3[out]"
        ),
        "-map", "[out]",
        "-c:a", "libvorbis",
        "-q:a", "6",
        OUTPUT
    ]
    
    result = subprocess.run(cmd_final, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  后期处理失败!")
        print(f"  stderr: {result.stderr}")
        return
    
    final_dur = get_duration(OUTPUT)
    file_size = os.path.getsize(OUTPUT)
    
    print(f"  输出: {OUTPUT}")
    print(f"  时长: {final_dur:.3f}s")
    print(f"  大小: {file_size / 1024:.1f} KB")
    
    # === 输出时间轴参考表 ===
    print("\n" + "=" * 60)
    print("  时间轴参考表 (供 AnimationPlayer 使用)")
    print("=" * 60)
    
    scene_cues = {}
    current_scene = 0
    for item in timeline:
        if item["type"] == "audio":
            name = item["name"]
            start = item["start"]
            end = start + item["duration"]
            print(f"  [{start:6.3f}s → {end:6.3f}s] {name}")
    
    print(f"\n  总时长: {final_dur:.3f}s")
    print(f"  输出文件: {OUTPUT}")
    
    # === 清理临时文件 ===
    print("\n[清理] 删除临时文件...")
    for sil_path in silence_files:
        try:
            os.remove(sil_path)
        except:
            pass
    try:
        os.remove(temp_concat_list)
    except:
        pass
    print("  完成!")
    
    return timeline


if __name__ == "__main__":
    main()
