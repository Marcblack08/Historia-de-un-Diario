shader_type canvas_item;

uniform float rain_speed : hint_range(0.1, 3.0) = 1.0;
uniform float rain_density : hint_range(0.0, 2.0) = 0.85;
uniform float rain_alpha : hint_range(0.0, 0.35) = 0.09;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	float left_dark = 1.0 - smoothstep(0.22, 0.62, uv.x);
	float vignette = smoothstep(0.95, 0.28, distance(uv, vec2(0.5)));
	vec2 grid = uv * vec2(115.0, 70.0);
	grid.y += TIME * rain_speed * 22.0;
	vec2 cell = fract(grid);
	float seed = hash21(floor(grid));
	float streak = step(0.91, seed) * smoothstep(0.95, 0.05, cell.x);
	float fall = smoothstep(0.0, 0.18, cell.y) * smoothstep(1.0, 0.25, cell.y);
	float rain = streak * fall * rain_density;
	float alpha = rain * rain_alpha + left_dark * 0.22 + (1.0 - vignette) * 0.16;
	COLOR = vec4(0.0, 0.0, 0.0, clamp(alpha, 0.0, 0.42));
}