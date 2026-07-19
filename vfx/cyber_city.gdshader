shader_type canvas_item;

uniform vec4 void_color : source_color = vec4(0.04, 0.02, 0.08, 1.0);
uniform float rain_speed : hint_range(0.0, 4.0) = 1.55;
uniform float glitch_amount : hint_range(0.0, 1.0) = 0.42;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float rain(vec2 uv, float t) {
	vec2 grid = vec2(uv.x * 78.0, uv.y * 28.0 + t * rain_speed * 8.5);
	vec2 id = floor(grid);
	vec2 f = fract(grid);
	float n = hash(id);
	float drop = smoothstep(0.018, 0.0, abs(f.x - 0.5)) * step(0.7, n);
	drop *= smoothstep(1.0, 0.15, f.y);
	return drop * (0.25 + 0.75 * hash(id + 3.1));
}

void fragment() {
	vec2 uv = UV;
	vec3 col = void_color.rgb;

	float horizon = 0.52;
	if (uv.y > horizon) {
		// Perspective neon grid floor + wet amber sheen
		float fy = (uv.y - horizon) / (1.0 - horizon);
		float persp = 1.0 / max(fy, 0.02);
		float gx = abs(fract((uv.x - 0.5) * persp * 0.35) - 0.5);
		float gy = abs(fract(persp * 0.08 - TIME * 0.38) - 0.5);
		float grid = smoothstep(0.038, 0.0, gx) + smoothstep(0.055, 0.0, gy);
		col += vec3(1.0, 0.12, 0.65) * grid * fy * 0.6;
		col += vec3(0.08, 0.75, 1.0) * fy * 0.14;
		col += vec3(1.0, 0.55, 0.12) * fy * fy * 0.08;
		// Rain reflection streaks
		float refl = rain(vec2(uv.x, 1.0 - uv.y * 0.4), TIME * 0.8);
		col += vec3(0.4, 0.7, 1.0) * refl * fy * 0.25;
	} else {
		// Upper city haze
		col += vec3(0.14, 0.02, 0.1) * (1.0 - uv.y);

		// Building silhouettes
		float bx = floor(uv.x * 22.0);
		float bh = 0.18 + hash(vec2(bx, 2.7)) * 0.28;
		float building = step(uv.y, horizon - 0.02) * step(horizon - bh, uv.y);
		col = mix(col, col * 0.35, building * 0.85);

		// Window lights (cyan / magenta / amber)
		if (building > 0.5) {
			vec2 wuv = vec2(uv.x * 55.0, uv.y * 40.0);
			vec2 wid = floor(wuv);
			float wn = hash(wid + bx);
			if (wn > 0.78) {
				float pulse = 0.55 + 0.45 * sin(TIME * (1.5 + wn * 3.0) + wn * 20.0);
				vec3 wcol = mix(vec3(0.15, 0.9, 1.0), vec3(1.0, 0.2, 0.7), step(0.9, wn));
				wcol = mix(wcol, vec3(1.0, 0.75, 0.2), step(0.96, wn));
				col += wcol * pulse * 0.22 * step(0.35, fract(wuv.x)) * step(0.35, fract(wuv.y));
			}
		}

		// Floating neon signs
		vec2 sign_uv = uv * vec2(18.0, 10.0);
		vec2 sid = floor(sign_uv);
		float sn = hash(sid);
		if (sn > 0.86 && uv.y < 0.45) {
			float pulse = 0.5 + 0.5 * sin(TIME * (2.0 + sn * 4.0) + sn * 30.0);
			vec3 neon = mix(vec3(1.0, 0.12, 0.65), vec3(0.12, 0.95, 1.0), step(0.93, sn));
			neon = mix(neon, vec3(1.0, 0.7, 0.15), step(0.97, sn));
			col += neon * pulse * 0.4 * (1.0 - uv.y);
		}
	}

	// Rain
	float r = rain(uv, TIME) + rain(uv + vec2(0.37, 0.11), TIME * 1.15) * 0.65;
	col += vec3(0.55, 0.78, 1.0) * r * 0.4;

	// Scanlines
	float scan = 0.07 * sin((uv.y + TIME * 0.18) * 1200.0);
	col += vec3(0.18, 0.04, 0.2) * scan;

	// Occasional glitch band
	float band = step(0.982, hash(vec2(floor(TIME * 7.0), floor(uv.y * 48.0))));
	col.rg += band * glitch_amount * vec2(0.3, -0.18);
	col.b += band * glitch_amount * 0.08;

	// Vignette
	float vig = smoothstep(0.98, 0.22, length((uv - 0.5) * vec2(1.25, 1.0)));
	col *= vig;

	COLOR = vec4(col, 1.0);
}
