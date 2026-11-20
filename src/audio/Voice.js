// Character voices using the browser's built-in text-to-speech (Web Speech API).
// Robotic on purpose. Each character gets their own pitch, speed and (if the computer has
// several) a different system voice. Which voices exist depends on the browser/OS:
// Chrome has "Google UK English Male" etc., Windows has David/Mark/Zira, Macs have Daniel, Fred...
//
//   Voice.say('skorn', 'Bet, my fault.')   Voice.stop()   Voice.toggle()   (V key / button)
import Sfx from './Sfx.js';
import Settings from '../systems/settings.js';

// pitch 0–2, rate 0.1–10. `prefer` = voice-name fragments to look for, in order.
const PROFILES = {
  skorn:         { pitch: 0.35, rate: 1.2,  prefer: ['Google US English', 'David', 'Fred', 'Alex', 'Male'] },
  lykor:         { pitch: 1.35, rate: 0.95, prefer: ['Google UK English Male', 'Daniel', 'George', 'Mark', 'Male'] },
  xylo:          { pitch: 0.55, rate: 0.82, prefer: ['Daniel', 'Google UK English Male', 'Ralph', 'Mark', 'Male'] },
  dulbers:       { pitch: 1.7,  rate: 1.3,  prefer: ['Google US English', 'Mark', 'Alex', 'Male'] },
  dulbers_demon: { pitch: 0.05, rate: 0.75, prefer: ['Fred', 'David', 'Google UK English Male', 'Male'] },
  dulbmeethus:   { pitch: 0.3,  rate: 0.7,  prefer: ['Ralph', 'Daniel', 'Google UK English Male'] },
  mattias:       { pitch: 0.8,  rate: 0.85, prefer: ['Google UK English Male', 'George', 'Daniel', 'David'] },
  giant:         { pitch: 0.0,  rate: 0.65, prefer: ['Fred', 'David', 'Google US English'] },
  goblin:        { pitch: 2.0,  rate: 1.45, prefer: ['Google UK English Female', 'Zira', 'Samantha', 'Female'] },
  goblins:       { pitch: 2.0,  rate: 1.5,  prefer: ['Google UK English Female', 'Zira', 'Samantha', 'Female'] },
  chief:         { pitch: 1.55, rate: 1.1,  prefer: ['Google UK English Male', 'Mark', 'Daniel'] },
  narrator:      { pitch: 1.0,  rate: 1.0,  prefer: ['Google UK English Female', 'Zira', 'Samantha', 'Karen', 'Female'] },
};

const Voice = {
  on: true,
  voices: [],
  picked: {},

  init() {
    try { this.on = localStorage.getItem('trio_voices') !== '0'; } catch (e) { /* storage blocked */ }
    if (!('speechSynthesis' in window)) { this.on = false; this.unsupported = true; return; }
    const load = () => { this.voices = speechSynthesis.getVoices().filter((v) => /^en/i.test(v.lang)); this.picked = {}; };
    load();
    speechSynthesis.addEventListener?.('voiceschanged', load);
  },

  voiceFor(who) {
    if (this.picked[who] !== undefined) return this.picked[who];
    const prof = PROFILES[who] || PROFILES.narrator;
    let v = null;
    for (const frag of prof.prefer) {
      v = this.voices.find((x) => x.name.includes(frag));
      if (v) break;
    }
    if (!v && this.voices.length) v = this.voices[Object.keys(PROFILES).indexOf(who) % this.voices.length];
    this.picked[who] = v || null;
    return this.picked[who];
  },

  // Turn a script line into something TTS reads well
  clean(text) {
    return text
      .replace(/\[[^\]]*\]/g, ' ')        // [stage directions]
      .replace(/[*_~]/g, '')
      .replace(/…|\.\.+/g, ', ')
      .replace(/\bshi\b/gi, 'shee')
      .replace(/\bdoe\b/gi, 'dough')
      .replace(/\by'all\b/gi, 'yall')
      .trim();
  },

  say(who, text, { thought = false } = {}) {
    if (!this.on || this.unsupported || Sfx.muted || !text) return;
    const line = this.clean(text);
    if (!/[a-z0-9]/i.test(line)) return; // "…" and other wordless lines
    speechSynthesis.cancel();
    const prof = PROFILES[who] || PROFILES.narrator;
    const u = new SpeechSynthesisUtterance(line);
    const v = this.voiceFor(who);
    if (v) { u.voice = v; u.lang = v.lang; }
    u.pitch = prof.pitch;
    // Shouting (ALL CAPS) goes faster; thoughts are quieter
    u.rate = Settings.voiceRate * prof.rate * (line === line.toUpperCase() && /[A-Z]{3}/.test(line) ? 1.15 : 1);
    u.volume = Settings.voice * (thought ? 0.55 : 1);
    if (u.volume <= 0.01) return;
    // Chrome sometimes leaves the engine paused after a cancel
    if (speechSynthesis.paused) speechSynthesis.resume();
    speechSynthesis.speak(u);
  },

  stop() { if (!this.unsupported) speechSynthesis.cancel(); },

  toggle() {
    this.on = !this.on;
    if (!this.on) this.stop();
    try { localStorage.setItem('trio_voices', this.on ? '1' : '0'); } catch (e) { /* storage blocked */ }
    document.dispatchEvent(new CustomEvent('trio-voices', { detail: this.on }));
  },
};

Voice.init();
export default Voice;
