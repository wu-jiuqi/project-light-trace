"""
修复环境音效 — 根源解决方案
问题：33个元素通过单个 amix 混合时，每个元素被隐性衰减约 -30dB
解决：按场景分段混合，每段独立控制电平
"""
import subprocess
import os

FFMPEG = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffmpeg.exe"
AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
SFX_DIR = os.path.join(AUDIO_DIR, "sfx")
OUTPUT = os.path.join(AUDIO_DIR, "opening_ambient.ogg")

SR = 44100

# 场景时间轴（来自 narration_timeline）
SCENES = {
    "scene1": (0.0, 4.9),
    "scene2": (0.05, 13.7),
    "scene3": (13.7, 18.3),
    "scene4": (18.3, 27.7),
    "scene5": (27.7, 31.1),
    "scene6": (31.1, 35.5),
    "scene7": (36.0, 37.3),
    "scene8": (37.2, 38.2),
    "scene9": (38.2, 46.5),
    "scene10": (46.5, 55.0),
}


def run_ffmpeg(cmd, desc=""):
    result = subprocess.run(cmd, capture_output=True, text=True)
    ok = result.returncode == 0
    if desc:
        print(f"  {'[OK]' if ok else '[FAIL]'} {desc}")
        if not ok:
            print(f"    {result.stderr[:300]}")
    return ok


def mix_scene(elements, duration, output_path):
    """混合单个场景的多个音效元素"""
    if not elements:
        # 无声场景：生成静音
        return run_ffmpeg([
            FFMPEG, "-y",
            "-f", "lavfi",
            "-i", f"anullsrc=r={SR}:cl=mono",
            "-t", str(duration),
            "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
            output_path
        ], f"无声场景 ({duration:.1f}s)")
    
    if len(elements) == 1:
        # 单个元素：直接裁剪到场景时长
        elem_path, delay, vol_db = elements[0]
        vol_linear = 10 ** (vol_db / 20.0)
        return run_ffmpeg([
            FFMPEG, "-y",
            "-i", elem_path,
            "-af", f"adelay={int(delay*1000)}:all=1,volume={vol_linear:.4f}",
            "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
            "-t", str(duration),
            output_path
        ], f"单元素场景 ({duration:.1f}s)")
    
    # 多元素：amix — 关键：normalize=0 避免稀疏输入被压缩
    filter_parts = []
    input_files = []
    
    for i, (elem_path, delay, vol_db) in enumerate(elements):
        input_files.append(elem_path)
        vol_linear = 10 ** (vol_db / 20.0)
        delay_ms = int(delay * 1000)
        
        filter_parts.append(
            f"[{i}:a]adelay={delay_ms}:all=1,volume={vol_linear:.4f}[a{i}]"
        )
    
    n = len(elements)
    mix_inputs = "".join([f"[a{i}]" for i in range(n)])
    filter_all = ";".join(filter_parts) + f";{mix_inputs}amix=inputs={n}:duration=longest:normalize=0[out]"
    
    cmd = [FFMPEG, "-y"]
    for f in input_files:
        cmd.extend(["-i", f])
    cmd.extend([
        "-filter_complex", filter_all,
        "-map", "[out]",
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        "-t", str(duration),
        output_path
    ])
    
    return run_ffmpeg(cmd, f"混合 {len(elements)} 元素 ({duration:.1f}s)")


def main():
    print("=" * 60)
    print("  修复环境音效 — 按场景分段混合")
    print("=" * 60)
    
    scene_mixes = {}
    
    # === 场景1: 系统启动音 (0-4.9s) ===
    print("\n[场景1] 系统启动音")
    scene_mixes["scene1"] = [
        (os.path.join(SFX_DIR, "e01_startup.wav"), 0.05, -8),  # 从 -12dB 提升
    ]
    
    # === 场景2: 纸板摩擦 + 城市白噪 (0.05-13.7s) ===
    print("\n[场景2] 纸板摩擦 + 城市白噪")
    scene_mixes["scene2"] = [
        (os.path.join(SFX_DIR, "e02_paper_rub.wav"), 0, -14),    # 提升：-10→-14
        (os.path.join(SFX_DIR, "e02_city_noise.wav"), 0, -20),    # 提升：-16→-20
    ]
    
    # === 场景3: 磁带停止声 (13.7-18.3s) ===
    print("\n[场景3] 磁带停止声")
    scene_mixes["scene3"] = [
        (os.path.join(SFX_DIR, "e03_tape_stop_0.wav"), 0.6, -3),   # 14.3s
        (os.path.join(SFX_DIR, "e03_tape_stop_1.wav"), 1.1, -3),   # 14.8s
    ]
    
    # === 场景4: 撕裂声 + 地鸣 (18.3-27.7s) ===
    print("\n[场景4] 撕裂声 + 地鸣")
    scene_mixes["scene4"] = [
        (os.path.join(SFX_DIR, "e04_tear.wav"), 0, -6),             # 撕裂声：-1→-6
        (os.path.join(SFX_DIR, "e04_rumble_scene4.wav"), 0, -14),   # 地鸣：-8→-14
    ]
    
    # === 场景5: 地鸣持续 (27.7-31.1s) ===
    print("\n[场景5] 地鸣持续")
    scene_mixes["scene5"] = [
        (os.path.join(SFX_DIR, "e05_rumble_scene5.wav"), 0, -6),    # 地鸣（单元素）
    ]
    
    # === 场景6: 打字机 (31.1-35.5s) ===
    print("\n[场景6] 打字机击键")
    typewriter_elements = []
    for i in range(20):
        t = 0.5 + i * 0.15  # 场景内偏移
        typewriter_elements.append(
            (os.path.join(SFX_DIR, f"e06_typewriter_{i:02d}.wav"), t, -8)  # -6→-8
        )
    scene_mixes["scene6"] = typewriter_elements
    
    # === 场景7: 盖章 + 翻页 (36.0-37.3s) ===
    print("\n[场景7] 盖章 + 翻页")
    scene_mixes["scene7"] = [
        (os.path.join(SFX_DIR, "e07_stamp.wav"), 0.08, -4),        # 36.08s: -2→-4
        (os.path.join(SFX_DIR, "e07_page_turn.wav"), 0.5, -14),    # 36.5s: -10→-14
    ]
    
    # === 场景8: 风声 (37.2-38.2s) ===
    print("\n[场景8] 风声切过")
    scene_mixes["scene8"] = [
        (os.path.join(SFX_DIR, "e08_wind.wav"), 0.05, -5),
    ]
    
    # === 场景9: 无声 (38.2-46.5s) ===
    print("\n[场景9] 无声")
    scene_mixes["scene9"] = []
    
    # === 场景10: 银箔 + 低持续音 (46.5-55.0s) ===
    print("\n[场景10] 银箔 + 低持续音")
    scene_mixes["scene10"] = [
        (os.path.join(SFX_DIR, "e10_foil.wav"), 0, -16),   # -10→-16
        (os.path.join(SFX_DIR, "e10_drone.wav"), 0, -14),   # -8→-14
    ]
    
    # 混合每个场景
    print("\n" + "=" * 60)
    print("  逐场景混合...")
    print("=" * 60)
    
    scene_wavs = []
    for scene_name, elements in scene_mixes.items():
        s, e = SCENES[scene_name]
        dur = e - s
        wav_path = os.path.join(AUDIO_DIR, f"_scene_{scene_name}.wav")
        
        print(f"\n  {scene_name} [{s:.1f}s → {e:.1f}s, {dur:.1f}s]: {len(elements)} 元素")
        if mix_scene(elements, dur, wav_path):
            scene_wavs.append(wav_path)
        else:
            print(f"  场景 {scene_name} 混合失败!")
            return
    
    # 拼接所有场景到 55s 时间轴
    print("\n" + "=" * 60)
    print("  拼接到 55s 时间轴...")
    print("=" * 60)
    
    TOTAL = 55.0
    
    # 方法：创建 55s 静音底轨，用 adelay+amix 将每个场景放到正确位置
    silence_path = os.path.join(AUDIO_DIR, "_silence_55s.wav")
    run_ffmpeg([
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", f"anullsrc=r={SR}:cl=mono",
        "-t", str(TOTAL),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        silence_path
    ], "55s静音底轨")
    
    # 收集所有带延迟的输入
    input_paths = [silence_path]
    filter_parts = []
    
    for idx, (scene_name, wav_path) in enumerate(zip(scene_mixes.keys(), scene_wavs)):
        s, e = SCENES[scene_name]
        input_idx = idx + 1
        input_paths.append(wav_path)
        delay_ms = int(s * 1000)
        filter_parts.append(f"[{input_idx}:a]adelay={delay_ms}:all=1[a{input_idx}]")
    
    # amix 所有场景到静音底轨上
    n = len(input_paths)
    mix_labels = "[0:a]" + "".join([f"[a{i}]" for i in range(1, n)])
    filter_all = ";".join(filter_parts) + f";{mix_labels}amix=inputs={n}:duration=first:normalize=0[out]"
    
    cmd = [FFMPEG, "-y"]
    for p in input_paths:
        cmd.extend(["-i", p])
    cmd.extend([
        "-filter_complex", filter_all,
        "-map", "[out]",
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        os.path.join(AUDIO_DIR, "_ambient_assembled.wav")
    ])
    
    run_ffmpeg(cmd, f"拼接到 {TOTAL}s 时间轴")
    
    assembled_wav = os.path.join(AUDIO_DIR, "_ambient_assembled.wav")
    
    # 最终导出 .ogg（带轻微限制器防止削波）
    print("\n  导出 .ogg（限制器保护）...")
    cmd = [
        FFMPEG, "-y",
        "-i", assembled_wav,
        "-af", "alimiter=limit=0.98:level=disabled:attack=5:release=50",
        "-c:a", "libvorbis",
        "-q:a", "5",
        OUTPUT
    ]
    run_ffmpeg(cmd, "导出 OGG")
    
    # 验证
    result = subprocess.run(
        ["D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffprobe.exe",
         "-v", "error", "-show_entries", "format=duration,size", "-of", "default=noprint_wrappers=1:nokey=1", OUTPUT],
        capture_output=True, text=True
    )
    dur, size = result.stdout.strip().split("\n")
    
    print(f"\n  输出: {OUTPUT}")
    print(f"  时长: {float(dur):.3f}s")
    print(f"  大小: {int(size)/1024:.0f}KB")
    
    # 静音检测
    print("\n  静音段验证...")
    result = subprocess.run([
        "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffmpeg.exe",
        "-i", OUTPUT,
        "-af", "silencedetect=n=-40dB:d=0.1",
        "-f", "null", "NUL"
    ], capture_output=True, text=True)
    
    silence_periods = []
    for line in result.stderr.split("\n"):
        if "silence_start" in line and "silence_end" in line:
            start = float(line.split("silence_start: ")[1].split("]")[0])
            end = float(line.split("silence_end: ")[1].split("|")[0])
            dur_s = float(line.split("silence_duration: ")[1].split("\n")[0])
            silence_periods.append((start, end, dur_s))
    
    # 场景覆盖检查
    should_have_sound = [
        ("场景1: 系统启动", 0, 0.5),
        ("场景2: 纸板摩擦+白噪", 0.5, 13.7),
        ("场景3: 磁带停止", 14.0, 15.5),
        ("场景4: 撕裂+地鸣", 18.3, 27.7),
        ("场景5: 地鸣", 27.7, 31.1),
        ("场景6: 打字机", 31.5, 34.5),
        ("场景7: 盖章+翻页", 36.0, 37.5),
        ("场景8: 风声", 37.2, 37.5),
        ("场景9: 无声", 38.2, 46.5),
        ("场景10: 银箔+低音", 46.5, 55.0),
    ]
    
    print(f"\n  {'场景':20s} {'应有声音':>12s} {'状态'}")
    print(f"  {'-'*20} {'-'*12} {'-'*10}")
    
    for label, s, e in should_have_sound:
        # 检查这个时间段是否在某个静音段内
        is_silent = False
        for sil_s, sil_e, __ in silence_periods:
            if sil_s <= s and e <= sil_e:
                is_silent = True
                break
        
        want_sound = "无声" not in label
        if want_sound and is_silent:
            status = "[问题] 应有声但静音"
        elif not want_sound and not is_silent:
            status = "[OK] 设计无声"
        elif want_sound and not is_silent:
            status = "[OK] 有声"
        else:
            status = "[OK] 静音"
        
        print(f"  {label:20s} {s:.1f}s-{e:.1f}s  {status}")
    
    # 清理
    for wav in scene_wavs:
        os.remove(wav)
    os.remove(silence_path)
    os.remove(assembled_wav)
    
    print(f"\n  [DONE]")


if __name__ == "__main__":
    main()
