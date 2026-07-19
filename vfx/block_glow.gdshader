shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.3, 0.9, 1.0, 1.0);
uniform float glow_strength : hint_range(0.0, 2.0) = 0.85;
uniform float core_brightness : hint_range(0.0, 2.0) = 1.15;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float core = smoothstep(0.95, 0.15, dist);
	float rim = smoothstep(1.0, 0.55, dist) * (1.0 - smoothstep(0.55, 0.05, dist));
	float alpha = clamp(core * 0.95 + rim * 0.55, 0.0, 1.0);
	vec3 col = glow_color.rgb * (core * core_brightness + rim * glow_strength);
	COLOR = vec4(col, alpha * glow_color.a);
}
