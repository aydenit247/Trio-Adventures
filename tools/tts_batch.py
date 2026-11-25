#!/usr/bin/env python3
"""Clone robot (TTS-fallback) voice lines with Ultimate TTS Studio (Pinokio, a local Gradio app).

Steps, one file:

  1. find  (in the repo, any machine)
       python3 tools/tts_batch.py find [--who skorn,mattias] [--include-drafts] [-o lines.json]
     Collects every {"who", "line"} dict in godot/scripts/**/*.gd (skips voice_*.gd) whose key isn't in
     voice_lines.gd LINES or voice_index.gd, i.e. lines that play on the robot voice. Lines tagged
     "# DRAFT" are skipped unless --include-drafts. Bare "…" lines are always skipped. Steps marked
     "voice": "none" are skipped too (they're waiting for a specific person's recording).

  1b. refs (in the repo, needs ffmpeg)
       python3 tools/tts_batch.py refs lines.json --out refs
     Per line, picks the character's existing takes closest in wording + mood (thoughts skipped) and joins
     them into refs/lines/<who>/<line>.wav (~6 s+), stored as "ref" in lines.json. gen uses it over
     refs/<who>.wav, so the clone borrows the delivery of a similar line (Ebain's ask).

  2. gen   (on the PC that runs Ultimate TTS Studio; needs `pip install gradio_client`)
       python tts_batch.py gen lines.json --refs refs [--out out] [--url http://127.0.0.1:7860]
                               [--engine "Chatterbox Turbo"] [--test] [--only "line text" ...]
     For each character: sends refs/<who>.mp3 (or .wav) as the voice to clone with each of their lines
     and saves one WAV per line in out/<who>/, each named after its line. --test = just the first line. --only = regenerate just
     those lines (match ignores case/punctuation; repeat the flag for several). Existing WAVs for other
     lines are kept, so a re-run with --only only replaces the bad takes.

  3. pack  (anywhere)
       python3 tools/tts_batch.py pack out -o clones.zip
     Zips out/ in the import_voices.py format (manifest.json: who, line, file, effects). Then
       python3 tools/import_voices.py clones.zip
     (or upload the zip to voice-imports/ on GitHub).

The Gradio endpoint is /generate_unified_tts (121 inputs, one per engine setting; we pass the few we
need by name and the rest keep their defaults). See TIPS.md.
"""
import argparse, json, pathlib, re, shutil, sys, zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "godot" / "scripts"

ENGINE_REF_PARAM = {           # engine name in the studio → its reference-audio input + extra settings
    "Chatterbox Turbo": ("chatterbox_turbo_ref_audio", "chatterbox_turbo_"),
    "ChatterboxTTS": ("chatterbox_ref_audio", "chatterbox_"),
    "Chatterbox Multilingual": ("chatterbox_mtl_ref_audio", "chatterbox_mtl_"),
    "IndexTTS2": ("indextts2_ref_audio", "indextts2_"),
    "IndexTTS": ("indextts_ref_audio", "indextts_"),
    "Fish Speech S2 Pro": ("fish_s2_ref_audio", "fish_s2_"),
    "Fish Speech S1": ("fish_ref_audio", "fish_"),
    "F5-TTS": ("f5_ref_audio", "f5_"),
    "Higgs Audio": ("higgs_ref_audio", "higgs_"),
    "VoxCPM": ("voxcpm_ref_audio", "voxcpm_"),
    "Qwen Voice Clone": ("qwen_ref_audio", "qwen_"),
}


def key(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def slug(s, n=48):
    return (re.sub(r"[^a-z0-9]+", "_", s.lower()).strip("_") or "line")[:n].rstrip("_")


def filename(line, n=150):
    """The line itself as a Windows-safe file name: drops <>:"/\\|?* and trailing dots/spaces."""
    s = re.sub(r'[<>:"/\\|?*\x00-\x1f]', "", line).replace("…", "...")
    s = re.sub(r"\s+", " ", s).strip()[:n].rstrip(". ")
    return s or slug(line)


def unq(s):
    return s.replace('\\"', '"').replace("\\n", " ")


# ---------------------------------------------------------------- find
DICT = re.compile(r'\{[^{}]*?"(who|line)"\s*:\s*"((?:[^"\\]|\\.)*)"[^{}]*?"(who|line)"\s*:\s*"((?:[^"\\]|\\.)*)"[^{}]*\}')


def voiced_keys():
    ks = set()
    for m in re.finditer(r'^\s*"((?:[^"\\]|\\.)*)"\s*:', (SCRIPTS / "voice_lines.gd").read_text(encoding="utf-8"), re.M):
        ks.add(key(unq(m.group(1))))
    for m in re.finditer(r'^\t"([a-z0-9]+)":', (SCRIPTS / "voice_index.gd").read_text(encoding="utf-8"), re.M):
        ks.add(m.group(1))
    return ks


def cmd_find(a):
    voiced = voiced_keys()
    want = set(a.who.split(",")) if a.who else None
    out, seen, drafts = [], set(), 0
    for p in sorted(SCRIPTS.rglob("*.gd")):
        if p.name.startswith("voice_"):
            continue
        text = p.read_text(encoding="utf-8")
        for m in DICT.finditer(text):
            f = {m.group(1): m.group(2), m.group(3): m.group(4)}
            if "who" not in f or "line" not in f:
                continue
            who, line = f["who"], unq(f["line"])
            k = key(line)
            if not k or k in voiced or (want and who not in want) or (who, k) in seen:
                continue
            if re.search(r'"voice"\s*:\s*"none"', m.group(0)):
                continue
            eol = text.find("\n", m.end())
            tail = text[m.end(): eol if eol >= 0 else None]
            tag = tail.split("#", 1)[1].strip() if "#" in tail else ""
            if "DRAFT" in tag.upper() and not re.search(r"Ebain|Asar", tag) and not a.include_drafts:
                drafts += 1
                continue
            seen.add((who, k))
            out.append({"who": who, "line": line, "src": str(p.relative_to(ROOT)).replace("\\", "/"), "tag": tag})
    pathlib.Path(a.o).write_text(json.dumps(out, indent=1, ensure_ascii=False), encoding="utf-8")
    by = {}
    for x in out:
        by[x["who"]] = by.get(x["who"], 0) + 1
    print(f"{len(out)} robot lines → {a.o}  {by}" + (f"  (skipped {drafts} DRAFT)" if drafts else ""))
    for x in out:
        print(f"  {x['who']:>8} | {x['line']}")


# ---------------------------------------------------------------- refs
VOICES = ROOT / "godot" / "assets" / "voices"
REF_DIRS = {"skorn": ["skorn"], "dulbers": ["dulbers"], "mattias": ["mattias"],
            "goblin": ["goblins_asar", "goblin"], "goblins": ["goblins_asar", "goblin"]}


def words(s):
    return set(re.findall(r"[a-z0-9']+", s.lower().replace("’", "'")))


def script_lines():
    """key → {line, mood, thought} for every dialogue dict in the scripts."""
    info = {}
    for p in SCRIPTS.rglob("*.gd"):
        if p.name.startswith("voice_"):
            continue
        for m in re.finditer(r'\{[^{}]*?"line"\s*:\s*"((?:[^"\\]|\\.)*)"[^{}]*\}', p.read_text(encoding="utf-8")):
            d = m.group(0)
            line = unq(m.group(1))
            mood = re.search(r'"mood"\s*:\s*"([^"]+)"', d)
            info.setdefault(key(line), {"line": line, "mood": mood.group(1) if mood else "",
                                        "thought": bool(re.search(r'"thought"\s*:\s*true', d))})
    return info


def takes_for(who, info):
    """The character's existing voice files with their line text (thoughts skipped: their echo is baked in)."""
    dirs = REF_DIRS.get(who, [who])
    out = []
    for m in re.finditer(r'^\t"([a-z0-9]+)": "([^"]+)"', (SCRIPTS / "voice_index.gd").read_text(encoding="utf-8"), re.M):
        out.append((m.group(1), m.group(2)))
    for m in re.finditer(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*"([^"]+)"', (SCRIPTS / "voice_lines.gd").read_text(encoding="utf-8"), re.M):
        f = m.group(2)
        out.append((key(unq(m.group(1))), f if "." in f.rsplit("/", 1)[-1] else f + ".mp3"))
    res, seen = [], set()
    for k, f in out:
        if f in seen or f.split("/")[0] not in dirs or not (VOICES / f).exists():
            continue
        seen.add(f)
        i = info.get(k)
        if i and (i["thought"] or "*echo" in i["line"].lower()):   # echo/thought effects would get cloned too
            continue
        res.append({"file": VOICES / f, "line": i["line"] if i else f, "mood": i["mood"] if i else ""})
    return res


def duration(path):
    import subprocess
    r = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                       capture_output=True, text=True)
    try:
        return float(r.stdout.strip())
    except ValueError:
        return 0.0


def cmd_refs(a):
    """Per line: pick the character's existing takes closest in words + mood, join them into refs/lines/<who>/."""
    import subprocess
    lines = json.loads(pathlib.Path(a.lines).read_text(encoding="utf-8"))
    info = script_lines()
    outdir = pathlib.Path(a.out)
    cache = {}
    for x in lines:
        who = x["who"]
        takes = cache.setdefault(who, takes_for(who, info))
        if not takes:
            print(f"-- {who}: no existing takes, uses refs/{who}.wav")
            continue
        mood = info.get(key(x["line"]), {}).get("mood", "")
        w = words(x["line"])
        def score(t):
            tw = words(t["line"])
            j = len(w & tw) / max(1, len(w | tw))
            return j + (0.3 if mood and t["mood"] == mood else 0) - (1 if key(t["line"]) == key(x["line"]) else 0)
        ranked = sorted(takes, key=score, reverse=True)
        pick, total = [], 0.0
        for t in ranked:           # best match first, then add the next best until the sample is ~6 s+
            d = t.setdefault("dur", duration(t["file"]))
            if d < 0.8:
                continue
            pick.append(t); total += d
            if total >= a.min_seconds:
                break
        dst = outdir / "lines" / who / f"{slug(x['line'])}.wav"
        dst.parent.mkdir(parents=True, exist_ok=True)
        args, fl = [], ""
        for i, t in enumerate(pick):
            args += ["-i", str(t["file"])]
            fl += f"[{i}:a]aresample=24000,aformat=channel_layouts=mono,apad=pad_dur=0.35[a{i}];"
        fl += "".join(f"[a{i}]" for i in range(len(pick))) + f"concat=n={len(pick)}:v=0:a=1,atrim=0:15[o]"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *args, "-filter_complex", fl, "-map", "[o]", str(dst)], check=True)
        x["ref"] = str(dst.relative_to(outdir)).replace("\\", "/")
        x["ref_from"] = [t["line"] for t in pick]
        print(f"{who:>8} | {x['line'][:60]}\n         ← " + "  +  ".join(t["line"][:50] for t in pick))
    pathlib.Path(a.lines).write_text(json.dumps(lines, indent=1, ensure_ascii=False), encoding="utf-8")


# ---------------------------------------------------------------- gen
def cmd_gen(a):
    try:
        from gradio_client import Client, handle_file
    except ImportError:
        sys.exit("Needs gradio_client:  pip install gradio_client")
    lines = json.loads(pathlib.Path(a.lines).read_text(encoding="utf-8"))
    if a.only:
        ks = {key(o) for o in a.only}
        lines = [x for x in lines if key(x["line"]) in ks]
        missing = ks - {key(x["line"]) for x in lines}
        for k in missing:
            print(f"!! --only line not in {a.lines}: {k}")
    if a.who:
        lines = [x for x in lines if x["who"] in a.who.split(",")]
    refs, out = pathlib.Path(a.refs), pathlib.Path(a.out)
    groups = {}
    for x in lines:
        groups.setdefault(x["who"], []).append(x)
    if a.test:
        first = next(iter(groups))
        groups = {first: groups[first][:1]}
    if a.engine not in ENGINE_REF_PARAM:
        sys.exit(f"Unknown engine {a.engine!r}. Known: {', '.join(ENGINE_REF_PARAM)}")
    ref_param, prefix = ENGINE_REF_PARAM[a.engine]
    client = Client(a.url, verbose=False)
    # gradio_client treats every input whose default is null as required, so send all 121 with the
    # app's own defaults and override only what we need (TIPS.md).
    api = client.view_api(print_info=False, return_format="dict")
    params = api["named_endpoints"]["/generate_unified_tts"]["parameters"]
    defaults = {p["parameter_name"]: p.get("parameter_default") for p in params}
    done = 0
    for who, items in groups.items():
        ref = next((refs / f"{who}{ext}" for ext in (".mp3", ".wav") if (refs / f"{who}{ext}").exists()), None)
        if not ref:
            print(f"-- {who}: no {refs}/{who}.mp3 or .wav, skipping {len(items)} line(s)")
            continue
        print(f"== {who} ({len(items)} lines, voice: {ref.name})")
        (out / who).mkdir(parents=True, exist_ok=True)
        for x in items:
            line_ref = refs / x["ref"] if x.get("ref") and not a.one_ref else None
            use = line_ref if line_ref and line_ref.exists() else ref
            kw = dict(defaults)
            kw.update({"text_input": x["line"], "tts_engine": a.engine, "audio_format": "wav",
                       ref_param: handle_file(str(use))})
            if a.exaggeration is not None and prefix.startswith("chatterbox"):
                kw[prefix + "exaggeration"] = a.exaggeration
            if a.seed is not None and prefix.startswith("chatterbox"):
                kw[prefix + "seed"] = a.seed
            try:
                audio, status = client.predict(api_name="/generate_unified_tts", **kw)
            except Exception as e:  # keep going; the bad line can be redone with --only
                print(f"   FAIL {x['line']!r}: {e}")
                continue
            if not audio or not pathlib.Path(audio).exists():
                print(f"   FAIL {x['line']!r}: no audio ({status})")
                continue
            dst = out / who / f"{filename(x['line'])}.wav"   # named after the line itself (Ebain's ask)
            shutil.copyfile(audio, dst)
            meta = out / who / (dst.stem + ".json")
            meta.write_text(json.dumps({"who": who, "line": x["line"], "engine": a.engine}, ensure_ascii=False), encoding="utf-8")
            done += 1
            print(f"   ok  {dst.name}  (voice sample: {use.name})")
    print(f"{done} WAV(s) in {out}/")


# ---------------------------------------------------------------- pack
def cmd_pack(a):
    out = pathlib.Path(a.out)
    manifest = []
    with zipfile.ZipFile(a.o, "w", zipfile.ZIP_DEFLATED) as z:
        for meta in sorted(out.glob("*/*.json")):
            wav = meta.with_suffix(".wav")
            if not wav.exists():
                continue
            m = json.loads(meta.read_text(encoding="utf-8"))
            name = f"{m['who']}/{m['who']}_clone_{slug(m['line'])}.wav"   # in-game file: plain slug, no spaces/quotes
            z.write(wav, name)
            manifest.append({"who": m["who"], "line": m["line"], "file": name, "effects": []})
        z.writestr("manifest.json", json.dumps(manifest, indent=1, ensure_ascii=False))
    print(f"{len(manifest)} lines → {a.o}. Next: python3 tools/import_voices.py {a.o}")


def main():
    for st in (sys.stdout, sys.stderr):   # Windows consoles default to cp1252; lines have … and emoji
        try: st.reconfigure(encoding="utf-8", errors="replace")
        except Exception: pass
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = ap.add_subparsers(dest="cmd", required=True)
    f = sp.add_parser("find"); f.add_argument("--who"); f.add_argument("--include-drafts", action="store_true"); f.add_argument("-o", default="lines.json")
    g = sp.add_parser("gen"); g.add_argument("lines"); g.add_argument("--refs", default="refs"); g.add_argument("--out", default="out")
    g.add_argument("--url", default="http://127.0.0.1:7860"); g.add_argument("--engine", default="Chatterbox Turbo")
    g.add_argument("--only", action="append"); g.add_argument("--who"); g.add_argument("--test", action="store_true")
    g.add_argument("--exaggeration", type=float); g.add_argument("--seed", type=float)
    g.add_argument("--one-ref", action="store_true", help="ignore per-line refs, use refs/<who>.mp3|wav for every line")
    r = sp.add_parser("refs"); r.add_argument("lines"); r.add_argument("--out", default="refs"); r.add_argument("--min-seconds", type=float, default=6.0)
    p = sp.add_parser("pack"); p.add_argument("out"); p.add_argument("-o", default="clones.zip")
    a = ap.parse_args()
    {"find": cmd_find, "refs": cmd_refs, "gen": cmd_gen, "pack": cmd_pack}[a.cmd](a)


if __name__ == "__main__":
    main()
