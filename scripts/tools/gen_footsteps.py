"""
合成纸雕风格脚步声 WAV — 4 个变体
- 纸板触感：过滤噪声 + 低频闷响
- LPF@8kHz，峰值 -12dBFS
- 步频匹配 SWAY_SPEED=10.0 → 每步 ~0.314s

输出：assets/audio/sfx/footstep_01.wav ~ footstep_04.wav
"""

import struct
import math
import random
import os

SAMPLE_RATE = 44100
BIT_DEPTH = 16
OUTPUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "assets", "audio", "sfx"
)


def generate_white_noise(n_samples: int, seed: int) -> list[float]:
    """生成 [-0.5, 0.5] 均匀白噪声"""
    rng = random.Random(seed)
    return [rng.random() - 0.5 for _ in range(n_samples)]


def simple_lpf(samples: list[float], cutoff_hz: float, sr: int) -> list[float]:
    """一阶 IIR 低通滤波器（简化 RC 滤波）"""
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    dt = 1.0 / sr
    alpha = dt / (rc + dt)
    filtered = [0.0] * len(samples)
    filtered[0] = samples[0] * alpha
    for i in range(1, len(samples)):
        filtered[i] = filtered[i - 1] + alpha * (samples[i] - filtered[i - 1])
    return filtered


def simple_bpf(samples: list[float], low_hz: float, high_hz: float, sr: int) -> list[float]:
    """级联低通+高通近似带通"""
    # 先高通（低通取差值）
    lp = simple_lpf(samples, low_hz, sr)
    hp = [s - lp[i] for i, s in enumerate(samples)]
    return simple_lpf(hp, high_hz, sr)


def sine_wave(freq: float, n_samples: int, sr: int, phase: float = 0.0) -> list[float]:
    """生成正弦波"""
    return [math.sin(2.0 * math.pi * freq * i / sr + phase) for i in range(n_samples)]


def adsr_envelope(n_samples: int, sr: int, attack: float, decay: float, sustain: float = 0.0, release: float = 0.02) -> list[float]:
    """简化 ADSR 包络（attack→decay→sustain→release）"""
    env = []
    n_attack = int(attack * sr)
    n_decay = int(decay * sr)
    n_release = int(release * sr)
    n_sustain = n_samples - n_attack - n_decay - n_release
    if n_sustain < 0:
        n_sustain = 0

    # Attack: 0→1
    for i in range(n_attack):
        env.append(i / max(n_attack, 1))

    # Decay: 1→sustain
    for i in range(n_decay):
        t = i / max(n_decay, 1)
        env.append(1.0 - (1.0 - sustain) * t)

    # Sustain
    for _ in range(n_sustain):
        env.append(sustain)

    # Release: sustain→0
    for i in range(n_release):
        t = i / max(n_release, 1)
        env.append(sustain * (1.0 - t))

    # Trim to n_samples
    return env[:n_samples]


def make_footstep(duration: float, sr: int, seed: int, freq_thud: float,
                  thud_mix: float, noise_mix: float, lpf_cutoff: float,
                  attack: float, decay: float, bp_low: float, bp_high: float) -> list[float]:
    """
    合成单次脚步声
    - duration: 总时长 (s)
    - freq_thud: 低频闷响频率 (Hz)
    - thud_mix: 闷响混合比例
    - noise_mix: 纸板噪声混合比例
    - bp_low/bp_high: 纸板噪声带通范围 (Hz)
    """
    n = int(duration * sr)

    # 1. 低频闷响（模拟脚踩硬纸板的沉闷声）
    thud = sine_wave(freq_thud, n, sr, random.Random(seed + 100).random() * math.pi)
    # 闷响用快速衰减包络
    thud_env = adsr_envelope(n, sr, attack=0.003, decay=0.025, sustain=0.0, release=0.01)
    thud = [t * e for t, e in zip(thud, thud_env)]

    # 2. 纸板摩擦/皱褶噪声
    noise = generate_white_noise(n, seed)
    noise_bp = simple_bpf(noise, bp_low, bp_high, sr)
    noise_env = adsr_envelope(n, sr, attack=attack, decay=decay, sustain=0.0, release=0.02)
    noise_shaped = [n * e for n, e in zip(noise_bp, noise_env)]

    # 3. 混合
    mixed = [thud[i] * thud_mix + noise_shaped[i] * noise_mix for i in range(n)]

    # 4. 整体 LPF
    mixed = simple_lpf(mixed, lpf_cutoff, sr)

    # 5. 归一化到 -12dBFS（峰值 0.2512 线性）
    peak = max(abs(x) for x in mixed)
    if peak > 0:
        target_peak = 10.0 ** (-12.0 / 20.0)  # ≈ 0.2512
        scale = target_peak / peak
        mixed = [x * scale for x in mixed]

    return mixed


def write_wav(filename: str, samples: list[float], sr: int) -> None:
    """写入 16-bit mono WAV"""
    n = len(samples)
    data_size = n * 2
    with open(filename, "wb") as f:
        # RIFF header
        f.write(b"RIFF")
        f.write(struct.pack("<I", 36 + data_size))
        f.write(b"WAVE")
        # fmt chunk
        f.write(b"fmt ")
        f.write(struct.pack("<I", 16))       # chunk size
        f.write(struct.pack("<H", 1))        # PCM
        f.write(struct.pack("<H", 1))        # mono
        f.write(struct.pack("<I", sr))
        f.write(struct.pack("<I", sr * 2))   # byte rate
        f.write(struct.pack("<H", 2))        # block align
        f.write(struct.pack("<H", 16))       # bits per sample
        # data chunk
        f.write(b"data")
        f.write(struct.pack("<I", data_size))
        for s in samples:
            val = int(max(-32768, min(32767, s * 32767)))
            f.write(struct.pack("<h", val))


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    sr = SAMPLE_RATE

    # 4 个变体参数：低频、噪声中心频率、时长、种子
    variants = [
        {"seed": 42,   "freq_thud": 90,  "bp_low": 1500, "bp_high": 5000, "duration": 0.090, "attack": 0.005, "decay": 0.040, "thud_mix": 0.35, "noise_mix": 0.60},
        {"seed": 73,   "freq_thud": 105, "bp_low": 1800, "bp_high": 5500, "duration": 0.085, "attack": 0.004, "decay": 0.038, "thud_mix": 0.32, "noise_mix": 0.58},
        {"seed": 119,  "freq_thud": 82,  "bp_low": 1200, "bp_high": 4500, "duration": 0.095, "attack": 0.006, "decay": 0.042, "thud_mix": 0.38, "noise_mix": 0.62},
        {"seed": 201,  "freq_thud": 98,  "bp_low": 2000, "bp_high": 6000, "duration": 0.088, "attack": 0.004, "decay": 0.036, "thud_mix": 0.33, "noise_mix": 0.57},
    ]

    for i, v in enumerate(variants):
        samples = make_footstep(
            duration=v["duration"],
            sr=sr,
            seed=v["seed"],
            freq_thud=v["freq_thud"],
            thud_mix=v["thud_mix"],
            noise_mix=v["noise_mix"],
            lpf_cutoff=8000,  # LPF@8kHz per spec
            attack=v["attack"],
            decay=v["decay"],
            bp_low=v["bp_low"],
            bp_high=v["bp_high"],
        )

        filename = os.path.join(OUTPUT_DIR, f"footstep_{i + 1:02d}.wav")
        write_wav(filename, samples, sr)
        print(f"  OK {filename}  ({len(samples)} samples, {len(samples) / sr:.3f}s)")

    print(f"\nDone: {len(variants)} footstep variants -> {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
