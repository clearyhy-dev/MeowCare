"""
Replay [Tool call] Write and StrReplace from Cursor transcript in chronological order.
Restores the final Feed-era MeowCare tree under ROOT (no path skipping).
"""
from __future__ import annotations

from pathlib import Path

TRANSCRIPT = Path(
    r"C:\Users\Administrator\.cursor\projects\d-googleplay-MeowCare\agent-transcripts\aaef4d58-9d21-4110-9542-62f01417cba1.txt"
)
ROOT = Path(r"d:\googleplay\MeowCare")


def norm_target_from_path_line(path_line: str) -> Path | None:
    if not path_line.startswith("  path:"):
        return None
    raw = path_line.split("path:", 1)[1].strip()
    raw = raw.replace("/", "\\")
    low = raw.lower()
    root = str(ROOT).lower()
    if not low.startswith(root):
        return None
    rel = low[len(root) :].lstrip("\\/")
    return ROOT / rel


def parse_str_replace_body(body_lines: list[str]) -> tuple[str, str, str] | None:
    if not body_lines or not body_lines[0].startswith("  path:"):
        return None
    path = body_lines[0].split("path:", 1)[1].strip()
    rest = "\n".join(body_lines[1:])
    oidx = rest.find("  old_string:")
    if oidx < 0:
        return None
    after_old = rest[oidx + len("  old_string:") :]
    mid = after_old.find("\n  new_string:")
    if mid < 0:
        return None
    old_raw = after_old[:mid]
    new_raw = after_old[mid + len("\n  new_string:") :]
    if old_raw.startswith(" "):
        old_raw = old_raw[1:]
    if new_raw.startswith(" "):
        new_raw = new_raw[1:]
    return path, old_raw, new_raw


def try_replace(cur: str, old: str, new: str) -> str | None:
    if old in cur:
        return cur.replace(old, new, 1)
    old_crlf = old.replace("\n", "\r\n")
    if old_crlf in cur:
        return cur.replace(old_crlf, new.replace("\n", "\r\n"), 1)
    return None


def main() -> None:
    lines = TRANSCRIPT.read_text(encoding="utf-8", errors="replace").split("\n")
    w_count = s_count = s_miss = s_bad = 0
    i = 0
    while i < len(lines):
        line = lines[i]
        if line == "[Tool call] Write" and i + 2 < len(lines):
            path_line = lines[i + 1]
            contents_line = lines[i + 2]
            if not contents_line.startswith("  contents:"):
                i += 1
                continue
            target = norm_target_from_path_line(path_line)
            if target is None:
                i += 1
                continue
            first = contents_line.split("  contents:", 1)[1]
            if first.startswith(" "):
                first = first[1:]
            parts: list[str] = []
            if first != "":
                parts.append(first)
            j = i + 3
            while j < len(lines):
                ln = lines[j]
                if ln.startswith("[Tool call]") or ln.startswith("[Tool result]"):
                    break
                parts.append(ln)
                j += 1
            content = "\n".join(parts)
            if content and not content.endswith("\n"):
                content += "\n"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8", newline="\n")
            w_count += 1
            i = j
            continue

        if line == "[Tool call] StrReplace":
            j = i + 1
            block: list[str] = []
            while j < len(lines):
                ln = lines[j]
                if ln.startswith("[Tool call]") or ln.startswith("[Tool result]"):
                    break
                block.append(ln)
                j += 1
            parsed = parse_str_replace_body(block)
            if parsed is None:
                s_bad += 1
                i = j
                continue
            path_s, old_s, new_s = parsed
            target = Path(path_s.replace("/", "\\"))
            low = str(target).lower()
            if not low.startswith(str(ROOT).lower()):
                i = j
                continue
            rel = low[len(str(ROOT).lower()) :].lstrip("\\/")
            target = ROOT / rel
            if not target.is_file():
                s_miss += 1
                i = j
                continue
            cur = target.read_text(encoding="utf-8", errors="replace")
            updated = try_replace(cur, old_s, new_s)
            if updated is None:
                s_bad += 1
                print("STR old not found:", target)
            else:
                target.write_text(updated, encoding="utf-8", newline="\n")
                s_count += 1
            i = j
            continue

        i += 1

    print(
        "writes:",
        w_count,
        "str_replace_ok:",
        s_count,
        "str_replace_missing_file:",
        s_miss,
        "str_replace_failed:",
        s_bad,
    )


if __name__ == "__main__":
    main()
