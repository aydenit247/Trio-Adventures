#!/usr/bin/env python3
"""Dialogue map builder (Asar 11/24). Run tools/dialogue_map/build.sh, not this file directly.
Reads the Godot dump ($DLG_DIR/dump.json, from godot/tools/dialogue_map_dump.gd) + the .gd sources (Ebain/Asar/DRAFT tags,
where each conversation plays, actions that start other conversations, short lines in level code) and writes
<out>/dialogue.json + <out>/index.html. New dialogue script or level file: add it to SCENES below."""
import json, re, os, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", "..", "godot")) + "/"
DLG = os.environ.get("DLG_DIR", "/tmp/dlg")
SCR = ROOT + "scripts/"
dump = json.load(open(DLG + "/dump.json"))

SCENES = [
    ("camp", "1. The Camp", ["camp_script.gd"], ["camp.gd"]),
    ("trail", "2. Goblin Woods Trail", ["trail_script.gd"], ["trail.gd"]),
    ("village", "3. Goblin Village", ["village_script.gd"], ["village.gd", "lost_pages.gd"]),
    ("rooms", "3b. Village buildings (bar, office, shops)", ["village_rooms_script.gd"], ["village_buildings.gd", "goblin_band.gd"]),
    ("mart", "4. Metocy Mart", ["mart_script.gd"], ["mart.gd"]),
    ("ruins", "4b. Old Ruins, Rat Cave & Charis (side quest)", ["ruins_script.gd"], ["ruins.gd", "cave.gd"]),
    ("pass", "5. Giant's Pass", ["pass_script.gd"], ["pass.gd"]),
    ("summit", "6. Summit Path & the Wizard's Lair (finale)", ["summit_script.gd"], ["summit.gd"]),
    ("deloye", "Side: Deloye Library", ["deloye_script.gd"], ["deloye_library.gd"]),
    ("fights", "Fights: banter & surprises", ["combat_data.gd"], ["combat/battle.gd", "combat/battle_view.gd"]),
]
SKIP_CONSTS = {"combat_data.gd": None}   # handled specially
NOT_DIALOGUE = {"TROLL", "R", "GULPO", "WUZZLE"}

def src(f):
    p = SCR + f
    return open(p).read().split("\n") if os.path.exists(p) else []

def unesc(s):
    return s.encode().decode("unicode_escape").encode("latin-1").decode("utf-8") if "\\" in s else s

# ---------- tags: text -> tag, from every .gd
tag_of = {}
STR = r'"((?:[^"\\]|\\.)*)"'
for dirpath, _, files in os.walk(SCR):
    for fn in files:
        if not fn.endswith(".gd"): continue
        for ln in open(os.path.join(dirpath, fn)).read().split("\n"):
            m = re.search(r"#\s*(Ebain|Asar|DRAFT)\b", ln)
            if not m: continue
            for s in re.findall(STR, ln.split("#")[0] if ln.count('"') else ln):
                if len(s) > 2:
                    tag_of.setdefault(unesc(s), m.group(1))

def tag_for(text):
    if text in tag_of: return tag_of[text]
    return ""

# ---------- const order + preload aliases
def const_order(f):
    return [m.group(1) for ln in src(f) for m in [re.match(r"^const ([A-Z0-9_]+)", ln)] if m]

alias = {}   # (levelfile, ALIAS) -> scriptfile
for dirpath, _, files in os.walk(SCR):
    for fn in files:
        if not fn.endswith(".gd"): continue
        rel = os.path.relpath(os.path.join(dirpath, fn), SCR)
        for ln in open(os.path.join(dirpath, fn)).read().split("\n"):
            m = re.match(r'\s*const (\w+)\s*:?=\s*preload\("res://scripts/(\w+_script\.gd|combat/combat_data\.gd)"\)', ln)
            if m: alias[(rel, m.group(1))] = os.path.basename(m.group(2))

# ---------- function bodies + match arms in level code
def funcs(lines):
    out = {}; cur = None; start = 0
    for i, ln in enumerate(lines):
        m = re.match(r"^(?:static )?func (\w+)", ln)
        if m:
            if cur: out[cur] = (start, i)
            cur, start = m.group(1), i
    if cur: out[cur] = (start, len(lines))
    return out

def func_at(fs, i):
    for n, (a, b) in fs.items():
        if a <= i < b: return n
    return ""

refs = collections.defaultdict(list)     # (scriptfile, CONST) -> [context strings]
do_links = collections.defaultdict(set)  # do id -> {(scriptfile, CONST)}
level_lines = collections.defaultdict(list)   # levelfile -> inline lines
LEVEL_FILES = sorted({f for s in SCENES for f in s[3]})

def consts_in(lines, a, b, rel, fs, depth=0, seen=None):
    seen = seen or set()
    found = set()
    for i in range(a, b):
        ln = lines[i].split("#")[0]
        for m in re.finditer(r"\b([A-Z]\w*)\.([A-Z][A-Z0-9_]+)\b", ln):
            k = (rel, m.group(1))
            if k in alias: found.add((alias[k], m.group(2)))
        if depth < 2:
            for m in re.finditer(r"\b(_\w+)\(", ln):
                fn = m.group(1)
                if fn in fs and fn not in seen:
                    seen.add(fn)
                    fa, fb = fs[fn]
                    found |= consts_in(lines, fa, fb, rel, fs, depth + 1, seen)
    return found

for rel in LEVEL_FILES:
    lines = src(rel)
    fs = funcs(lines)
    for i, ln in enumerate(lines):
        code = ln.split("#")[0]
        for m in re.finditer(r"\b([A-Z]\w*)\.([A-Z][A-Z0-9_]+)\b", code):
            k = (rel, m.group(1))
            if k not in alias: continue
            ctx = ""
            for j in range(i, max(-1, i - 4), -1):
                lm = re.search(r'"label":\s*' + STR, lines[j])
                if lm:
                    vm = re.search(r'"verb":\s*' + STR, lines[j])
                    ctx = '%s "%s"' % (vm.group(1) if vm else "Use", lm.group(1)); break
            if not ctx:
                ctx = "in %s()" % func_at(fs, i)
            refs[(alias[k], m.group(2))].append("%s: %s" % (rel, ctx))
        # match arms: "do_id":
        am = re.match(r'^(\t+)"([a-z0-9_]+)":\s*(.*)$', ln)
        if am and func_at(fs, i) in ("do_action", "_on_action", "_do", "do_step", "_action"):
            ind = am.group(1)
            j = i + 1
            while j < len(lines) and (lines[j].startswith(ind + "\t") or lines[j].strip() == ""):
                j += 1
            for c in consts_in(lines, i, j, rel, fs):
                do_links[am.group(2)].add(c)
        # inline lines
        for lm in re.finditer(r'"line":\s*' + STR, code):
            text = unesc(lm.group(1))
            wm = re.search(r'"who":\s*' + STR, code)
            nm = re.search(r'"name":\s*' + STR, code)
            who = wm.group(1) if wm else ("(depends)" if '"who"' in code else "narrator")
            t = re.search(r"#\s*(Ebain|Asar|DRAFT)\b", ln)
            level_lines[rel].append({"t": "line", "who": who, "name": nm.group(1) if nm else "", "text": text,
                                     "tag": t.group(1) if t else "", "ctx": func_at(fs, i), "src": "%s:%d" % (rel, i + 1)})

# ---------- voice for inline lines needs a second Godot pass
extra = sorted({l["text"] for ls in level_lines.values() for l in ls})
json.dump(extra, open(DLG + "/extra_texts.json", "w"))
if not dump.get("extra") and extra:
    print("NEED_SECOND_PASS"); sys.exit(3)
used_voice = set()
for ls in level_lines.values():
    for l in ls:
        l["voice"] = dump["extra"].get(l["text"], "")
        if l["voice"]: used_voice.add(l["voice"])

# ---------- annotate trees
def annot(n):
    if isinstance(n, list):
        return [annot(x) for x in n]
    t = n.get("t")
    if t == "line":
        n["tag"] = tag_for(n["text"])
        if n["voice"]: used_voice.add(n["voice"])
    elif t == "str":
        n["tag"] = tag_for(n["text"])
        if n["voice"]: used_voice.add(n["voice"])
    elif t == "do":
        n["links"] = sorted("%s|%s" % c for c in do_links.get(n["id"], []))
    elif t == "choice":
        for o in n["options"]: o["steps"] = annot(o["steps"]); o["tag"] = tag_for(o["text"])
    elif t == "if":
        n["steps"] = annot(n["steps"])
    elif t == "dict":
        n["items"] = {k: annot(v) for k, v in n["items"].items()}
    return n

import subprocess, datetime
commit = subprocess.run(["git", "-C", ROOT, "log", "-1", "--format=%h %cs"], capture_output=True, text=True).stdout.strip()
out = {"scenes": [], "chars": dump["chars"], "commit": commit, "built": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")}
for sid, title, sfiles, lfiles in SCENES:
    sc = {"id": sid, "title": title, "convs": [], "inline": [], "files": sfiles + lfiles}
    for f in sfiles:
        consts = dump["scripts"].get(f, {})
        order = const_order(f) or list(consts)
        for k in order:
            if k not in consts or k in NOT_DIALOGUE: continue
            v = consts[k]
            if f == "combat_data.gd" and k not in ("BANTER", "CHAOS", "BOLT_EVENT", "PENALTIES", "BUZZED_MISFIRES"):
                continue
            node = annot(v)
            # keep only things with any text in them
            if not re.search(r'"(text)":', json.dumps(node)): continue
            if isinstance(node, dict) and node.get("t") == "str" and (" " not in node["text"] or len(node["text"]) < 4): continue
            sc["convs"].append({"key": "%s|%s" % (f, k), "name": k, "file": f, "node": node,
                                "when": sorted(set(refs.get((f, k), [])))[:6]})
    for lf in lfiles:
        sc["inline"] += level_lines.get(lf, [])
    out["scenes"].append(sc)

# recordings on disk that no line uses
allv = sorted(set(dump["voice_files"]))
out["unused_voice"] = [v for v in allv if v not in used_voice and os.path.exists(ROOT + v.replace("res://", ""))]
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "..", "build", "dialogue_map")
os.makedirs(OUT, exist_ok=True)
json.dump(out, open(OUT + "/dialogue.json", "w"), ensure_ascii=False)
import shutil
shutil.copy(os.path.join(os.path.dirname(os.path.abspath(__file__)), "index.html"), OUT + "/index.html")
# quick stats
def count(n, c):
    if isinstance(n, list):
        for x in n: count(x, c)
    elif isinstance(n, dict):
        if n.get("t") in ("line", "str"):
            c["lines"] += 1; c["voiced"] += 1 if n.get("voice") else 0
        for v in n.values():
            if isinstance(v, (list, dict)): count(v, c)
for sc in out["scenes"]:
    c = collections.Counter()
    for cv in sc["convs"]: count(cv["node"], c)
    for l in sc["inline"]: c["lines"] += 1; c["voiced"] += 1 if l["voice"] else 0
    print("%-48s convs=%3d lines=%4d voiced=%4d inline=%d" % (sc["title"], len(sc["convs"]), c["lines"], c["voiced"], len(sc["inline"])))
print("unused recordings:", len(out["unused_voice"]), " do-links:", len(do_links))
