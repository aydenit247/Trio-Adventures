// Green-screen removal for videos, done live on the GPU.
// Usage: videoObject.setPostPipeline('ChromaKey')  (registered in BootScene)

const FRAG = `
precision mediump float;
uniform sampler2D uMainSampler;
varying vec2 outTexCoord;
void main() {
  vec4 c = texture2D(uMainSampler, outTexCoord);
  float m = max(c.r, c.b);
  float g = c.g - m;                          // how much greener than red/blue
  float a = clamp(1.0 - (g - 0.03) / 0.05, 0.0, 1.0);
  if (c.g > m) c.g = m + (c.g - m) * 0.25;    // remove green spill on edges
  gl_FragColor = vec4(c.rgb * a, c.a * a);
}`;

export default class ChromaKey extends Phaser.Renderer.WebGL.Pipelines.PostFXPipeline {
  constructor(game) {
    super({ game, name: 'ChromaKey', fragShader: FRAG });
  }
}
