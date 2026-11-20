// Sound effects, synthesized live with the Web Audio API (no audio files needed).
//
//   import Sfx from '../audio/Sfx.js';
//   Sfx.play('whoosh');            one-shot
//   Sfx.blip('skorn');             dialogue voice blip
//   Sfx.startLoop('fire');         looping ambience (starts as soon as audio is unlocked)
//   Sfx.stopLoop('fire');
//
// Browsers only allow sound after the player presses a key or clicks, so the first
// press unlocks audio. M toggles mute (remembered between visits).

const VOICES = {
  skorn:    { type: 'square',   freq: 98,  vol: 0.07 },
  lykor:    { type: 'triangle', freq: 330, vol: 0.10 },
  xylo:     { type: 'sawtooth', freq: 140, vol: 0.05, lowpass: 900 },
  dulbers:  { type: 'square',   freq: 260, vol: 0.05 },
  mattias:  { type: 'triangle', freq: 200, vol: 0.09 },
  giant:    { type: 'square',   freq: 60,  vol: 0.08 },
  goblin:   { type: 'square',   freq: 520, vol: 0.04 },
  goblins:  { type: 'square',   freq: 470, vol: 0.05 },
  chief:    { type: 'square',   freq: 380, vol: 0.045 },
  dulbers_demon: { type: 'sawtooth', freq: 70, vol: 0.07, lowpass: 600 },
  narrator: { type: 'sine',     freq: 640, vol: 0.05 },
};

class SfxEngine {
  constructor() {
    this.ctx = null;
    this.loops = {};       // name -> stop function
    this.wanted = new Set(); // loops requested before audio was unlocked
    try { this.muted = localStorage.getItem('trio_muted') === '1'; } catch (e) { this.muted = false; }

    const unlock = () => {
      this.init();
      if (this.ctx && this.ctx.state !== 'running') this.ctx.resume();
      if (this.musicBlocked && this.retryMusic) this.retryMusic();
    };
    ['keydown', 'pointerdown', 'touchstart', 'touchend', 'click'].forEach((e) => window.addEventListener(e, unlock, { capture: true }));
    window.addEventListener('keydown', (e) => { if (e.key === 'm' || e.key === 'M') this.toggleMute(); });
  }

  init() {
    if (this.ctx) return;
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    this.ctx = new AC();
    this.master = this.ctx.createGain();
    this.master.gain.value = this.muted ? 0 : 0.8;
    this.master.connect(this.ctx.destination);

    // 2 seconds of white noise, reused by every noisy sound
    const len = this.ctx.sampleRate * 2;
    this.noiseBuf = this.ctx.createBuffer(1, len, this.ctx.sampleRate);
    const d = this.noiseBuf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;

    this.ctx.addEventListener('statechange', () => {
      if (!this.ready) return;
      this.wanted.forEach((n) => this.startLoop(n));
    });
  }

  get ready() { return !!this.ctx && this.ctx.state === 'running'; }

  toggleMute() {
    this.muted = !this.muted;
    try { localStorage.setItem('trio_muted', this.muted ? '1' : '0'); } catch (e) { /* storage blocked */ }
    if (this.master) this.master.gain.setTargetAtTime(this.muted ? 0 : 0.8, this.ctx.currentTime, 0.05);
    Object.values(this.tracks || {}).forEach((a) => { a.muted = this.muted; });
    document.dispatchEvent(new CustomEvent('trio-mute', { detail: this.muted }));
  }

  // ---------- building blocks ----------
  tone({ type = 'sine', freq = 440, freqEnd, dur = 0.2, vol = 0.2, attack = 0.005, when = 0, lowpass, out }) {
    if (!this.ready) return;
    const t = this.ctx.currentTime + when;
    const o = this.ctx.createOscillator();
    const g = this.ctx.createGain();
    o.type = type;
    o.frequency.setValueAtTime(freq, t);
    if (freqEnd) o.frequency.exponentialRampToValueAtTime(Math.max(1, freqEnd), t + dur);
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(vol, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    let node = o;
    if (lowpass) { const f = this.ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lowpass; node.connect(f); node = f; }
    node.connect(g); g.connect(out || this.master);
    o.start(t); o.stop(t + dur + 0.05);
  }

  noise({ dur = 0.3, vol = 0.2, type = 'lowpass', f0 = 1000, f1, q = 1, attack = 0.01, when = 0, out }) {
    if (!this.ready) return;
    const t = this.ctx.currentTime + when;
    const src = this.ctx.createBufferSource();
    src.buffer = this.noiseBuf;
    const f = this.ctx.createBiquadFilter();
    f.type = type; f.Q.value = q;
    f.frequency.setValueAtTime(f0, t);
    if (f1) f.frequency.exponentialRampToValueAtTime(f1, t + dur);
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(vol, t + attack);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f); f.connect(g); g.connect(out || this.master);
    src.start(t, Math.random() * 1.5); src.stop(t + dur + 0.05);
  }

  // ---------- dialogue ----------
  blip(who) {
    const v = VOICES[who] || VOICES.narrator;
    this.tone({ type: v.type, freq: v.freq * (0.94 + Math.random() * 0.12), dur: 0.05, vol: v.vol, lowpass: v.lowpass });
  }

  // ---------- one-shots ----------
  play(name) {
    const fn = this[`sfx_${name}`];
    if (fn) fn.call(this);
  }

  sfx_click()   { this.tone({ type: 'triangle', freq: 1400, freqEnd: 900, dur: 0.05, vol: 0.06 }); }
  sfx_tick()    { this.tone({ type: 'square', freq: 880, dur: 0.035, vol: 0.04 }); }
  sfx_confirm() {
    this.tone({ type: 'triangle', freq: 660, dur: 0.12, vol: 0.12 });
    this.tone({ type: 'triangle', freq: 990, dur: 0.18, vol: 0.12, when: 0.07 });
  }
  sfx_step()    { this.noise({ dur: 0.07, vol: 0.12, type: 'lowpass', f0: 420, f1: 160, attack: 0.004 }); }
  sfx_pop()     { this.tone({ type: 'sine', freq: 300, freqEnd: 900, dur: 0.09, vol: 0.14 }); }
  sfx_grab() { // item get
    [523, 659, 784, 1046].forEach((f, i) => this.tone({ type: 'square', freq: f, dur: 0.12, vol: 0.05, when: i * 0.07 }));
  }
  sfx_whoosh()  { this.noise({ dur: 0.45, vol: 0.25, type: 'bandpass', f0: 300, f1: 2500, q: 0.8, attack: 0.12 }); }
  sfx_ignite() {
    this.noise({ dur: 1.2, vol: 0.5, type: 'lowpass', f0: 3000, f1: 300, attack: 0.02 });
    this.tone({ type: 'sine', freq: 120, freqEnd: 40, dur: 0.6, vol: 0.35 });
  }
  sfx_boom() {
    this.tone({ type: 'sine', freq: 90, freqEnd: 30, dur: 0.7, vol: 0.5 });
    this.noise({ dur: 0.35, vol: 0.25, type: 'lowpass', f0: 600, f1: 100 });
  }
  sfx_dramatic() { // record-scratch "wait what" sting
    this.noise({ dur: 0.25, vol: 0.2, type: 'bandpass', f0: 2000, f1: 400, q: 3 });
    this.tone({ type: 'sawtooth', freq: 220, freqEnd: 110, dur: 0.5, vol: 0.08, when: 0.15, lowpass: 1200 });
  }
  sfx_birds() {
    for (let i = 0; i < 6; i++) {
      const w = i * 0.35 + Math.random() * 0.2, f = 2600 + Math.random() * 1400;
      this.tone({ type: 'sine', freq: f, freqEnd: f * 1.3, dur: 0.08, vol: 0.05, when: w });
      this.tone({ type: 'sine', freq: f * 1.2, freqEnd: f, dur: 0.1, vol: 0.04, when: w + 0.1 });
    }
  }
  sfx_choir() { // heavenly "ahhh" for the goblins worshipping
    [261.6, 329.6, 392, 523.3].forEach((f, i) => {
      this.tone({ type: 'sine', freq: f, dur: 2.2, vol: 0.06, attack: 0.4, when: i * 0.05 });
      this.tone({ type: 'triangle', freq: f * 1.003, dur: 2.2, vol: 0.03, attack: 0.5, when: i * 0.05 });
    });
    this.noise({ dur: 1.8, vol: 0.04, type: 'bandpass', f0: 1200, q: 4, attack: 0.5 });
  }
  sfx_gulp() {
    this.tone({ type: 'sine', freq: 180, freqEnd: 90, dur: 0.18, vol: 0.3 });
    this.tone({ type: 'sine', freq: 220, freqEnd: 110, dur: 0.16, vol: 0.25, when: 0.25 });
  }
  sfx_sparkle() {
    [1568, 2093, 2637, 3136].forEach((f, i) => this.tone({ type: 'sine', freq: f, dur: 0.25, vol: 0.05, when: i * 0.05 }));
  }
  sfx_tiptoe() {
    for (let i = 0; i < 4; i++) this.tone({ type: 'triangle', freq: 900 + (i % 2) * 200, dur: 0.04, vol: 0.05, when: i * 0.18 });
  }
  sfx_snore() { // big rumbling giant snore
    this.noise({ dur: 1.4, vol: 0.35, type: 'lowpass', f0: 260, f1: 140, q: 3, attack: 0.5 });
    this.tone({ type: 'sawtooth', freq: 55, freqEnd: 48, dur: 1.4, vol: 0.12, attack: 0.5, lowpass: 300 });
  }
  sfx_door() { this.noise({ dur: 0.5, vol: 0.12, type: 'bandpass', f0: 500, f1: 900, q: 6 }); this.tone({ type: 'square', freq: 1320, dur: 0.12, vol: 0.04, when: 0.05 }); }
  sfx_titleSting() {
    const chord = [146.8, 220, 293.7, 349.2]; // D minor
    chord.forEach((f, i) => this.tone({ type: 'triangle', freq: f, dur: 3.2, vol: 0.07, attack: 0.6, when: i * 0.12 }));
    this.tone({ type: 'sine', freq: 73.4, dur: 3.5, vol: 0.18, attack: 0.3 });
    this.noise({ dur: 2.5, vol: 0.06, type: 'bandpass', f0: 800, f1: 3000, q: 0.5, attack: 1.2 });
  }

  // ---------- music (real audio files) ----------
  // Music uses an <audio> element instead of Web Audio: it's more reliable across browsers,
  // and on iPhones it still plays when the ringer switch is on silent.
  // opts: { volume, loopStart, loopEnd, fadeIn } in seconds.
  preloadMusic(url) {
    this.tracks = this.tracks || {};
    if (!this.tracks[url]) {
      const a = new Audio();
      a.preload = 'auto';
      a.src = url;
      a.loop = true;
      a.load();
      this.tracks[url] = a;
    }
    return this.tracks[url];
  }

  playMusic(url, opts = {}) {
    const a = this.preloadMusic(url);
    if (this.music && this.music.a === a && !a.paused) return;
    this.stopMusic(0.8);
    const vol = opts.volume ?? 0.5;
    this.music = { url, a, vol, opts };
    a.muted = this.muted;
    a.volume = 0;
    if (opts.loopStart && a.currentTime < opts.loopStart) { try { a.currentTime = opts.loopStart; } catch (e) { /* not loaded yet */ } }
    // Trim silence at the end of the file so the loop has no gap
    a.ontimeupdate = () => {
      if (opts.loopEnd && a.currentTime >= opts.loopEnd) a.currentTime = opts.loopStart || 0;
    };
    const tryPlay = () => a.play().then(() => {
      this.musicBlocked = false;
      this.fadeAudio(a, vol, (opts.fadeIn ?? 2) * 1000);
    }).catch(() => {
      // Browser wants a click/keypress first — try again on the next one.
      this.musicBlocked = true;
    });
    tryPlay();
    this.retryMusic = tryPlay;
  }

  stopMusic(fade = 1.2) {
    if (!this.music) return;
    const { a } = this.music;
    this.music = null;
    this.retryMusic = null;
    this.fadeAudio(a, 0, fade * 1000, () => { a.pause(); });
  }

  fadeAudio(a, target, ms, done) {
    clearInterval(a._fade);
    const from = a.volume, steps = Math.max(1, Math.round(ms / 50));
    let i = 0;
    a._fade = setInterval(() => {
      i += 1;
      a.volume = Math.min(1, Math.max(0, from + (target - from) * (i / steps)));
      if (i >= steps) { clearInterval(a._fade); if (done) done(); }
    }, 50);
  }

  // ---------- loops ----------
  startLoop(name) {
    this.wanted.add(name);
    if (!this.ready || this.loops[name]) return;
    const fn = this[`loop_${name}`];
    if (fn) this.loops[name] = fn.call(this);
  }

  stopLoop(name) {
    this.wanted.delete(name);
    if (this.loops[name]) { this.loops[name](); delete this.loops[name]; }
  }

  stopAll() { Object.keys(this.loops).forEach((n) => this.stopLoop(n)); this.wanted.clear(); }

  bed(vol) { // a fade-able gain node for a loop
    const g = this.ctx.createGain();
    g.gain.setValueAtTime(0.0001, this.ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(vol, this.ctx.currentTime + 1.5);
    g.connect(this.master);
    return g;
  }

  fadeOut(g, nodes, timers) {
    const t = this.ctx.currentTime;
    g.gain.cancelScheduledValues(t);
    g.gain.setValueAtTime(Math.max(g.gain.value, 0.0001), t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 1.2);
    timers.forEach(clearInterval);
    setTimeout(() => nodes.forEach((n) => { try { n.stop(); } catch (e) { /* already stopped */ } }), 1400);
  }

  loop_night() {
    const g = this.bed(1);
    // Wind: filtered noise with a slow swell
    const src = this.ctx.createBufferSource(); src.buffer = this.noiseBuf; src.loop = true;
    const f = this.ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 380;
    const wind = this.ctx.createGain(); wind.gain.value = 0.05;
    const lfo = this.ctx.createOscillator(); lfo.frequency.value = 0.08;
    const lfoAmt = this.ctx.createGain(); lfoAmt.gain.value = 0.03;
    lfo.connect(lfoAmt); lfoAmt.connect(wind.gain);
    src.connect(f); f.connect(wind); wind.connect(g);
    src.start(); lfo.start();
    // Crickets
    const timer = setInterval(() => {
      if (Math.random() < 0.55) {
        const base = 4200 + Math.random() * 500;
        for (let i = 0; i < 3; i++) this.tone({ type: 'sine', freq: base, dur: 0.03, vol: 0.018, when: i * 0.06, out: g });
      }
    }, 700);
    return () => this.fadeOut(g, [src, lfo], [timer]);
  }

  loop_village() { // daytime: soft wind and birds
    const g = this.bed(1);
    const src = this.ctx.createBufferSource(); src.buffer = this.noiseBuf; src.loop = true;
    const f = this.ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 500;
    const wind = this.ctx.createGain(); wind.gain.value = 0.03;
    src.connect(f); f.connect(wind); wind.connect(g); src.start();
    const timer = setInterval(() => {
      if (Math.random() < 0.35) {
        const fr = 2400 + Math.random() * 1800;
        this.tone({ type: 'sine', freq: fr, freqEnd: fr * 1.25, dur: 0.09, vol: 0.03, out: g });
        this.tone({ type: 'sine', freq: fr * 1.1, freqEnd: fr * 0.9, dur: 0.1, vol: 0.025, when: 0.12, out: g });
      }
    }, 900);
    return () => this.fadeOut(g, [src], [timer]);
  }

  loop_shop() { // quiet room tone with the odd creak
    const g = this.bed(1);
    const o = this.ctx.createOscillator(); o.type = 'sine'; o.frequency.value = 55;
    const og = this.ctx.createGain(); og.gain.value = 0.025;
    o.connect(og); og.connect(g); o.start();
    const timer = setInterval(() => {
      if (Math.random() < 0.15) this.noise({ dur: 0.4, vol: 0.05, type: 'bandpass', f0: 350, f1: 600, q: 8, out: g });
    }, 1500);
    return () => this.fadeOut(g, [o], [timer]);
  }

  loop_trip() { // warbly detuned drone for the midtocy
    const g = this.bed(1);
    const nodes = [];
    [110, 110 * 1.5, 110 * 2.01].forEach((fr, i) => {
      const o = this.ctx.createOscillator(); o.type = i === 1 ? 'triangle' : 'sine'; o.frequency.value = fr;
      const lfo = this.ctx.createOscillator(); lfo.frequency.value = 0.3 + i * 0.17;
      const amt = this.ctx.createGain(); amt.gain.value = fr * 0.04;
      lfo.connect(amt); amt.connect(o.frequency);
      const og = this.ctx.createGain(); og.gain.value = 0.035;
      o.connect(og); og.connect(g); o.start(); lfo.start();
      nodes.push(o, lfo);
    });
    return () => this.fadeOut(g, nodes, []);
  }

  loop_fire() {
    const g = this.bed(1);
    // Low roar
    const src = this.ctx.createBufferSource(); src.buffer = this.noiseBuf; src.loop = true;
    const f = this.ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 700;
    const roar = this.ctx.createGain(); roar.gain.value = 0.09;
    src.connect(f); f.connect(roar); roar.connect(g); src.start();
    // Crackles and pops
    const timer = setInterval(() => {
      if (Math.random() < 0.5) this.noise({ dur: 0.02 + Math.random() * 0.03, vol: 0.08 + Math.random() * 0.15, type: 'highpass', f0: 1500 + Math.random() * 3000, out: g });
      if (Math.random() < 0.06) this.noise({ dur: 0.08, vol: 0.25, type: 'bandpass', f0: 900, q: 2, out: g });
    }, 60);
    return () => this.fadeOut(g, [src], [timer]);
  }
}

const Sfx = new SfxEngine();
export default Sfx;
