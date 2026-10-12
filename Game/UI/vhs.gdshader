shader_type canvas_item;
// VHS overlay แบบเบา — ใช้ได้ทั้ง Forward+ / Mobile / Compatibility (เว็บ)
// วางบน ColorRect เต็มจอใน CanvasLayer ที่ layer ต่ำกว่า UI (ดู UiKit.vhs_layer) — ห้ามวางทับ UI

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float strength : hint_range(0.0, 2.0) = 1.0;
uniform float scanline_density = 360.0;
uniform float grain = 0.06;
uniform float vignette = 0.55;
uniform float chroma = 0.0015;
// เพิ่มตอนโดนไล่ล่า (0..1) ทำให้ภาพสั่น/สีเพี้ยนขึ้น
uniform float distortion : hint_range(0.0, 1.0) = 0.0;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float wobble = sin(uv.y * 40.0 + TIME * 6.0) * 0.0015 * distortion;
	float jitter = (rand(vec2(floor(TIME * 20.0), floor(uv.y * 80.0))) - 0.5) * 0.004 * distortion;
	uv.x += wobble + jitter;
	float ca = chroma * strength * (1.0 + distortion * 4.0);
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(ca, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(ca, 0.0)).b;
	float scan = 0.5 + 0.5 * sin(uv.y * scanline_density * 3.14159);
	col *= 1.0 - 0.12 * strength * scan;
	col += (rand(uv * TIME) - 0.5) * grain * strength;
	vec2 d = SCREEN_UV - 0.5;
	col *= 1.0 - dot(d, d) * vignette * 2.0 * strength;
	COLOR = vec4(col, 1.0);
}
