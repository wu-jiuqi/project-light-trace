"""
溯光计划 — 环境音效生成脚本
根据 提示词.md / 第七章音频设计，合成所有环境音效元素
Foley 音效用 ffmpeg 音频滤镜合成近似
"""
import subprocess
import os

FFMPEG = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffmpeg.exe"
FFPROBE = "D:/FFMPEG/ffmpeg-2025-09-18-git-c373636f55-full_build/ffmpeg-2025-09-18-git-c373636f55-full_build/bin/ffprobe.exe"

AUDIO_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
AMBIENT_DIR = os.path.join(AUDIO_DIR, "sfx")
OUTPUT = os.path.join(AUDIO_DIR, "opening_ambient.ogg")

# 采样率
SR = 44100
# 总时长
TOTAL_DUR = 55.0
# 实际时间轴（来自 narration_timeline.md）
#   seg1: 0.050s → 4.898s  (画面1)
#   seg2: 4.948s → 13.732s (画面2)
#   seg3: 13.782s → 18.342s (画面3)
#   seg4: 18.392s → 27.728s (画面4)
#   seg5: 27.778s → 31.066s (画面5)
#   seg6: 31.116s → 35.580s (画面6)
#   注意: 36.080s → 37.208s (画面7-注意)
#   正文: 37.208s → 46.544s (画面7-正文)
#   静音: 46.544s → 55.000s (画面9-10 + )

# 设计文档中的画面划分（与实际音频对齐）：
SCENE_1_END = 4.9      # 画面1结束
SCENE_2_START = 0.05    # 画面2开始（纸板摩擦 + 城市白噪）
SCENE_2_END = 13.7
SCENE_3_START = 13.7    # 个体画面
SCENE_3_END = 18.3
SCENE_4_START = 18.3    # 碎裂
SCENE_4_END = 27.7
SCENE_5_START = 27.7    # 碎片特写
SCENE_5_END = 31.1
SCENE_6_START = 31.1    # 任务简报
SCENE_6_END = 35.5
SCENE_7_START = 36.0    # 警告页
SCENE_7_END = 41.1
SCENE_8_START = 37.2    # 老顾闪现（嵌入在画面7正文中）
SCENE_9_START = 38.2
SCENE_9_END = 46.5
SCENE_10_START = 46.5
SCENE_10_END = 55.0


def run_ffmpeg(cmd, desc=""):
    """运行 ffmpeg 命令"""
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  [FAIL] {desc}: {result.stderr[:300]}")
        return False
    if desc:
        print(f"  [OK] {desc}")
    return True


def get_duration(path):
    result = subprocess.run(
        [FFPROBE, "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", path],
        capture_output=True, text=True
    )
    return float(result.stdout.strip()) if result.stdout.strip() else 0


def main():
    os.makedirs(AMBIENT_DIR, exist_ok=True)
    
    print("=" * 60)
    print("  溯光计划 环境音效生成")
    print("=" * 60)
    
    elements = []  # [(filepath, start_time, volume_db)]
    
    # ============================================================
    # 画面1 (0s → 4.9s): 系统启动音 — 500-800Hz 正弦波，0.3s，渐入渐出
    # ============================================================
    print("\n[画面1] 系统启动音 (500-800Hz, 0.3s)")
    startup_path = os.path.join(AMBIENT_DIR, "e01_startup.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            "sine=frequency=500:duration=0.15:sample_rate=44100[low];"
            "sine=frequency=800:duration=0.15:sample_rate=44100[high];"
            "[low][high]amix=inputs=2:duration=first:weights=0.6 0.4,"
            "volume=0.25,"
            "afade=t=in:d=0.05,afade=t=out:d=0.1"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        startup_path
    ]
    run_ffmpeg(cmd, "系统启动音")
    elements.append((startup_path, 0.05, -12))
    
    # ============================================================
    # 画面2 (0.05s → 13.7s): 纸板摩擦 + 城市白噪
    # ============================================================
    print("\n[画面2] 纸板摩擦声 (粉噪+低通+调制, 14s)")
    paper_rub_path = os.path.join(AMBIENT_DIR, "e02_paper_rub.wav")
    dur_paper = SCENE_2_END - SCENE_2_START
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            f"anoisesrc=d={dur_paper}:c=pink:r={SR}:a=0.02,"
            "lowpass=f=800,"
            "highpass=f=60,"
            "volume=0.15,"
            "afade=t=in:d=0.5,afade=t=out:d=1.0"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        paper_rub_path
    ]
    run_ffmpeg(cmd, "纸板摩擦")
    elements.append((paper_rub_path, SCENE_2_START, -18))
    
    print("\n[画面2] 城市白噪音 (白噪+低通2kHz, 14s)")
    city_path = os.path.join(AMBIENT_DIR, "e02_city_noise.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            f"anoisesrc=d={dur_paper}:c=white:r={SR}:a=0.01,"
            "lowpass=f=2000,"
            "highpass=f=100,"
            "volume=0.06,"
            "afade=t=in:d=2,afade=t=out:d=2"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        city_path
    ]
    run_ffmpeg(cmd, "城市白噪")
    elements.append((city_path, SCENE_2_START, -24))
    
    # ============================================================
    # 画面3 (13.7s → 18.3s): 磁带停止声 — 短白噪爆发 + 高频衰减
    # ============================================================
    print("\n[画面3] 磁带停止声 x2 (0.05s 白噪爆发+高频衰减)")
    for i, t in enumerate([14.3, 14.8]):
        tape_path = os.path.join(AMBIENT_DIR, f"e03_tape_stop_{i}.wav")
        cmd = [
            FFMPEG, "-y",
            "-f", "lavfi",
            "-i", (
                "anoisesrc=d=0.08:c=white:r=44100:a=0.5,"
                "highpass=f=2000,"
                "volume='if(gt(t,0.03), 0.1, 1.0)':eval=frame,"
                "afade=t=out:d=0.03"
            ),
            "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
            tape_path
        ]
        run_ffmpeg(cmd, f"磁带停止声 #{i+1}")
        elements.append((tape_path, t, -6))
    
    # ============================================================
    # 画面4 (18.3s → 27.7s): 撕裂声 + 低频地鸣
    # ============================================================
    print("\n[画面4] 纸板撕裂声 (噪声爆发+快速衰减, 0.4s)")
    tear_path = os.path.join(AMBIENT_DIR, "e04_tear.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            "anoisesrc=d=0.5:c=white:r=44100:a=0.8,"
            "bandpass=f=800:width_type=h:width=1200,"
            "volume='if(lt(t,0.1), 1.0, exp(-5*(t-0.1)))':eval=frame,"
            "highpass=f=200"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        tear_path
    ]
    run_ffmpeg(cmd, "撕裂声")
    # 立体声展开效果——放两个副本，微微错开的延迟
    elements.append((tear_path, SCENE_4_START, -3))
    
    print("\n[画面4] 低频地鸣 (~30Hz, 9.4s, 渐升)")
    rumble4_path = os.path.join(AMBIENT_DIR, "e04_rumble_scene4.wav")
    dur_rumble4 = SCENE_4_END - SCENE_4_START
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            f"sine=frequency=30:duration={dur_rumble4}:sample_rate={SR},"
            "volume=0.08,"
            # 渐升效果：前6s 从0.3到1.0，然后保持，最后淡出
            "volume='if(lt(t,6), 0.3+0.7*t/6, 1.0)':eval=frame,"
            "afade=t=in:d=2.0,afade=t=out:d=1.0"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        rumble4_path
    ]
    run_ffmpeg(cmd, "低频地鸣(画面4, 渐升)")
    elements.append((rumble4_path, SCENE_4_START, -24))
    
    print("\n[画面5] 低频地鸣持续 (~30Hz, 3.4s)")
    rumble5_path = os.path.join(AMBIENT_DIR, "e05_rumble_scene5.wav")
    dur_rumble5 = SCENE_5_END - SCENE_5_START
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            f"sine=frequency=30:duration={dur_rumble5}:sample_rate={SR},"
            "volume=0.12,"
            "afade=t=in:d=0.3,afade=t=out:d=1.0"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        rumble5_path
    ]
    run_ffmpeg(cmd, "低频地鸣(画面5, 持续)")
    elements.append((rumble5_path, SCENE_5_START, -12))
    
    # ============================================================
    # 画面6 (31.1s → 35.5s): 打字机击键声 — 逐字同步
    # ============================================================
    print("\n[画面6] 打字机击键声 (20次——对应任务文本)")
    # 文本: "进入碎片——找到源印——净化世界——修复万象——"
    # 约20个击键（每个字一个咔-嗒）
    # 简化为在 31.5s-34.5s 之间均匀分布 20 次咔嗒声
    
    for i in range(20):
        t_key = SCENE_6_START + 0.5 + i * 0.15  # 均匀分布
        key_path = os.path.join(AMBIENT_DIR, f"e06_typewriter_{i:02d}.wav")
        cmd = [
            FFMPEG, "-y",
            "-f", "lavfi",
            "-i", (
                "anoisesrc=d=0.04:c=white:r=44100:a=0.6,"
                "bandpass=f=2000:width_type=h:width=500,"
                "volume='if(lt(t,0.01), 1.0, exp(-30*(t-0.01)))':eval=frame"
            ),
            "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
            key_path
        ]
        run_ffmpeg(cmd, f"打字机 #{i+1}")
        elements.append((key_path, t_key, -9))
    
    # ============================================================
    # 画面7 (36.0s → 37.2s): 盖章闷响 + 翻页声
    # ============================================================
    print("\n[画面7] 盖章闷响 (低频冲击, ~0.15s)")
    stamp_path = os.path.join(AMBIENT_DIR, "e07_stamp.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            "sine=frequency=80:duration=0.08:sample_rate=44100,"
            "volume='exp(-20*t)':eval=frame,"
            "volume=0.6"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        stamp_path
    ]
    run_ffmpeg(cmd, "盖章声")
    elements.append((stamp_path, 36.08, -4))  # 和"注意——"同步
    
    print("\n[画面7] 翻页声 (短纸声, ~0.2s)")
    page_path = os.path.join(AMBIENT_DIR, "e07_page_turn.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            "anoisesrc=d=0.2:c=pink:r=44100:a=0.3,"
            "bandpass=f=500:width_type=h:width=400,"
            "volume='if(lt(t,0.05), 1.0, exp(-10*(t-0.05)))':eval=frame"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        page_path
    ]
    run_ffmpeg(cmd, "翻页声")
    elements.append((page_path, 36.5, -18))
    
    # ============================================================
    # 画面8 (37.2s → 38.2s): 风声切过
    # ============================================================
    print("\n[画面8] 风声切过 (0.1s, 滤波噪声)")
    wind_path = os.path.join(AMBIENT_DIR, "e08_wind.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            "anoisesrc=d=0.15:c=white:r=44100:a=0.5,"
            "bandpass=f=1500:width_type=h:width=1000,"
            "volume='if(lt(t,0.03), t/0.03, exp(-15*(t-0.03)))':eval=frame"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        wind_path
    ]
    run_ffmpeg(cmd, "风声切过")
    elements.append((wind_path, 37.25, -8))  # 和"请勿过度共情"同步
    
    # ============================================================
    # 画面9 (38.2s → 46.5s): 无声
    # ============================================================
    print("\n[画面9] 无声（无需生成）")
    
    # ============================================================
    # 画面10 (46.5s → 55.0s): 银箔触碰声 + 低持续音
    # ============================================================
    print("\n[画面10] 银箔纸触碰声 (高频 transient, ~0.08s)")
    foil_path = os.path.join(AMBIENT_DIR, "e10_foil.wav")
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            "anoisesrc=d=0.1:c=white:r=44100:a=0.6,"
            "highpass=f=6000,"
            "volume='exp(-30*t)':eval=frame"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        foil_path
    ]
    run_ffmpeg(cmd, "银箔触碰声")
    elements.append((foil_path, SCENE_10_START, -16))
    
    print("\n[画面10] 低持续音 (星图过渡——和游戏星图音效同调)")
    drone_path = os.path.join(AMBIENT_DIR, "e10_drone.wav")
    dur_drone = SCENE_10_END - SCENE_10_START
    cmd = [
        FFMPEG, "-y",
        "-f", "lavfi",
        "-i", (
            f"sine=frequency=55:duration={dur_drone}:sample_rate={SR},"
            "volume=0.04,"
            "afade=t=in:d=1.5"
        ),
        "-c:a", "pcm_s16le", "-ar", str(SR), "-ac", "1",
        drone_path
    ]
    run_ffmpeg(cmd, "低持续音")
    elements.append((drone_path, SCENE_10_START, -18))
    
    # ============================================================
    # 最终混音
    # ============================================================
    print("\n" + "=" * 60)
    print("  混音中...")
    print("=" * 60)
    
    # 方法：为每个元素创建 55s 的静音轨道，用 adelay 将元素放到正确位置，然后 amix 全部混合
    # 这样最简单且精确
    
    filter_parts = []
    input_files = []
    input_labels = []
    
    for i, (elem_path, start_time, vol_db) in enumerate(elements):
        input_files.append(elem_path)
        label = f"{i}"
        input_labels.append(label)
        
        # 延迟（毫秒）+ 音量调整
        delay_ms = int(start_time * 1000)
        vol_linear = 10 ** (vol_db / 20.0)
        
        filter_parts.append(
            f"[{label}:a]adelay={delay_ms}:all=1,volume={vol_linear:.4f}[a{label}]"
        )
    
    n = len(elements)
    mix_inputs = "".join([f"[a{i}]" for i in range(n)])
    filter_all = ";".join(filter_parts) + f";{mix_inputs}amix=inputs={n}:duration=longest:dropout_transition=0:normalize=0[out]"
    
    cmd = [FFMPEG, "-y"]
    for f in input_files:
        cmd.extend(["-i", f])
    cmd.extend([
        "-filter_complex", filter_all,
        "-map", "[out]",
        "-c:a", "libvorbis",
        "-q:a", "5",
        "-t", str(TOTAL_DUR),
        OUTPUT
    ])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"混音失败!")
        # Try to find the actual error
        for line in result.stderr.split("\n"):
            if "error" in line.lower() or "invalid" in line.lower() or "fail" in line.lower():
                print(f"  {line[:200]}")
        print(f"\n完整stderr:\n{result.stderr[:1000]}")
        return
    
    final_dur = get_duration(OUTPUT)
    file_size = os.path.getsize(OUTPUT)
    
    print(f"\n  [DONE] 环境音效完成:")
    print(f"    输出: {OUTPUT}")
    print(f"    时长: {final_dur:.3f}s")
    print(f"    大小: {file_size / 1024:.1f} KB")
    print(f"    元素数: {len(elements)}")
    
    # 时间轴总览
    print(f"\n  时间轴总览:")
    scene_labels = [
        (0, SCENE_1_END, "画面1 系统启动"),
        (SCENE_2_START, SCENE_2_END, "画面2 万象全景+纸板摩擦+城市白噪"),
        (SCENE_3_START, SCENE_3_END, "画面3 个体画面+磁带停止声"),
        (SCENE_4_START, SCENE_4_END, "画面4 碎裂+撕裂+地鸣"),
        (SCENE_5_START, SCENE_5_END, "画面5 碎片特写+地鸣"),
        (SCENE_6_START, SCENE_6_END, "画面6 任务简报+打字机"),
        (SCENE_7_START, SCENE_7_END, "画面7 警告页+盖章+翻页"),
        (SCENE_8_START, SCENE_8_START+1, "画面8 老顾闪现+风声"),
        (SCENE_9_START, SCENE_9_END, "画面9 logo+冥府(无声)"),
        (SCENE_10_START, SCENE_10_END, "画面10 星图过渡+银箔+低音"),
    ]
    for s, e, label in scene_labels:
        print(f"    [{s:5.1f}s → {e:5.1f}s] {label}")


if __name__ == "__main__":
    main()
