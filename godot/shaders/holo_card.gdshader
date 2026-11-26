// Charis's prized card (Asar 11/25): an original holo card face, no real card art. A gold border, a deep purple
// field with a bright starburst in the middle and rainbow foil that shifts as the camera moves.
shader_type spatial;
render_mode unshaded, cull_disabled;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	// gold border
	float border = step(0.06, uv.x) * step(uv.x, 0.94) * step(0.045, uv.y) * step(uv.y, 0.955);
	vec3 gold = vec3(0.95, 0.75, 0.3) * (0.85 + 0.15 * sin(uv.y * 40.0));
	// field: purple → magenta, with a starburst behind the "art"
	vec2 c = uv - vec2(0.5, 0.42);
	float r = length(c * vec2(1.0, 1.4));
	float a = atan(c.y, c.x);
	float rays = pow(0.5 + 0.5 * sin(a * 14.0), 6.0) * smoothstep(0.55, 0.0, r);
	vec3 field = mix(vec3(0.25, 0.08, 0.45), vec3(0.75, 0.2, 0.55), uv.y);
	field += vec3(1.0, 0.9, 0.6) * rays * 0.7 + vec3(1.0, 0.95, 0.8) * smoothstep(0.12, 0.0, r);
	// rainbow foil that slides with the view angle
	float shift = dot(VIEW, vec3(1.0, 0.6, 0.0)) * 2.0 + uv.x * 3.0 + uv.y * 2.0;
	vec3 foil = 0.5 + 0.5 * cos(6.2831 * (shift + vec3(0.0, 0.33, 0.67)));
	float sparkle = step(0.985, hash(floor(uv * 90.0))) * 0.8;
	field = mix(field, field * 0.6 + foil * 0.6, 0.35) + sparkle;
	// a text box near the bottom (blank lines, no real text)
	float box = step(0.12, uv.x) * step(uv.x, 0.88) * step(0.72, uv.y) * step(uv.y, 0.9);
	vec3 boxc = vec3(0.95, 0.93, 0.88) - 0.25 * step(0.5, fract(uv.y * 28.0)) * step(0.16, uv.x) * step(uv.x, 0.8);
	field = mix(field, boxc, box * 0.9);
	ALBEDO = mix(gold, field, border);
	EMISSION = ALBEDO * 0.35;
}
