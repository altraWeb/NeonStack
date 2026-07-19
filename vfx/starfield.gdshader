shader_type canvas_item;

uniform vec4 void_color : source_color = vec4(0.02, 0.03, 0.05, 1.0);
uniform float speed : hint_range(0.0, 2.0) = 0.08;
uniform float density : hint_range(10.0, 120.0) = 55.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = void_color.rgb;
	col += vec3(0.01, 0.03, 0.05) * (1.0 - uv.y);

	vec2 grid = uv * density;
	vec2 cell = floor(grid);
	vec2 f = fract(grid);
	float n = hash(cell);
	vec2 star = vec2(hash(cell + 0.1), hash(cell + 0.2));
	float twinkle = 0.5 + 0.5 * sin(TIME * (2.0 + n * 3.0) + n * 20.0);
	float d = distance(f, star);
	float star_a = smoothstep(0.04, 0.0, d) * twinkle * step(0.82, n);
	col += vec3(0.55, 0.85, 1.0) * star_a;

	float scan = 0.04 * sin((uv.y + TIME * speed) * 900.0);
	col += vec3(0.05, 0.12, 0.16) * scan;

	COLOR = vec4(col, 1.0);
}
