# The writing-for-humans script checks for one Markdown doc. Exit 1 on any failure.
# Usage: python3 check.py <doc.md>   (budget 750 words; "Budget: N" in the header lines overrides it)
# Fixtures: fixtures/*-pass.md must exit 0, every other fixture must exit 1.
import os, re, sys, urllib.parse
import xml.etree.ElementTree as ET

SWAPS_FILE = os.path.expanduser("~/.agents/skills/simple-english/references/word-swaps.md")
WEAK_MODALS = ["should", "would", "may", "might", "could"]
DEFAULT_BUDGET = 750
SKIPPED = r"(Sources|.*\(not counted\))\s*$"
FENCE = re.compile(r"^\s*(`{3,}|~{3,})(.*)$")


def fenced_lines(text):
    # Yield (line, inside_code) for each line; a fence closes only on the same character and length or more.
    opener = None
    for line in text.splitlines():
        m = FENCE.match(line)
        if opener is None and m:
            opener = m.group(1)
            yield line, True
        elif opener and m and m.group(1)[0] == opener[0] and len(m.group(1)) >= len(opener) and not m.group(2).strip():
            opener = None
            yield line, True
        else:
            yield line, opener is not None


def swap_words():
    # The left column of each word-swaps.md table row is a word to avoid.
    words = []
    for line in open(SWAPS_FILE):
        cells = [c.strip(" `*") for c in line.split("|")]
        if len(cells) < 3 or not cells[1] or set(cells[1]) <= set("-: ") or cells[1].lower() == "slop":
            continue
        entry = re.sub(r"\(.*?\)", "", cells[1])
        words += [w.strip(" .").lower() for w in re.split(r",| / ", entry) if len(w.strip(" .")) > 1]
    return words


def human_part(doc):
    # The human part ends at the first "## Agent context" heading outside a code fence.
    out = []
    for line, code in fenced_lines(doc):
        if not code and line.strip() == "## Agent context":
            break
        out.append(line)
    return "\n".join(out)


def drop_sections(text, pattern=SKIPPED):
    # A skipped section runs until the next heading of the same or a higher level.
    kept, skip_level = [], None
    for line, code in fenced_lines(text):
        heading = None if code else re.match(r"^(#{1,6}) (.*)", line)
        if heading and skip_level and len(heading.group(1)) <= skip_level:
            skip_level = None
        if heading and not skip_level and re.match(pattern, heading.group(2)):
            skip_level = len(heading.group(1))
        if not skip_level:
            kept.append(line)
    return "\n".join(kept)


def drop_code(text):
    out = [line for line, code in fenced_lines(text) if not code]
    return re.sub(r"(`+)(?!`).*?(?<!`)\1(?!`)", "x", "\n".join(out))


def blocks(text):
    # One block per paragraph, list item, table row, or heading, with its wrapped lines joined.
    current = []
    for line in text.splitlines():
        if line.startswith("#"):
            if current:
                yield " ".join(current)
            yield line.strip()
            current = []
            continue
        starts_new = re.match(r"^\s*([-*] |\d+\. |\|)", line)
        if not line.strip() or starts_new:
            if current:
                yield " ".join(current)
            current = [line.strip()] if line.strip() else []
        else:
            current.append(line.strip())
    if current:
        yield " ".join(current)


def sentences(block):
    body = re.sub(r"^(?:[-*]|\d+\.)\s+", "", block)
    return [s.strip() for s in re.split(r"(?<=[.!?])[*_)\"']*\s+", body) if s.strip()]


def word_count(s):
    return len(re.findall(r"[A-Za-z0-9]+(?:'[a-z]+)?", s))


doc_path = sys.argv[1]
doc = open(doc_path).read()
human = human_part(doc)
fails = []

# Header: the non-blank, non-quote lines before the first "## " heading.
preamble = re.split(r"^## ", human, maxsplit=1, flags=re.M)[0]
head_lines = [l for l in preamble.splitlines() if l.strip() and not l.startswith(">")][:10]
head = "\n".join(head_lines).lower()
if not re.search(r"(\bfor:|audience:)[ \t]*\S+(?:[ \t]+\S+)+", head):
    fails.append("the header lines do not name the reader (For: <reader>, to <task>)")
if not re.search(r"(not covered:|out of scope:)[ \t]*\S+(?:[ \t]+\S+)+", head):
    fails.append("the header lines do not state the scope (Not covered: ...)")
kind = re.search(r"kind:[ \t]*(\w+)", head)
if kind and kind.group(1) in ("design", "research") and not any(not code and re.match(r"^## Sources\s*$", l) for l, code in fenced_lines(human)):
    fails.append(f"a {kind.group(1)} doc needs a ## Sources section")

# Budget: tables and code blocks count. Sources, "(not counted)" sections, URLs, and images do not.
override = re.search(r"budget:[ \t]*(\d[\d,]*)", head)
budget = int(override.group(1).replace(",", "")) if override else DEFAULT_BUDGET
counted = re.sub(r"https?://\S+|!\[.*?\]\(.*?\)", "", drop_sections(human))
words = word_count(counted)
if words > budget:
    fails.append(f"human part has {words} words (budget {budget}, tables and code included, sources excluded)")

# Style checks skip code, URLs, and the Sources section.
prose = drop_code(drop_sections(human, r"Sources\s*$"))
prose = re.sub(r"https?://\S+", "x", prose)
for block in blocks(prose):
    if block.startswith(("#", "![")) or re.match(r"^\|[\s:|-]+\|$", block):
        continue
    limit = 20 if re.match(r"^\d+\.\s", block) else 25
    parts = [c for c in block.strip("|").split("|")] if block.startswith("|") else [block]
    for part in parts:
        for s in sentences(part):
            if word_count(s) > limit:
                fails.append(f"sentence has {word_count(s)} words (max {limit}): {s[:70]}")

if re.search(r"^\s*(```|~~~)\s*mermaid", human, re.M | re.I):
    fails.append("Mermaid block in a human doc: draw an SVG instead")
if "\u2014" in human:
    fails.append("em dash in the human part")
if ";" in prose:
    fails.append("semicolon in the human part")
for w in WEAK_MODALS + swap_words():
    flags = 0 if w == "may" else re.I
    stem = re.escape(w[:-1]) + "(?:e|es|ed|ing)" if w.endswith("e") and " " not in w else re.escape(w) + "(?:s|es|ed|d|ing)?"
    if re.search(rf"\b{stem}\b", prose, flags):
        fails.append(f"avoid-list word: {w}")

for m in re.finditer(r"^!\[(.*?)\]\((.*?)\)", human, re.M):
    if not re.match(r"\s*\*\*Figure", human[m.end():]):
        fails.append(f"figure without a caption right under it: {m.group(2)}")
    path = urllib.parse.unquote(m.group(2))
    svg = os.path.join(os.path.dirname(os.path.abspath(doc_path)), path)
    if not svg.endswith(".svg"):
        continue
    ok = False
    if os.path.exists(svg):
        if not open(svg, "rb").read().isascii():
            fails.append(f"SVG has non-ASCII bytes: {path}")
        try:
            root, ns = ET.parse(svg).getroot(), "{http://www.w3.org/2000/svg}"
            title, desc = root.find(ns + "title"), root.find(ns + "desc")
            ok = root.get("role") == "img" and all(e is not None and (e.text or "").strip() for e in (title, desc))
        except ET.ParseError:
            fails.append(f"SVG does not parse: {path}")
    if not ok:
        fails.append(f"SVG lacks role, title, or desc: {path}")

print("\n".join(fails) if fails else "all script checks pass")
sys.exit(1 if fails else 0)
