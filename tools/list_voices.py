import asyncio
import edge_tts

async def main():
    voices = await edge_tts.list_voices()
    for v in voices:
        if v['Locale'].startswith('zh-CN') and v['Gender'] == 'Female':
            styles = v.get('StyleList', '')
            print(f"{v['ShortName']:40s} {v['Locale']:10s} VoiceType:{v.get('VoiceType','N/A'):20s} Styles:{styles}")

asyncio.run(main())
