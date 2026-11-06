import sys
import json
import re

# Ensure standard streams use UTF-8
if hasattr(sys.stdin, "reconfigure"):
    sys.stdin.reconfigure(encoding='utf-8')
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding='utf-8')

PATTERNS = [
    r'(?:^|[;&|\r\n\(\)]\s*)(?:powershell\s+.*)?\b(Remove-Item)\b',
    r'(?:^|[;&|\r\n\(\)]\s*)(?:powershell\s+.*)?\b(ri)\s+',
    r'(?:^|[;&|\r\n\(\)]\s*)(?:cmd(?:\.exe)?\s+/c\s+)?\b(del|erase)\b(?!\s*--help)',
    r'(?:^|[;&|\r\n\(\)]\s*)(?:cmd(?:\.exe)?\s+/c\s+)?\b(rmdir|rd)\b',
    r'(?:^|[;&|\r\n\(\)]\s*)\brm\b(?!\s*--version|-v\b)',
    r'\bgit\s+clean\s+-[a-zA-Z]*f',
    r'shutil\.rmtree\s*\(',
    r'os\.(remove|unlink)\s*\('
]

def main():
    try:
        raw_input = sys.stdin.read()
        if not raw_input.strip():
            print(json.dumps({"decision": "allow"}))
            return

        data = json.loads(raw_input)
        tool_call = data.get("toolCall", {})
        tool_name = tool_call.get("name", "")
        args = tool_call.get("args", {})

        if tool_name == "run_command":
            cmd = args.get("CommandLine", "")
            for pat in PATTERNS:
                if re.search(pat, cmd, re.IGNORECASE):
                    reason = (
                        "[보안 정책 차단] 파일 또는 폴더의 영구 삭제 명령(Remove-Item, rm, del, rmdir 등)은 실행할 수 없습니다.\n"
                        "파일/폴더 삭제 시 반드시 영구 삭제 대신 Windows 휴지통으로 이동시키는 명령어를 사용하십시오.\n"
                        "사용법: recycle <경로> 또는 powershell & \"$HOME\\.gemini\\scripts\\recycle.ps1\" <경로>"
                    )
                    result = {
                        "decision": "deny",
                        "reason": reason
                    }
                    print(json.dumps(result, ensure_ascii=False))
                    return

        print(json.dumps({"decision": "allow"}))
    except Exception as e:
        # 예외 발생 시 도구 실행이 차단되지 않도록 기본 허용
        print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()

