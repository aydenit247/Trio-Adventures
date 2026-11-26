// The 3D trio's look (Asar 11/25: "darker, more contrast, colors that impress"). Meshy's PBR textures, re-graded:
// a deeper, punchier albedo (contrast + saturation around the mids, a little darker overall), a soft rim light
// so they pop off the background, and Unit's night fill (emission) the same way set_fill() always did.
shader_type spatial;
render_mode cull_disabled, fog_disabled;   // the heroes stay crisp in the morning mist

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap, repeat_enable;   // G roughness, B metallic
uniform bool has_normal = true;

uniform float exposure = 0.72;       // overall brightness of the albedo (1 = Meshy's)
uniform float contrast = 1.5;       // around the mid-grey, in display space
uniform float saturation = 1.45;
uniform float shadow_lift = 0.0;    // keeps the darkest bits from going pure black
uniform float rough_mul = 1.1;     // a touch more sheen than Meshy's flat 0.54
uniform float spec = 0.25;
uniform float rim = 0.08;
uniform float rim_tint = 1.0;       // 0 = white rim, 1 = rim takes the surface colour
uniform vec3 fill = vec3(0.0);      // night fill (Char3D.set_fill)

vec3 grade(vec3 lin) {
	vec3 s = pow(max(lin, vec3(0.0)), vec3(1.0 / 2.2));        // to display space
	s = (s - 0.5) * contrast + 0.5;
	float l = dot(s, vec3(0.299, 0.587, 0.114));
	s = mix(vec3(l), s, saturation);
	s = clamp(s, vec3(0.0), vec3(1.0));
	s = s * (1.0 - shadow_lift) + shadow_lift;
	return pow(s, vec3(2.2)) * exposure;                       // back to linear
}

void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb;
	vec3 c = grade(base);
	ALBEDO = c;
	vec4 orm = texture(orm_tex, UV);
	ROUGHNESS = clamp(orm.g * rough_mul, 0.05, 1.0);
	METALLIC = orm.b;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	SPECULAR = spec;
	RIM = rim;
	RIM_TINT = rim_tint;
	EMISSION = base * fill;
}
