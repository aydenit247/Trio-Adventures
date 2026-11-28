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
                               [--engine ChatterboxTTS] [--test] [--only "line text" ...]
     For each character: sends refs/<who>.mp3 (or .wav) as the voice to clone with each of their lines
     and saves one WAV per line in out/<who>/, each named after its line. --test = just the first line. --only = regenerate just
     those lines (match ignores case/punctuation; repeat the flag for several). Existing WAVs for other
     lines are kept, so a re-run with --only only replaces the bad takes.

  2b. fx   (anywhere with librosa + scipy + soundfile)
       python3 tools/tts_batch.py fx out --dest out_fx [--who skorn] [--hz 90] [--monster 0.15]
     Pitches each clone down to the character's studio pitch and adds the studio's "monster" layer (FX table),
     so clones sit next to the Emberstage takes. Pack out_fx instead of out afterwards.

  3. pack  (anywhere with ffmpeg + librosa for the fx)
       python3 tools/tts_batch.py pack out -o clones.zip [--who skorn] [--no-fx]
     Zips out/ in the import_voices.py format (manifest.json: who, line, file, effects). Skorn's pitch drop (the FX
     table) is applied automatically while packing, so no separate fx step is needed. Then
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


def chunks(text, limit=280):
    """Split long text at sentence ends into pieces of at most ~limit characters (Chatterbox drifts on long input)."""
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= limit:
        return [text]
    out, cur = [], ""
    for sent in re.split(r"(?<=[.!?…])\s+", text):
        if cur and len(cur) + 1 + len(sent) > limit:
            out.append(cur)
            cur = sent
        else:
            cur = (cur + " " + sent).strip()
    if cur:
        out.append(cur)
    return out


def join_wavs(paths, dst, gap=0.35):
    """Glue WAV files end to end with a short pause (stdlib only, so it runs in the Windows venv)."""
    import wave
    if len(paths) == 1:
        shutil.copyfile(paths[0], dst)
        return
    with wave.open(str(paths[0])) as w0:
        params = w0.getparams()
    silence = b"\x00" * int(params.framerate * gap) * params.sampwidth * params.nchannels
    with wave.open(str(dst), "wb") as o:
        o.setparams(params)
        for i, p in enumerate(paths):
            with wave.open(str(p)) as w:
                o.writeframes(w.readframes(w.getnframes()))
            if i < len(paths) - 1:
                o.writeframes(silence)


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
            if not k or (k in voiced and not a.all) or (want and who not in want) or (who, k) in seen:
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
            "goblin": ["goblins_asar", "goblin"], "goblins": ["goblins_asar", "goblin"],
            "troll": ["goblins_asar"]}
# Characters with no takes of their own clone another speaker's takes (Ebain 11/26: the Bridge Troll is Chief
# Bogdrinker's voice, then FX["troll"] lowers it): who → the speaker whose takes to use.
REF_WHO = {"troll": "chief"}


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
            name = re.search(r'"name"\s*:\s*"?([A-Za-z_][^",}]*)', d)   # speaker (a constant like SLUDGE or a string)
            who = re.search(r'"who"\s*:\s*"([^"]+)"', d)
            info.setdefault(key(line), {"line": line, "mood": mood.group(1) if mood else "",
                                        "who": who.group(1) if who else "",
                                        "name": name.group(1).strip() if name else "",
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
        if "_clone_" in f:   # never clone from a clone: it drifts further from the real voice each time
            continue
        seen.add(f)
        i = info.get(k)
        if i and (i["thought"] or "*echo" in i["line"].lower()):   # echo/thought effects would get cloned too
            continue
        if who in REF_WHO and not (i and i.get("who") == REF_WHO[who]):   # e.g. troll: only the Chief's own lines
            continue
        res.append({"file": VOICES / f, "line": i["line"] if i else f, "mood": i["mood"] if i else "",
                    "name": i["name"] if i else ""})
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
            # a reference recording kept in the repo (tools/voice_refs/<who>.wav|mp3, e.g. Ebain's Deloye voice, 11/26)
            kept = next((ROOT / "tools" / "voice_refs" / f"{who}{ext}" for ext in (".wav", ".mp3")
                         if (ROOT / "tools" / "voice_refs" / f"{who}{ext}").exists()), None)
            if kept and not (outdir / f"{who}{kept.suffix}").exists():
                outdir.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(kept, outdir / f"{who}{kept.suffix}")
            print(f"-- {who}: no existing takes, uses refs/{who}{kept.suffix if kept else '.wav'}"
                  + (f" (copied from tools/voice_refs)" if kept else ""))
            continue
        mood = info.get(key(x["line"]), {}).get("mood", "")
        name = info.get(key(x["line"]), {}).get("name", "")
        w = words(x["line"])
        def score(t):
            tw = words(t["line"])
            j = len(w & tw) / max(1, len(w | tw))
            return (j + (0.3 if mood and t["mood"] == mood else 0) + (0.5 if name and t["name"] == name else 0)
                    - (1 if key(t["line"]) == key(x["line"]) else 0))   # same speaker (e.g. Sludge) first
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


# ---------------------------------------------------------------- pronunciation
# Same respellings the Emberstage studio uses (Voice-actor-generation src/data/trio/cast.ts PRONUNCIATIONS), applied to
# the text sent to the TTS ONLY. File names, lines.json and the manifest keep the real line, so the game still matches it.
PRONUNCIATIONS = {
    "Lykor": "Lie-core", "Xylo": "Zy-lo", "Caelid": "Kay-lid", "Dulbers": "Dull-burrs",
    "Deloye": "Duh-loy", "Bogdrinker": "Bog-drinker",   # Deloye = da-loy (Ebain). No Metocin/Mattias respelling: Ebain found it silly
    "metocy": "meh-toe-see", "midtocy": "mid-toe-see", "beezy": "bee-zee",
    "aight": "ite", "looksmaxxin": "looks-maxin", "deadahh": "dead-ahh", "allat": "all-at", "OD": "oh-dee",
    "ts": "this", "mf": "motherfucker", "ngl": "not gonna lie", "fw": "fuck with",
    "shi": "shee", "Im": "I'm", "Dulbmeethus": "Dulb-mee-thus",
    "bussy": "buh-see",   # troll line: say it like "pussy" with a b (Ebain 11/26)
   # Deloye's lines (Ebain 11/26)
}


def spoken(line, extra=None):
    """The line with whole-word respellings swapped in (any capitalization). extra: {"word": "say"} overrides."""
    table = {k.lower(): v for k, v in {**PRONUNCIATIONS, **(extra or {})}.items()}
    pat = re.compile(r"(?<![A-Za-z0-9'])(" + "|".join(re.escape(k) for k in sorted(table, key=len, reverse=True)) + r")(?![A-Za-z0-9'])", re.I)
    return pat.sub(lambda m: table[m.group(1).lower()], line)


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
        if not ref and not a.one_ref:   # no main sample is fine when every line has its own (refs/lines/)
            items = [x for x in items if x.get("ref") and (refs / x["ref"]).exists()] or items
            if all(x.get("ref") and (refs / x["ref"]).exists() for x in items):
                ref = refs / items[0]["ref"]
        if not ref:
            print(f"-- {who}: no {refs}/{who}.mp3 or .wav, skipping {len(items)} line(s)")
            continue
        print(f"== {who} ({len(items)} lines, voice: {ref.name})")
        (out / who).mkdir(parents=True, exist_ok=True)
        for x in items:
            line_ref = refs / x["ref"] if x.get("ref") and not a.one_ref else None
            use = line_ref if line_ref and line_ref.exists() else ref
            kw = dict(defaults)
            say = x["line"] if a.no_pron else spoken(x["line"], dict(p.split("=", 1) for p in (a.say or [])))
            kw.update({"text_input": say, "tts_engine": a.engine, "audio_format": "wav",
                       ref_param: handle_file(str(use))})
            if a.exaggeration is not None and prefix.startswith("chatterbox"):
                kw[prefix + "exaggeration"] = a.exaggeration
            if a.cfg is not None and prefix.startswith("chatterbox"):
                kw[prefix + "cfg_weight"] = a.cfg            # lower = follows the voice sample's delivery more
            if a.seed is not None and prefix.startswith("chatterbox"):
                kw[prefix + "seed"] = a.seed
            dst = out / who / f"{filename(x['line'])}.wav"   # named after the line itself (Ebain's ask)
            parts, status = [], ""
            for chunk in chunks(say):   # long text (book pages) goes in sentence chunks, then gets joined
                kw["text_input"] = chunk
                try:
                    audio, status = client.predict(api_name="/generate_unified_tts", **kw)
                except Exception as e:  # keep going; the bad line can be redone with --only
                    print(f"   FAIL {x['line'][:80]!r}: {e}")
                    parts = None
                    break
                if not audio or not pathlib.Path(audio).exists():
                    print(f"   FAIL {x['line'][:80]!r}: no audio ({status})")
                    parts = None
                    break
                parts.append(audio)
            if not parts:
                continue
            join_wavs(parts, dst)
            meta = out / who / (dst.stem + ".json")
            meta.write_text(json.dumps({"who": who, "line": x["line"], "engine": a.engine}, ensure_ascii=False), encoding="utf-8")
            done += 1
            print(f"   ok  {dst.name}  (voice sample: {use.name})" + (f"\n       said as: {say[:200]}" if say != x["line"] else ""))
    print(f"{done} WAV(s) in {out}/")


# ---------------------------------------------------------------- fx
# Same "monster" layering as the Emberstage studio (Voice-actor-generation src/trio/fx.ts) so clones sit next to
# the studio takes. Pitch is matched per line to the character's existing takes (median voice pitch).
FX = {   # who → target median pitch (Hz) of their studio/real takes, studio monster amount
    "skorn": {"hz": 90, "monster": 0.15, "lo": -5},   # Ebain 11/24: -8 st was TOO low on the high takes
    "mattias": {"st": -3, "monster": 0},   # Ebain 11/24: clones good, just deeper (fixed shift, his takes are ~240 Hz)
    "troll": {"st": -4, "monster": 0.1},   # Ebain 11/26: Chief Bogdrinker's voice, lowered. Fixed -4 st, tune here if he wants deeper
}


def _median_f0(y, sr):
    import librosa, numpy as np
    y = librosa.resample(y, orig_sr=sr, target_sr=16000)          # same settings the 90 Hz target was measured with
    f, _, _ = librosa.pyin(y, fmin=50, fmax=400, sr=16000, frame_length=1024)
    f = f[~np.isnan(f)]
    return float(np.median(f)) if len(f) else 0.0


def apply_fx(src, dst, hz, monster, lo=-8.0, hi=0.0, grit=False, fixed=None):
    """Pitch-match with ffmpeg's Rubber Band (clean, high quality), then the studio's octave-down layer.
    The studio's waveshaper grit is off by default (Ebain 11/24: "kind of distorted")."""
    import subprocess, librosa, numpy as np
    y, sr = librosa.load(str(src), sr=None, mono=True)
    f0 = _median_f0(y, sr)
    st = float(fixed) if fixed is not None else (float(max(lo, min(hi, 12 * np.log2(hz / f0)))) if f0 else 0.0)
    rb = lambda semis: f"rubberband=pitch={2 ** (semis / 12):.6f}:pitchq=quality:transients=smooth:window=long"
    m = monster
    chain = f"[0:a]aformat=channel_layouts=mono,{rb(st)},asplit=2[v][s];"
    chain += f"[s]{rb(-12)},lowpass=f=2200,volume={m * 0.9:.3f}[sub];" if m > 0 else "[s]anullsink;"
    main = f"[v]lowpass=f={7000 - m * 3500:.0f}" + (f",asoftclip=type=tanh:param={1 + m * 4:.2f}" if grit else "") + "[main];"
    chain += main
    chain += (f"[main][sub]amix=inputs=2:normalize=0,volume={1 / (1 + m * 0.8):.3f},"
              f"lowshelf=f=180:g={m * 6:.2f}[mx];" if m > 0 else "[main]anull[mx];")
    chain += "[mx]loudnorm=I=-18:TP=-1.5:LRA=11[o]"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-filter_complex", chain,
                    "-map", "[o]", "-ar", str(sr), "-c:a", "pcm_s16le", str(dst)], check=True)
    return f0, st


def cmd_fx(a):
    """Deepen/layer clones to match the character's studio takes. out/<who>/*.wav → <dest>/<who>/ (+ .json copied)."""
    src, dest = pathlib.Path(a.out), pathlib.Path(a.dest)
    for who, cfg in FX.items():
        if a.who and who not in a.who.split(","):
            continue
        hz = a.hz or cfg.get("hz", 0); fixed = a.st if a.st is not None else cfg.get("st"); monster = cfg["monster"] if a.monster is None else a.monster
        for wav in sorted((src / who).glob("*.wav")):
            (dest / who).mkdir(parents=True, exist_ok=True)
            f0, st = apply_fx(wav, dest / who / wav.name, hz, monster, lo=cfg.get("lo", -8.0), fixed=fixed)
            meta = wav.with_suffix(".json")
            if meta.exists():
                shutil.copyfile(meta, dest / who / meta.name)
            print(f"{who:>8} | {f0:5.0f} Hz → {st:+.1f} st, monster {monster} | {wav.stem}")


# ---------------------------------------------------------------- pack
def tidy(src, dst, keep=0.6):
    """Chatterbox sometimes adds long dead air (seconds of silence mid-line or at the end; Ebain 11/25). Trim the start
    and end, and shorten any pause longer than ~1 s to `keep` seconds. Returns how many seconds were cut."""
    import subprocess
    af = (f"silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
          f"silenceremove=stop_periods=-1:stop_duration=1.0:stop_threshold=-45dB:stop_silence={keep}")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(src), "-af", af, str(dst)], check=True)
    return max(0.0, duration(src) - duration(dst))


def cmd_pack(a):
    """Zip out/<who>/*.wav + manifest.json for import_voices.py. Characters in the FX table (Skorn) get their pitch
    drop + layer applied automatically here (--no-fx to skip), so it can't be forgotten. --who limits the characters."""
    import tempfile
    out = pathlib.Path(a.out)
    want = set(a.who.split(",")) if a.who else None
    manifest = []
    with tempfile.TemporaryDirectory() as tmp, zipfile.ZipFile(a.o, "w", zipfile.ZIP_DEFLATED) as z:
        for meta in sorted(out.glob("*/*.json")):
            wav = meta.with_suffix(".wav")
            if not wav.exists():
                continue
            m = json.loads(meta.read_text(encoding="utf-8"))
            if want and m["who"] not in want:
                continue
            src = wav
            cfg = FX.get(m["who"])
            if cfg and not a.no_fx:
                src = pathlib.Path(tmp) / f"{m['who']}_{len(manifest)}.wav"
                f0, st = apply_fx(wav, src, cfg.get("hz", 0), cfg["monster"], lo=cfg.get("lo", -8.0), fixed=cfg.get("st"))
                print(f"  fx {m['who']}: {f0:.0f} Hz → {st:+.1f} st  {wav.stem}")
            tidy_src = pathlib.Path(tmp) / f"tidy_{len(manifest)}.wav"
            cut = tidy(src, tidy_src)
            if cut >= 1.0:
                print(f"  tidy: cut {cut:.1f}s of dead air  {wav.stem[:60]}")
            name = f"{m['who']}/{m['who']}_clone_{slug(m['line'])}.wav"   # in-game file: plain slug, no spaces/quotes
            z.write(tidy_src, name)
            manifest.append({"who": m["who"], "line": m["line"], "file": name, "effects": []})
        z.writestr("manifest.json", json.dumps(manifest, indent=1, ensure_ascii=False))
    print(f"{len(manifest)} lines → {a.o}. Next: python3 tools/import_voices.py {a.o}")


def main():
    for st in (sys.stdout, sys.stderr):   # Windows consoles default to cp1252; lines have … and emoji
        try: st.reconfigure(encoding="utf-8", errors="replace")
        except Exception: pass
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = ap.add_subparsers(dest="cmd", required=True)
    f = sp.add_parser("find"); f.add_argument("--who"); f.add_argument("--include-drafts", action="store_true"); f.add_argument("--all", action="store_true", help="also list lines that already have a voice file (to re-voice them)"); f.add_argument("-o", default="lines.json")
    g = sp.add_parser("gen"); g.add_argument("lines"); g.add_argument("--refs", default="refs"); g.add_argument("--out", default="out")
    g.add_argument("--url", default="http://127.0.0.1:7860"); g.add_argument("--engine", default="ChatterboxTTS")
    g.add_argument("--only", action="append"); g.add_argument("--who"); g.add_argument("--test", action="store_true")
    g.add_argument("--exaggeration", type=float, default=0.7); g.add_argument("--seed", type=float); g.add_argument("--cfg", type=float, default=0.3)
    g.add_argument("--say", action="append", metavar="WORD=SPELLING", help="extra respelling for this run, e.g. --say 'mufug=muh-fug'")
    g.add_argument("--no-pron", action="store_true", help="send the line exactly as written (skip the respellings)")
    g.add_argument("--one-ref", action="store_true", help="ignore per-line refs, use refs/<who>.mp3|wav for every line")
    r = sp.add_parser("refs"); r.add_argument("lines"); r.add_argument("--out", default="refs"); r.add_argument("--min-seconds", type=float, default=6.0)
    x = sp.add_parser("fx"); x.add_argument("out"); x.add_argument("--dest", default="out_fx"); x.add_argument("--who")
    x.add_argument("--hz", type=float); x.add_argument("--monster", type=float); x.add_argument("--st", type=float, help="fixed semitone shift")
    p = sp.add_parser("pack"); p.add_argument("out"); p.add_argument("-o", default="clones.zip")
    p.add_argument("--who"); p.add_argument("--no-fx", action="store_true", help="don't auto-apply the FX table (Skorn pitch drop)")
    a = ap.parse_args()
    {"find": cmd_find, "refs": cmd_refs, "gen": cmd_gen, "fx": cmd_fx, "pack": cmd_pack}[a.cmd](a)


if __name__ == "__main__":
    main()
