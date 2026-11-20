// Autosave: a checkpoint is written every time a story scene ends (and when a new game starts).
// It stores the next scene plus every story flag, item, XP and level from the registry.
const KEY = 'trio_save';
const store = (() => { try { return window.localStorage; } catch (e) { return null; } })();

export const SCENE_NAMES = { Goblin: 'Goblin Village', Mart: 'Metocy Mart', Pass: 'The Pass', Continue: 'End of Chapter 1' };

const Save = {
  write(registry, scene) {
    if (!store) return;
    const data = {};
    Object.entries(registry.getAll()).forEach(([k, v]) => {
      if (['boolean', 'number', 'string'].includes(typeof v)) data[k] = v;
    });
    try { store.setItem(KEY, JSON.stringify({ v: 1, scene, data, at: Date.now() })); } catch (e) { /* full/blocked */ }
  },

  read() {
    if (!store) return null;
    try { const s = JSON.parse(store.getItem(KEY)); return s && s.scene ? s : null; } catch (e) { return null; }
  },

  // Load flags into the registry, return the scene to start
  load(registry) {
    const s = this.read();
    if (!s) return null;
    registry.reset();
    Object.entries(s.data).forEach(([k, v]) => registry.set(k, v));
    return s.scene;
  },

  newGame(registry) {
    registry.reset();
    registry.set('level', 1);
    registry.set('xp', 0);
    this.write(registry, 'Goblin');
  },

  clear() { if (store) store.removeItem(KEY); },
};

export default Save;
