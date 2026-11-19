// Shared visual helpers: generated glow/particle textures, vignette, cover-fit images.

export function makeFxTextures(scene) {
  const tx = scene.textures;

  // Soft round particle (white, tinted per emitter)
  if (!tx.exists('fx_soft')) {
    const c = tx.createCanvas('fx_soft', 64, 64);
    const g = c.context.createRadialGradient(32, 32, 0, 32, 32, 32);
    g.addColorStop(0, 'rgba(255,255,255,1)');
    g.addColorStop(0.35, 'rgba(255,255,255,0.6)');
    g.addColorStop(1, 'rgba(255,255,255,0)');
    c.context.fillStyle = g; c.context.fillRect(0, 0, 64, 64); c.refresh();
  }

  // Warm firelight glow
  if (!tx.exists('fx_glow')) {
    const s = 512, c = tx.createCanvas('fx_glow', s, s);
    const g = c.context.createRadialGradient(s / 2, s / 2, 0, s / 2, s / 2, s / 2);
    g.addColorStop(0, 'rgba(255,170,80,0.9)');
    g.addColorStop(0.25, 'rgba(255,120,40,0.45)');
    g.addColorStop(0.6, 'rgba(200,70,20,0.12)');
    g.addColorStop(1, 'rgba(0,0,0,0)');
    c.context.fillStyle = g; c.context.fillRect(0, 0, s, s); c.refresh();
  }

  // Cool moon glow
  if (!tx.exists('fx_moonglow')) {
    const s = 256, c = tx.createCanvas('fx_moonglow', s, s);
    const g = c.context.createRadialGradient(s / 2, s / 2, 0, s / 2, s / 2, s / 2);
    g.addColorStop(0, 'rgba(220,230,255,0.55)');
    g.addColorStop(1, 'rgba(120,140,220,0)');
    c.context.fillStyle = g; c.context.fillRect(0, 0, s, s); c.refresh();
  }

  // Screen vignette
  const { width, height } = scene.scale;
  if (!tx.exists('fx_vignette')) {
    const c = tx.createCanvas('fx_vignette', width, height);
    const g = c.context.createRadialGradient(width / 2, height / 2, height * 0.35, width / 2, height / 2, width * 0.75);
    g.addColorStop(0, 'rgba(0,0,0,0)');
    g.addColorStop(1, 'rgba(0,0,0,0.85)');
    c.context.fillStyle = g; c.context.fillRect(0, 0, width, height); c.refresh();
  }
}

// Scales an image to fully cover the screen (like CSS background-size: cover).
export function coverImage(scene, key) {
  const { width, height } = scene.scale;
  const img = scene.add.image(width / 2, height / 2, key);
  const s = Math.max(width / img.width, height / img.height);
  return img.setScale(s);
}

export function vignette(scene, depth = 900) {
  return scene.add.image(0, 0, 'fx_vignette').setOrigin(0).setDepth(depth);
}
