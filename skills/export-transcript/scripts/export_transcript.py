#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
export_transcript.py
Antigravity 대화 기록(.jsonl)을 AI 사고 과정(Thinking)을 포함한 고품질 Markdown 문서로 변환·내보내는 도구.
"""

import os
import sys
import json
import re
import argparse
from datetime import datetime, timezone, timedelta

# UTF-8 출력 강제 (윈도우 콘솔 한글 깨짐 방지)
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

def fix_windows_argv():
    """Windows 환경에서 PowerShell/CMD가 한글 인자를 망가뜨리는 것을 방지하고 순수 UTF-16 원형 복원"""
    if sys.platform != "win32":
        return sys.argv
    try:
        import ctypes
        from ctypes import wintypes
        GetCommandLineW = ctypes.windll.kernel32.GetCommandLineW
        GetCommandLineW.restype = wintypes.LPCWSTR
        GetCommandLineW.argtypes = []

        CommandLineToArgvW = ctypes.windll.shell32.CommandLineToArgvW
        CommandLineToArgvW.restype = ctypes.POINTER(wintypes.LPWSTR)
        CommandLineToArgvW.argtypes = [wintypes.LPCWSTR, ctypes.POINTER(ctypes.c_int)]

        cmd_line = GetCommandLineW()
        argc = ctypes.c_int()
        argv_p = CommandLineToArgvW(cmd_line, ctypes.byref(argc))
        argv = [argv_p[i] for i in range(argc.value)]
        ctypes.windll.kernel32.LocalFree(argv_p)
        # 스크립트 실행 형태 (python script.py ...) 맞추기
        if len(argv) > 1 and argv[1].endswith('.py'):
            return argv[1:]
        elif len(argv) > 2 and argv[2].endswith('.py'):
            return argv[2:]
        return argv
    except Exception:
        return sys.argv

try:
    import tiktoken
    HAS_TIKTOKEN = True
except ImportError:
    HAS_TIKTOKEN = False

KST = timezone(timedelta(hours=9))

def to_kst(dt_str):
    if not dt_str:
        return ""
    try:
        dt_clean = dt_str.replace("Z", "+00:00")
        dt = datetime.fromisoformat(dt_clean)
        return dt.astimezone(KST).strftime("%Y-%m-%d %H:%M:%S (KST)")
    except Exception:
        return dt_str

def to_short_kst(dt_str):
    if not dt_str:
        return ""
    try:
        dt_clean = dt_str.replace("Z", "+00:00")
        dt = datetime.fromisoformat(dt_clean)
        return dt.astimezone(KST).strftime("%m/%d %H:%M:%S")
    except Exception:
        return dt_str

def sanitize_filename(name):
    name = re.sub(r'[\\/*?:"<>|]', '', name)
    name = re.sub(r'\s+', '_', name.strip())
    return name[:50] if len(name) > 50 else name

def parse_user_content(content):
    if not content:
        return "", ""
    req_match = re.search(r'<USER_REQUEST>(.*?)</USER_REQUEST>', content, re.DOTALL)
    if req_match:
        user_req = req_match.group(1).strip()
        meta = content.replace(req_match.group(0), '').strip()
        return user_req, meta
    return content.strip(), ""

def clean_thinking(thinking_text):
    if not thinking_text:
        return ""
    paragraphs = [p.strip() for p in thinking_text.split('\n\n') if p.strip()]
    lines = []
    for p in paragraphs:
        cleaned_p = re.sub(r'\s*\n\s*', ' ', p)
        lines.append(f"> {cleaned_p}")
    return "\n>\n".join(lines)

def summarize_tool(name, args, result_content):
    if name == 'read_file':
        path = args.get('Path', '')
        basename = os.path.basename(path.replace('\\', '/'))
        return f"- 🛠️ `read_file({basename})`: 파일 내용 확인 완료"
    elif name == 'search_web':
        query = args.get('query', '')
        summary = "검색 완료"
        first_line = result_content.strip().split('\n')[0] if result_content else ""
        if len(first_line) > 60:
            first_line = first_line[:60] + "..."
        if first_line:
            summary = f"검색 결과 확인 ({first_line})"
        return f"- 🛠️ `search_web('{query}')`: {summary}"
    elif name == 'run_command':
        cmd = args.get('CommandLine', '')
        summary = args.get('toolSummary', '명령어 실행')
        return f"- 🛠️ `run_command`: {summary} (`{cmd[:40]}...`)"
    elif name == 'write_file':
        path = args.get('Path', '')
        basename = os.path.basename(path.replace('\\', '/'))
        return f"- 🛠️ `write_file({basename})`: 파일 작성 완료"
    elif name == 'edit_file':
        path = args.get('Path', '')
        basename = os.path.basename(path.replace('\\', '/'))
        return f"- 🛠️ `edit_file({basename})`: 파일 수정 완료"
    else:
        return f"- 🛠️ `{name}`: 도구 실행 완료"

def find_conversation_by_keyword(keyword, brain_dir):
    """제목이나 키워드로 가장 일치하는 대화 디렉터리를 탐색"""
    keyword_lower = keyword.strip().lower()
    if not keyword_lower or not os.path.isdir(brain_dir):
        return None

    entries = os.listdir(brain_dir)
    candidate_dirs = []
    for d in entries:
        if d == 'tempmediaStorage':
            continue
        full_d = os.path.join(brain_dir, d)
        if os.path.isdir(full_d):
            try:
                mtime = os.path.getmtime(full_d)
                candidate_dirs.append((mtime, full_d, d))
            except Exception:
                continue

    candidate_dirs.sort(reverse=True, key=lambda x: x[0])

    for mtime, full_d, conv_id in candidate_dirs[:150]:
        log_file = os.path.join(full_d, ".system_generated", "logs", "transcript.jsonl")
        if not os.path.isfile(log_file):
            continue
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                lines = [f.readline() for _ in range(8)]
            combined_text = "".join(lines).lower()
            if keyword_lower in combined_text or keyword_lower in conv_id.lower():
                return conv_id
        except Exception:
            continue

    return None

def resolve_input_path(input_arg):
    # 1. 파일 경로 직접 지정
    if os.path.isfile(input_arg):
        return os.path.abspath(input_arg), None

    # 2. conversation:// URI 또는 UUID 정제
    conv_id = input_arg.strip()
    if conv_id.startswith("conversation://"):
        conv_id = conv_id.replace("conversation://", "").strip()

    brain_dir = os.path.expanduser(r"~\.gemini\antigravity\brain")
    possible_dir = os.path.join(brain_dir, conv_id)
    if os.path.isdir(possible_dir):
        full_log = os.path.join(possible_dir, ".system_generated", "logs", "transcript_full.jsonl")
        compact_log = os.path.join(possible_dir, ".system_generated", "logs", "transcript.jsonl")
        if os.path.isfile(full_log):
            return full_log, conv_id
        if os.path.isfile(compact_log):
            return compact_log, conv_id

    # 3. 키워드/제목으로 대화 자동 검색
    found_id = find_conversation_by_keyword(conv_id, brain_dir)
    if found_id:
        f_dir = os.path.join(brain_dir, found_id)
        full_log = os.path.join(f_dir, ".system_generated", "logs", "transcript_full.jsonl")
        compact_log = os.path.join(f_dir, ".system_generated", "logs", "transcript.jsonl")
        if os.path.isfile(full_log):
            return full_log, found_id
        if os.path.isfile(compact_log):
            return compact_log, found_id

    raise FileNotFoundError(f"대화 로그 파일을 찾을 수 없습니다 (키워드/경로: {input_arg})")

def convert(input_path, output_path=None, mode="compact", title=None):
    real_input_path, conv_id = resolve_input_path(input_path)
    
    with open(real_input_path, 'r', encoding='utf-8') as f:
        items = [json.loads(line) for line in f if line.strip()]

    if not items:
        raise ValueError("대화 로그 파일이 비어 있습니다.")

    start_time = to_kst(items[0].get('created_at'))
    end_time = to_kst(items[-1].get('created_at'))

    turns = []
    curr_turn = None
    turn_idx = 1
    pending_tool_calls = []

    for idx, item in enumerate(items):
        stype = item.get('type')
        source = item.get('source')
        created_at_short = to_short_kst(item.get('created_at'))
        created_at_full = to_kst(item.get('created_at'))
        
        if stype == 'USER_INPUT':
            user_msg, meta = parse_user_content(item.get('content', ''))
            curr_turn = {
                'turn_num': turn_idx,
                'user_time': created_at_short,
                'user_time_full': created_at_full,
                'user_msg': user_msg,
                'user_meta': meta,
                'events': []
            }
            turns.append(curr_turn)
            turn_idx += 1
            pending_tool_calls = []
            
        elif stype == 'SYSTEM_MESSAGE':
            if curr_turn:
                curr_turn['events'].append({
                    'type': 'system',
                    'time': created_at_full,
                    'text': item.get('content', '').strip()
                })
                
        elif stype == 'PLANNER_RESPONSE':
            thinking = item.get('thinking', '')
            tool_calls = item.get('tool_calls', [])
            content = item.get('content', '').strip()
            tokens_in = item.get('input_tokens')
            tokens_out = item.get('output_tokens')
            
            if tool_calls:
                for tc in tool_calls:
                    pending_tool_calls.append(tc)
                    
            if curr_turn is None:
                curr_turn = {
                    'turn_num': turn_idx,
                    'user_time': created_at_short,
                    'user_time_full': created_at_full,
                    'user_msg': '(초기화 세션)',
                    'user_meta': '',
                    'events': []
                }
                turns.append(curr_turn)
                turn_idx += 1
                
            curr_turn['events'].append({
                'type': 'planner',
                'time': created_at_full,
                'thinking': thinking,
                'tools': tool_calls,
                'content': content,
                'tokens_in': tokens_in,
                'tokens_out': tokens_out
            })
            
        elif stype == 'GENERIC':
            tool_call = pending_tool_calls.pop(0) if pending_tool_calls else {}
            name = tool_call.get('name', 'tool')
            args = tool_call.get('args', {})
            raw_content = item.get('content', '')
            
            if curr_turn:
                curr_turn['events'].append({
                    'type': 'generic',
                    'time': created_at_full,
                    'tool_name': name,
                    'tool_args': args,
                    'tool_content': raw_content,
                    'summary': summarize_tool(name, args, raw_content)
                })

    first_user_text = ""
    for t in turns:
        if t['user_msg'] and t['user_msg'] != '(초기화 세션)':
            first_user_text = t['user_msg'].split('\n')[0].strip()
            break
            
    doc_title = title
    if not doc_title:
        if first_user_text:
            clean_first = re.sub(r'/[a-zA-Z0-9_-]+', '', first_user_text).strip()
            clean_first = re.sub(r'[\\/*?:"<>|]', '', clean_first)
            doc_title = clean_first[:40] if clean_first else "대화_기록"
        else:
            doc_title = f"대화_기록_{conv_id}" if conv_id else "대화_기록"

    if not output_path:
        desktop_dir = os.path.join(os.path.expanduser("~"), "Desktop")
        file_slug = sanitize_filename(doc_title)
        output_path = os.path.join(desktop_dir, f"{file_slug}.md")

    lines = []
    lines.append(f"# 📋 {doc_title} (Transcript & AI Reasoning)")
    lines.append("")
    lines.append("> [!NOTE]")
    if conv_id:
        lines.append(f"> - **Conversation ID:** `{conv_id}`")
    lines.append(f"> - **총 대화 턴:** {len(turns)}턴 (총 {len(items)}단계)")
    lines.append(f"> - **대화 시작:** {start_time}")
    lines.append(f"> - **대화 종료:** {end_time}")
    lines.append(f"> - **내보내기 모드:** `{mode.upper()}` (AI 사고 과정 Thinking 100% 보존)")
    lines.append("")
    lines.append("---")
    lines.append("")

    lines.append("## 📑 목차 (Table of Contents)")
    lines.append("")
    for t in turns:
        preview = t['user_msg'].split('\n')[0][:45]
        anchor = f"턴-{t['turn_num']:02d}"
        lines.append(f"- [**턴 {t['turn_num']:02d}: {preview}...**](#{anchor})")
    lines.append("")
    lines.append("---")
    lines.append("")

    for t in turns:
        lines.append(f"## 턴 {t['turn_num']:02d}")
        lines.append(f"*일시: {t['user_time_full']}*")
        lines.append("")
        lines.append("**👤 User:**")
        lines.append(f"{t['user_msg']}")
        lines.append("")

        if mode == "full" and t['user_meta']:
            lines.append("<details>")
            lines.append("<summary>⚙️ <b>시스템 전달 메타데이터 (클릭하여 확인)</b></summary>\n")
            lines.append("```text")
            lines.append(t['user_meta'])
            lines.append("```\n</details>\n")

        thinkings = []
        tool_summaries = []
        raw_tools = []
        responses = []

        for ev in t['events']:
            if ev['type'] == 'planner':
                th = ev['thinking']
                if th:
                    thinkings.append(clean_thinking(th) if mode == "compact" else th)
                if ev['content']:
                    responses.append(ev['content'])
            elif ev['type'] == 'generic':
                tool_summaries.append(ev['summary'])
                raw_tools.append(ev)

        if thinkings:
            if mode == "compact":
                lines.append("**🧠 AI Thinking (사고 과정):**")
                for th in thinkings:
                    lines.append(th)
                    lines.append(">")
                lines.append("")
            else:
                lines.append("<details open>")
                lines.append("<summary>🧠 <b>AI Thinking (사고 과정 - 클릭하여 접기/펼치기)</b></summary>\n")
                for th in thinkings:
                    for line in th.split('\n'):
                        lines.append(f"> {line}" if line.strip() else ">")
                    lines.append(">")
                lines.append("\n</details>\n")

        if mode == "compact":
            if tool_summaries:
                lines.append("**🛠️ 실행된 도구:**")
                for ts in tool_summaries:
                    lines.append(ts)
                lines.append("")
        else:
            if raw_tools:
                for rt in raw_tools:
                    name = rt['tool_name']
                    args_str = json.dumps(rt['tool_args'], ensure_ascii=False, indent=2)
                    lines.append(f"<details>")
                    lines.append(f"<summary>🛠️ <b>도구 호출: <code>{name}</code></b></summary>\n")
                    lines.append(f"```json\n{args_str}\n```\n")
                    if rt['tool_content']:
                        lines.append(f"```text\n{rt['tool_content'].strip()}\n```")
                    lines.append("</details>\n")

        if responses:
            lines.append("**🤖 Assistant Response:**")
            lines.append("")
            for resp in responses:
                lines.append(resp)
                lines.append("")

        lines.append("---")
        lines.append("")

    final_content = "\n".join(lines)
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(final_content)

    token_info = ""
    if HAS_TIKTOKEN:
        try:
            enc = tiktoken.get_encoding('cl100k_base')
            token_count = len(enc.encode(final_content))
            token_info = f", 토큰 수: 약 {token_count:,} tokens"
        except Exception:
            pass

    print(f"[SUCCESS] 변환 완료: {output_path} (모드: {mode}, 글자 수: {len(final_content):,}{token_info})")
    return output_path

def main():
    custom_argv = fix_windows_argv()
    parser = argparse.ArgumentParser(description="Antigravity transcript exporter to Markdown")
    parser.add_argument("--input", "-i", required=True, help="대화 ID, conversation:// URL, 키워드 검색 또는 .jsonl 파일 경로")
    parser.add_argument("--output", "-o", default=None, help="저장할 마크다운 파일 경로 (기본값: 바탕화면)")
    parser.add_argument("--mode", "-m", choices=["compact", "full"], default="compact", help="내보내기 모드 (compact: 토큰 절약 최적화, full: 전체 원시 도구 내역 수록)")
    parser.add_argument("--title", "-t", default=None, help="문서 상단 제목 (기본값: 첫 질문 기반 자동 생성)")

    args = parser.parse_args(custom_argv[1:])
    try:
        convert(args.input, args.output, args.mode, args.title)
    except Exception as e:
        print(f"[ERROR] {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
