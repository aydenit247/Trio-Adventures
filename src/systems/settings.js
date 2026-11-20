// Player settings, saved in the browser.
const KEY = 'trio_settings';
const DEFAULTS = { textSpeed: 1, music: 1, sfx: 0.8, voice: 1, voiceRate: 1, combatDiff: 1, timedHits: 1 };
// textSpeed index → ms per character (0 = instant)
export const TEXT_SPEEDS = [{ name: 'Slow', ms: 40 }, { name: 'Normal', ms: 22 }, { name: 'Fast', ms: 10 }, { name: 'Instant', ms: 0 }];

const Settings = {
  ...DEFAULTS,
  load() {
    try { Object.assign(this, DEFAULTS, JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { /* blocked */ }
  },
  set(k, v) {
    this[k] = v;
    const out = {};
    Object.keys(DEFAULTS).forEach((key) => { out[key] = this[key]; });
    try { localStorage.setItem(KEY, JSON.stringify(out)); } catch (e) { /* blocked */ }
    document.dispatchEvent(new CustomEvent('trio-settings', { detail: { k, v } }));
  },
  textMs() { return TEXT_SPEEDS[this.textSpeed].ms; },
};
Settings.load();
export default Settings;
