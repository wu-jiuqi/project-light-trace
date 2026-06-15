#!/usr/bin/env python3
"""处理撕裂遮罩图片：去除绿幕背景，缩放到目标尺寸"""

from PIL import Image
import numpy as np

def process_tear_overlay(input_path: str, output_path: str, target_size: tuple = (3840, 2160)):
    """
    处理撕裂遮罩图片：
    1. 去除绿幕背景（色键抠图）
    2. 缩放至目标尺寸
    3. 保存为带透明通道的 PNG
    """
    # 打开图片
    img = Image.open(input_path).convert('RGB')
    
    # 转换为 numpy 数组
    data = np.array(img)
    
    # 创建 Alpha 通道（绿幕变透明）
    # 绿色范围：R < 100, G > 150, B < 100
    r, g, b = data[:,:,0], data[:,:,1], data[:,:,2]
    
    # 更宽松的绿色检测，考虑边缘抗锯齿
    green_mask = (r < 120) & (g > 140) & (b < 120)
    
    # 创建 RGBA 图像
    rgba = np.zeros((data.shape[0], data.shape[1], 4), dtype=np.uint8)
    rgba[:,:,:3] = data
    rgba[:,:,3] = np.where(green_mask, 0, 255).astype(np.uint8)
    
    # 转回 PIL
    result = Image.fromarray(rgba, 'RGBA')
    
    # 缩放至目标尺寸（使用 Lanczos 高质量插值）
    result = result.resize(target_size, Image.LANCZOS)
    
    # 保存
    result.save(output_path, 'PNG')
    print(f"已保存: {output_path} ({target_size[0]}x{target_size[1]})")
    
    return result


if __name__ == "__main__":
    input_path = r"C:\Users\30114\.workbuddy\clipboard-images\clipboard-2026-06-08T17-02-56-928Z-0bbb5201.jpg"
    output_path = r"D:\WorkBuddy WorkSpace\project_light_trace\assets\papercraft\cinematic\opening_tear_overlay.png"
    
    process_tear_overlay(input_path, output_path, (3840, 2160))
