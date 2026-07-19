shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float chroma : hint_range(0.0, 0.02) = 0.0045;
uniform float kick : hint_range(0.0, 1.0) = 0.0;
uniform float scan_strength : hint_range(0.0, 0.2) = 0.07;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Tear / slice on Tetris kick
	float tear_band = step(0.92, hash(vec2(floor(TIME * 28.0), floor(uv.y * 55.0))));
	uv.x += tear_band * kick * (hash(vec2(floor(uv.y * 80.0), floor(TIME * 12.0))) - 0.5) * 0.04;
	uv.x += sin(uv.y * 40.0 + TIME * 18.0) * kick * 0.006;

	float aberr = chroma + kick * 0.018;
	float r = texture(screen_texture, uv + vec2(aberr, kick * 0.002)).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - vec2(aberr, kick * 0.0015)).b;
	vec3 col = vec3(r, g, b);

	float scan = sin(uv.y * 1500.0 + TIME * 10.0) * scan_strength;
	col += col * scan;

	// Magenta + amber street lift on kick
	col = mix(col, col * vec3(1.25, 0.65, 1.1), kick * 0.4);
	col = mix(col, col * vec3(1.15, 1.05, 0.55), kick * 0.22);

	// Fine grain
	float grain = (hash(uv * vec2(1200.0, 800.0) + TIME) - 0.5) * (0.035 + kick * 0.06);
	col += grain;

	// Soft vignette tightens on kick
	float vig = smoothstep(1.15, 0.2, length((uv - 0.5) * vec2(1.15, 1.0)));
	col *= mix(vig, vig * 0.85, kick);

	COLOR = vec4(col, 1.0);
}
