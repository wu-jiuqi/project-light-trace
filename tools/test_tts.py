"""快速测试 edge-tts SSML"""
import asyncio
import edge_tts

VOICE = "zh-CN-XiaoxiaoNeural"
OUT = "D:/WorkBuddy WorkSpace/project_light_trace/assets/audio/test_simple.mp3"

async def test_plain():
    """纯文本测试"""
    text = "编号TP二零七七零三溯光者。身份确认。"
    print(f"Testing plain text: {text}")
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(OUT)
    print("Done: test_simple.mp3")

async def test_ssml_simple():
    """最简 SSML 测试"""
    ssml = f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
    <voice name="{VOICE}">
        编号TP二零七七零三溯光者。身份确认。
    </voice>
</speak>'''
    print(f"Testing simple SSML...")
    communicate = edge_tts.Communicate(ssml, VOICE)
    await communicate.save(OUT.replace(".mp3", "_ssml.mp3"))
    print("Done: test_ssml.mp3")

async def test_ssml_prosody():
    """SSML + prosody 测试"""
    ssml = f'''<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="zh-CN">
    <voice name="{VOICE}">
        <prosody rate="+10%" pitch="0%">
            编号TP二零七七零三溯光者。身份确认。
        </prosody>
    </voice>
</speak>'''
    print(f"Testing SSML with prosody...")
    communicate = edge_tts.Communicate(ssml, VOICE)
    await communicate.save(OUT.replace(".mp3", "_prosody.mp3"))
    print("Done: test_prosody.mp3")

async def main():
    await test_plain()
    await test_ssml_simple()
    await test_ssml_prosody()

asyncio.run(main())
