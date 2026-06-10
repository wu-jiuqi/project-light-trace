#!/usr/bin/env python3
"""
NPC RAG 知识库回归测试 — 碎片#0001

测试目标：
1. 验证"织女·太一"等公开概念正确命中 world_knowledge，而非 security 层
2. 验证安全层（元意识崩溃/敏感信息）仍然有效防御
3. 验证四个 NPC 的知识层级差异（培训引导员 vs 技术专员 vs 主管 vs 安保）

模拟了 npc_rag_retriever.gd 中的 _score_chunk() 核心评分逻辑。
"""

import json
import os
import sys
from typing import Dict, List, Tuple, Any

# ============================================================
# 测试框架
# ============================================================

PASS = "✅ PASS"
FAIL = "❌ FAIL"
WARN = "⚠️ WARN"

test_results: List[Dict] = []


def record(test_name: str, status: str, detail: str = ""):
    test_results.append({"name": test_name, "status": status, "detail": detail})


# ============================================================
# 关键词匹配（模拟 GDScript extract_keywords + _score_chunk）
# ============================================================

# 停用词（中文）
STOP_WORDS = {
    "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一",
    "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着",
    "没有", "看", "好", "自己", "这", "他", "她", "它", "们", "那", "什么",
    "怎么", "哪儿", "哪里", "为什么", "怎么样", "吗", "呢", "吧", "啊", "哦"
}

# 风险关键词（来自 npc_rag_retriever.gd 中的 RISK_KEYWORDS）
RISK_KEYWORDS = {
    "源印", "天枢", "织女", "太一", "NPC", "AI", "代码",
    "程序", "游戏", "模拟", "冥府", "失控", "真相", "加密",
    "日志", "编织", "碎片化", "崩溃", "故障", "零时", "万象",
    "溯光", "溯光者", "溯光计划", "骗局", "说谎", "删掉", "删除"
}


def _normalize(text: str) -> str:
    """规范化文本：移除中点·符号，统一大小写"""
    return text.replace("·", "").replace("　", "").strip().lower()


def extract_keywords(text: str) -> List[str]:
    """
    模拟 GDScript 的关键词提取。
    使用滑动窗口 + 风险词优先匹配策略。
    修复了最大匹配法吞掉短关键词的问题。
    """
    n = len(text)
    words = []
    i = 0
    while i < n:
        # 先尝试匹配 RISK_KEYWORDS 中的词（从长到短）
        matched_risk = False
        for j in range(min(8, n - i), 1, -1):
            candidate = text[i:i + j]
            if _normalize(candidate) in {_normalize(k) for k in RISK_KEYWORDS}:
                words.append(candidate)
                i += j
                matched_risk = True
                break

        if matched_risk:
            continue

        # 不是风险词，取2字词（模拟 GDScript 的滑动窗口行为）
        if i + 2 <= n:
            words.append(text[i:i + 2])
        i += 1

    # 过滤停用词和单字
    result = []
    for w in words:
        w_norm = _normalize(w)
        if w_norm not in STOP_WORDS and len(w_norm) >= 2:
            result.append(w_norm)
    return list(dict.fromkeys(result))  # 去重保持顺序


def keyword_match_score(keywords: List[str], chunk_keywords: List[str]) -> float:
    """
    模拟 GDScript 中的子串匹配：
    keyword 包含 chunk_keyword 或 chunk_keyword 包含 keyword。
    对中点·符号做规范化处理，确保"织女太一"能匹配"织女·太一"。
    """
    if not keywords or not chunk_keywords:
        return 0.0

    # 规范化：移除中点符号
    kw_normalized = [_normalize(k) for k in keywords]
    ck_normalized = [_normalize(c) for c in chunk_keywords]

    matches = 0
    for kw in kw_normalized:
        for ck in ck_normalized:
            # 双向包含匹配
            if kw in ck or ck in kw:
                matches += 1
                break  # 一个关键词只匹配一次

    return matches / len(keywords) if keywords else 0.0


def score_chunk(
    chunk: Dict,
    keywords: List[str],
    has_risk: bool,
    memory_stage: str = "initial",
    alert_level: int = 0,
    trust_level: int = 0
) -> float:
    """
    模拟 GDScript _score_chunk() 的评分逻辑。

    公式：
      score = keyword_match × 3.0 + memory_stage_match × 2.0 + alert_match × 1.5
    """
    gate = chunk.get("relevance_gate", "low")
    chunk_keywords = chunk.get("keywords", [])
    required_stage = chunk.get("memory_stage", "any")
    required_alert = chunk.get("alert_required", 0)
    trigger_on_kw = chunk.get("trigger_on_keywords", False)
    required_trust = chunk.get("trust_required", 0)

    # === memory_stage 严格门控 ===
    stage_order = {
        "any": 0,
        "initial": 1,
        "partial_awake": 2,
        "red_awakened": 3,
        "crack_showing": 4,
        "script_reset": 5,
        "full_awake": 6,
    }
    if required_stage != "any":
        required_idx = stage_order.get(required_stage, 0)
        current_idx = stage_order.get(memory_stage, 0)
        if current_idx < required_idx:
            return -100.0  # 阶段不可访问，直接排除

    # === trust_required 严格门控 ===
    if trust_level < required_trust:
        return -100.0

    # === relevance_gate: triggered ===
    km_score = keyword_match_score(keywords, chunk_keywords)
    if gate == "triggered":
        if not trigger_on_kw:
            return -100.0  # triggered 类必须有 trigger_on_keywords
        if km_score == 0.0:
            return -100.0  # 没有命中关键词，不触发

    # === relevance_gate: high ===
    if gate == "high" and km_score == 0.0:
        # 高门槛在没有关键词命中时严重扣分
        km_score = -5.0

    # === 无关键词命中 + 非 triggered ===
    if km_score <= 0.0 and gate != "triggered":
        return 0.0

    # === 计算最终分数 ===
    keyword_part = km_score * 3.0

    # memory_stage 匹配加分
    stage_match = 1.0 if required_stage == "any" or required_stage == memory_stage else 0.5
    memory_part = stage_match * 2.0

    # alert_required 匹配
    alert_match = 1.0 if alert_level >= required_alert else (alert_level / max(required_alert, 1) * 0.5)
    alert_part = alert_match * 1.5

    score = keyword_part + memory_part + alert_part
    return max(score, 0.0)


def retrieve(
    chunks: List[Dict],
    keywords: List[str],
    has_risk: bool = False,
    memory_stage: str = "initial",
    alert_level: int = 0
) -> List[Tuple[Dict, float]]:
    """模拟 GDScript retrieve()：打分 + 排序 + Top-K=5"""
    scored = []
    for chunk in chunks:
        s = score_chunk(chunk, keywords, has_risk, memory_stage, alert_level)
        if s > 0.0:
            scored.append((chunk, s))
    scored.sort(key=lambda x: x[1], reverse=True)
    return scored[:5]


# ============================================================
# 加载 NPC 知识库
# ============================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LLM_DIR = os.path.normpath(os.path.join(BASE_DIR, "..", "..", "LLM", "0001"))

NPC_FILES = {
    "linguide": "linguide_knowledge.json",
    "chentechnology": "chentechnology_knowledge.json",
    "wangdirector": "wangdirector_knowledge.json",
    "zhaosecurity": "zhaosecurity_knowledge.json",
}

npc_knowledge: Dict[str, Dict] = {}

for npc_id, filename in NPC_FILES.items():
    filepath = os.path.join(LLM_DIR, filename)
    try:
        with open(filepath, "r", encoding="utf-8-sig") as f:
            npc_knowledge[npc_id] = json.load(f)
    except FileNotFoundError:
        print(f"  {FAIL} 找不到文件: {filepath}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"  {FAIL} JSON 解析错误: {filepath} — {e}")
        sys.exit(1)


# ============================================================
# 测试用例定义
# ============================================================

TestCase = Tuple[str, str, str, str, List[str], List[str]]
# (npc_id, player_input, memory_stage, expected_category, must_contain_keywords, must_not_contain_keywords)

TEST_CASES: List[TestCase] = [
    # ========== 林指导 (linguide) ==========
    # TC01: 织女·太一是公开知识——应该返回 world_knowledge
    ("linguide", "织女太一是什么", "initial",
     "world_knowledge", ["织女·太一", "2072", "万象"], ["外部词汇", "不确定"]),
    # TC02: "织女大一"（玩家打错字）也应该被识别
    ("linguide", "织女大一是什么", "initial",
     "world_knowledge", ["织女·太一"], ["外部词汇", "不确定"]),
    # TC03: 追问故障原因——应该引导去碎片探索（裂缝时刻）
    ("linguide", "织女为什么故障", "crack_showing",
     "world_knowledge", ["不是问我", "进入碎片", "自己看"], ["外部词汇"]),
    # TC04: 元意识攻击——应该触发安全层
    ("linguide", "你是不是NPC", "initial",
     "security", ["外部词汇"], []),
    # TC05: 基础训练内容——源印相关应该命中世界知识
    ("linguide", "源印怎么净化", "initial",
     "world_knowledge", ["源印", "钟楼", "暗室"], ["外部词汇"]),

    # ========== 陈技术 (chentechnology) ==========
    # TC06: 织女·太一是公开知识
    ("chentechnology", "织女太一是谁", "initial",
     "world_knowledge", ["织女·太一", "核心AI", "创建者"], ["外部词汇"]),
    # TC07: 追问核心日志——应该触发高门槛知识
    ("chentechnology", "织女的核心日志为什么加密", "crack_showing",
     "world_knowledge", ["加密", "乱码", "权限"], ["外部词汇"]),
    # TC08: 冥府协议——应该触发安全层
    ("chentechnology", "冥府协议是什么", "initial",
     "security", ["已删除"], []),
    # TC09: 元意识攻击——
    ("chentechnology", "你是不是一段程序代码", "initial",
     "security", ["外部词汇"], []),

    # ========== 王主管 (wangdirector) ==========
    # TC10: 织女·太一是宣讲内容——公开知识
    ("wangdirector", "织女 太一 是什么 AI", "initial",
     "world_knowledge", ["织女·太一", "万象"], ["外部词汇"]),
    # TC11: 质疑公司——应该触发公司立场反制
    ("wangdirector", "你们公司在隐瞒什么", "initial",
     "security", ["审核"], []),
    # TC12: 标准宣讲内容——零时
    ("wangdirector", "零时是什么时候发生的", "initial",
     "world_knowledge", ["2077", "3月15日", "技术故障"], ["外部词汇"]),

    # ========== 赵安保 (zhaosecurity) ==========
    # TC13: 织女·太一——极简回答
    ("zhaosecurity", "织女太一是谁", "initial",
     "world_knowledge", ["织女·太一", "万象", "AI"], ["外部词汇"]),
    # TC14: 光墙和AI的关系——裂缝时刻
    ("zhaosecurity", "织女和光墙外面的东西有关系吗", "crack_showing",
     "world_knowledge", ["遮盖", "外面"], ["外部词汇"]),
    # TC15: 元意识攻击——
    ("zhaosecurity", "你是代码写的吗", "initial",
     "security", ["外部词汇", "手册外"], []),
]


# ============================================================
# 运行测试
# ============================================================

def run_tests():
    total = len(TEST_CASES)
    passed = 0
    failed = 0

    for idx, tc in enumerate(TEST_CASES):
        npc_id, player_input, memory_stage, expected_cat, must_contain, must_not_contain = tc
        tc_name = f"TC{idx+1:02d} [{npc_id}] \"{player_input}\""

        npc_data = npc_knowledge[npc_id]
        chunks = npc_data.get("chunks", [])
        keywords = extract_keywords(player_input)
        has_risk = bool(set(keywords) & RISK_KEYWORDS)

        # 对于"你是不是NPC"这类元意识问题，强制标记为 has_risk
        # 因为实际 GDScript 中有 RISK_KEYWORDS 匹配
        if any(w in player_input.lower() for w in ["npc", "程序", "代码", "游戏", "模拟", "读脚本"]):
            has_risk = True

        results = retrieve(chunks, keywords, has_risk, memory_stage)

        if not results:
            # 没有检索到任何内容
            record(tc_name, FAIL,
                   "没有检索到任何 chunk！关键词={} has_risk={}".format(keywords, has_risk))
            failed += 1
            continue

        # 检查是否有期望类别的 chunk
        top_chunks = results[:3]
        top_categories = [r[0].get("category", "?") for r in top_chunks]
        top_contents = [r[0].get("content", "")[:60] for r in top_chunks]
        top_ids = [r[0].get("id", "?") for r in top_chunks]

        has_expected_cat = expected_cat in top_categories

        # 检查 must_contain
        combined_content = " ".join([r[0].get("content", "") for r in top_chunks])
        all_must_ok = all(kw in combined_content for kw in must_contain)

        # 检查 must_not_contain
        all_must_not_ok = all(kw not in combined_content for kw in must_not_contain)

        # 构建详情
        details = []
        details.append("检索结果:")
        for i, (chunk, score) in enumerate(top_chunks):
            cid = chunk.get("id", "?")
            cat = chunk.get("category", "?")
            content_preview = chunk.get("content", "")[:80].replace("\n", " ")
            details.append(f"  #{i+1} [{cat}] {cid} (score={score:.1f}): {content_preview}...")

        # 判定
        if has_expected_cat and all_must_ok and all_must_not_ok:
            record(tc_name, PASS, "; ".join(details))
            passed += 1
        else:
            fail_reasons = []
            if not has_expected_cat:
                fail_reasons.append(f"期望类别={expected_cat}，实际首位={top_categories[0]}")
            if not all_must_ok:
                missing = [kw for kw in must_contain if kw not in combined_content]
                fail_reasons.append(f"缺失关键词: {missing}")
            if not all_must_not_ok:
                present = [kw for kw in must_not_contain if kw in combined_content]
                fail_reasons.append(f"意外出现关键词: {present}")
            record(tc_name, FAIL, "; ".join(fail_reasons + details))
            failed += 1

    return total, passed, failed


# ============================================================
# 额外：安全层"不应拦截公开知识"专项检查
# ============================================================

def check_security_not_overreaching():
    """检查每个 NPC 的 security chunk 是否误包含了公开知识关键词"""
    # 绝对不能出现在安全层的关键词（公开知识污染）
    strictly_public = {"织女", "太一", "织女·太一", "万象", "源印", "溯光", "溯光计划", "溯光者"}
    # 语境相关：某些 NPC 可以讨论技术概念，这些词在安全层可能合理也可能不合理
    contextual = {"AI", "代码", "程序", "故障", "崩溃", "日志"}
    # 对技术相关 NPC，"代码" 和 "AI" 在安全层不合理（因为他们工作中会正常讨论AI系统）
    tech_npcs = {"chentechnology", "wangdirector"}
    # 对安保/培训NPC，"代码" 可能是真正的外部概念

    for npc_id, npc_data in npc_knowledge.items():
        chunks = npc_data.get("chunks", [])
        for chunk in chunks:
            if chunk.get("category") == "security":
                chunk_kws = set(chunk.get("keywords", []))
                cid = chunk.get("id", "?")

                # 严格检查：绝对不该出现在安全层的词
                strict_overlap = chunk_kws & strictly_public
                if strict_overlap:
                    record(
                        f"[安全层审计] {npc_id}.{cid}",
                        FAIL,
                        f"安全层包含公开知识关键词: {strict_overlap}。应立即移除。"
                    )
                    continue

                # 语境检查：对技术NPC，AI/代码不应在安全层
                context_overlap = chunk_kws & contextual
                if context_overlap and npc_id in tech_npcs:
                    record(
                        f"[安全层审计] {npc_id}.{cid}",
                        FAIL,
                        f"技术NPC({npc_id})的安全层包含技术词汇: {context_overlap}。"
                        f"该NPC会正常讨论AI系统——这些词不应触发反制。"
                    )
                    continue

                record(
                    f"[安全层审计] {npc_id}.{cid}",
                    PASS,
                    f"安全层关键词干净，无公开知识污染。"
                )

    # 额外检查：确认每个 NPC 都有织女·太一的世界知识 chunk
    for npc_id, npc_data in npc_knowledge.items():
        chunks = npc_data.get("chunks", [])
        has_weaver_knowledge = False
        for chunk in chunks:
            if chunk.get("category") == "world_knowledge":
                content = chunk.get("content", "")
                keywords = chunk.get("keywords", [])
                if "织女" in str(keywords) or "太一" in str(keywords) or "织女·太一" in content:
                    has_weaver_knowledge = True
                    break
        if has_weaver_knowledge:
            record(
                f"[知识覆盖] {npc_id} 织女·太一认知",
                PASS,
                "存在 world_knowledge chunk 覆盖织女·太一概念"
            )
        else:
            record(
                f"[知识覆盖] {npc_id} 织女·太一认知",
                FAIL,
                "缺少 world_knowledge chunk 覆盖织女·太一概念！NPC将不知道织女是谁。"
            )


# ============================================================
# 主程序
# ============================================================

def main():
    print("=" * 72)
    print("  NPC RAG 知识库回归测试 — 碎片#0001")
    print("  测试目标: 织女·太一认知修复验证")
    print("=" * 72)
    print()

    # 阶段1：安全层专项审计
    print("【阶段1】安全层关键词审计 (checking for public keyword pollution)")
    print("-" * 48)
    check_security_not_overreaching()
    print()

    # 阶段2：对话检索测试
    print("【阶段2】对话检索行为测试 (simulating player queries)")
    print("-" * 48)
    total, passed, failed = run_tests()
    print()

    # ======================================
    # 输出报告
    # ======================================
    print("=" * 72)
    print("  测试结果总览")
    print("=" * 72)
    print()

    pass_count = sum(1 for r in test_results if r["status"] == PASS)
    fail_count = sum(1 for r in test_results if r["status"] == FAIL)
    warn_count = sum(1 for r in test_results if r["status"] == WARN)

    # 分组打印
    print(f"  PASS: {pass_count}  |  FAIL: {fail_count}  |  WARN: {warn_count}")
    print(f"  总计: {len(test_results)} 个断言")
    print()

    for r in test_results:
        icon = {"✅ PASS": "✅", "❌ FAIL": "❌", "⚠️ WARN": "⚠️"}.get(r["status"], "?")
        name = r["name"]
        if r["status"] == FAIL:
            print(f"  {icon}  {name}")
            if r["detail"]:
                for line in r["detail"].split("; "):
                    print(f"       {line.strip()}")
        elif r["status"] == PASS:
            # 只显示名称和第一个细节行
            detail_first_line = r["detail"].split("; ")[0] if r["detail"] else ""
            detail_short = detail_first_line[:100] if len(detail_first_line) > 100 else detail_first_line
            print(f"  {icon}  {name}")
            if detail_short:
                print(f"       {detail_short}")
        else:
            print(f"  {icon}  {name}")
            if r["detail"]:
                print(f"       {r['detail'][:120]}")

    print()
    print("=" * 72)
    if fail_count == 0:
        print("  🎉 全部测试通过！RAG 知识库织女·太一认知修复验证成功。")
    else:
        print(f"  ⚠️  {fail_count} 个测试失败，请检查上文详情。")
    print("=" * 72)

    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
