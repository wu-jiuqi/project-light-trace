"""
开场动画图片处理脚本
功能：缩放 + 透明背景处理
参考：SETUP_GUIDE.md 纹理规格表
"""
import os
from PIL import Image, ImageFilter

CINEMATIC_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "assets", "papercraft", "cinematic"
)
OUTPUT_DIR = CINEMATIC_DIR  # 直接覆盖（备份原文件到 _backup/）

# === 目标规格 ===
SPECS = {
    "opening_panorama_wanxiang.png": {
        "size": (3840, 2160),
        "transparent": False,
        "note": "万象全景——背景图，保持不透明"
    },
    "opening_logo_tianshu.png": {
        "size": (512, 512),
        "transparent": True,
        "note": "天枢logo——需要透明背景"
    },
    "opening_tear_overlay.png": {
        "size": (3840, 2160),
        "transparent": True,
        "note": "撕裂裂缝——仅裂缝线可见，其余透明"
    },
    "opening_coffee_hand.png": {
        "size": (512, 512),
        "transparent": True,
        "note": "手握咖啡杯——闪现叠加，需要透明"
    },
    "opening_child_swing.png": {
        "size": (512, 512),
        "transparent": True,
        "note": "小孩秋千——闪现叠加，需要透明"
    },
    "opening_old_hands.png": {
        "size": (512, 512),
        "transparent": True,
        "note": "老人手部——闪现叠加，需要透明"
    },
    "opening_laogu_silhouette.png": {
        "size": (256, 384),
        "transparent": True,
        "note": "老顾剪影——叠加层，需要透明"
    },
    "opening_folder_bg.png": {
        "size": (1920, 1080),
        "transparent": False,
        "note": "档案夹背景——全屏背景，不透明"
    },
    "opening_folder_stamp.png": {
        "size": (300, 150),
        "transparent": True,
        "note": "红色印章——叠加层，需要透明"
    },
    "opening_clouds.png": {
        "size": (1920, 400),
        "transparent": False,
        "note": "手撕纸云层——背景层"
    },
    "opening_dark_bg.png": {
        "size": (1920, 1080),
        "transparent": False,
        "note": "深色纸板背景——全屏背景，不透明"
    },
}


def analyze_background(img):
    """分析图像背景特征"""
    # 采样四角和边缘像素来判断背景色
    w, h = img.size
    corners = [
        img.getpixel((0, 0)),
        img.getpixel((w-1, 0)),
        img.getpixel((0, h-1)),
        img.getpixel((w-1, h-1)),
        img.getpixel((w//2, 0)),
        img.getpixel((w//2, h-1)),
        img.getpixel((0, h//2)),
        img.getpixel((w-1, h//2)),
    ]
    avg = tuple(sum(c[i] for c in corners) // len(corners) for i in range(3))
    is_light = all(v > 200 for v in avg)
    is_dark = all(v < 50 for v in avg)
    return avg, is_light, is_dark


def remove_background(img, tolerance=40, feather=2):
    """
    智能移除背景：
    1. 采样边缘判断主背景色
    2. 将接近背景色的像素设为透明
    3. 带羽化避免硬边
    """
    w, h = img.size
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # 采样边缘
    edge_pixels = []
    for x in range(0, w, max(1, w//20)):
        edge_pixels.append(img.getpixel((x, 0)))
        edge_pixels.append(img.getpixel((x, h-1)))
    for y in range(0, h, max(1, h//20)):
        edge_pixels.append(img.getpixel((0, y)))
        edge_pixels.append(img.getpixel((w-1, y)))
    
    # 计算背景色中位数
    edge_pixels = [p for p in edge_pixels if len(p) >= 3]
    r_vals = sorted(p[0] for p in edge_pixels)
    g_vals = sorted(p[1] for p in edge_pixels)
    b_vals = sorted(p[2] for p in edge_pixels)
    n = len(r_vals)
    bg_color = (r_vals[n//2], g_vals[n//2], b_vals[n//2])
    
    # 判断背景是亮色还是暗色
    brightness = sum(bg_color) / 3
    is_light_bg = brightness > 128
    
    print(f"    背景色: RGB({bg_color[0]},{bg_color[1]},{bg_color[2]}) {'亮' if is_light_bg else '暗'}")
    
    # 创建 alpha mask
    pixels = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # 计算与背景色的距离
            dist = abs(r - bg_color[0]) + abs(g - bg_color[1]) + abs(b - bg_color[2])
            
            if dist < tolerance:
                # 在容差范围内 → 透明
                new_alpha = 0
            elif dist < tolerance + feather * 2:
                # 羽化过渡区
                ratio = (dist - tolerance) / (feather * 2)
                new_alpha = int(a * ratio)
            else:
                new_alpha = a
            
            pixels[x, y] = (r, g, b, new_alpha)
    
    return img


def process_tear_overlay(img):
    """
    特殊处理撕裂裂缝图：只保留暗色裂缝线，其余透明
    裂缝线特征：暗色（接近黑色），细线
    """
    w, h = img.size
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    pixels = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            brightness = (r + g + b) / 3
            
            # 保留暗色线条（裂缝），其他透明
            if brightness < 80:
                # 暗色裂缝线 → 保留，设为纯黑半透明
                pixels[x, y] = (0, 0, 0, int((80 - brightness) / 80 * 255))
            else:
                pixels[x, y] = (0, 0, 0, 0)
    
    return img


def resize_image(img, target_size):
    """高质量缩放"""
    return img.resize(target_size, Image.LANCZOS)


def main():
    print("=" * 60)
    print("  开场动画图片处理：缩放 + 透明背景")
    print("=" * 60)
    
    backup_dir = os.path.join(CINEMATIC_DIR, "_backup")
    os.makedirs(backup_dir, exist_ok=True)
    
    results = []
    
    for filename, spec in SPECS.items():
        filepath = os.path.join(CINEMATIC_DIR, filename)
        if not os.path.exists(filepath):
            print(f"\n  [跳过] {filename} — 文件不存在")
            results.append((filename, "MISSING", None, None))
            continue
        
        target_size = spec["size"]
        need_transparent = spec["transparent"]
        
        print(f"\n{'='*60}")
        print(f"  处理: {filename}")
        print(f"  {spec['note']}")
        print(f"  目标: {target_size[0]}×{target_size[1]} | 透明: {'是' if need_transparent else '否'}")
        
        # 备份原文件
        import shutil
        backup_path = os.path.join(backup_dir, filename)
        if not os.path.exists(backup_path):
            shutil.copy2(filepath, backup_path)
            print(f"  已备份 → _backup/{filename}")
        
        # 加载
        img = Image.open(filepath)
        orig_size = img.size
        orig_mode = img.mode
        print(f"  原始: {orig_size[0]}×{orig_size[1]} | 模式: {orig_mode}")
        
        # 步骤 1: 缩放
        if orig_size != target_size:
            print(f"  缩放: {orig_size[0]}×{orig_size[1]} → {target_size[0]}×{target_size[1]}")
            img = resize_image(img, target_size)
        
        # 步骤 2: 透明背景处理
        if need_transparent:
            if filename == "opening_tear_overlay.png":
                print(f"  透明处理: 裂痕专用——保留暗线，其余透明")
                img = process_tear_overlay(img)
            else:
                print(f"  透明处理: 智能边缘采样 + 去背景")
                img = remove_background(img, tolerance=35, feather=3)
        
        # 确保 RGBA 模式（需要透明时）
        if need_transparent and img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # 保存
        img.save(filepath, 'PNG', optimize=True)
        
        final_size = os.path.getsize(filepath)
        print(f"  输出: {img.size[0]}×{img.size[1]} | 模式: {img.mode} | 大小: {final_size/1024:.0f}KB")
        
        results.append((filename, "OK", orig_size, img.size))
    
    # 汇总
    print(f"\n{'='*60}")
    print(f"  处理完成汇总")
    print(f"{'='*60}")
    print(f"  {'文件':35s} {'原始':>12s} {'→ 输出':>12s} {'状态'}")
    print(f"  {'-'*35} {'-'*12} {'-'*12} {'-'*6}")
    
    for name, status, orig, final in results:
        orig_str = f"{orig[0]}×{orig[1]}" if orig else "—"
        final_str = f"{final[0]}×{final[1]}" if final else "—"
        print(f"  {name:35s} {orig_str:>12s} {final_str:>12s} {status}")
    
    print(f"\n  原图备份: {backup_dir}")
    print(f"  所有 .import 文件已保留（Godot 直接 reload 即可）")


if __name__ == "__main__":
    main()
