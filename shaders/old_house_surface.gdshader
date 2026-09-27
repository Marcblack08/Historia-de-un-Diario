shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.12, 0.08, 0.055, 1.0);
uniform vec4 detail_color : source_color = vec4(0.025, 0.018, 0.014, 1.0);
uniform float roughness : hint_range(0.05, 1.0) = 0.82;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float detail_scale : hint_range(0.2, 20.0) = 4.0;
uniform float stain_strength : hint_range(0.0, 1.0) = 0.28;
uniform float moisture : hint_range(0.0, 1.0) = 0.0;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.18;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * detail_scale;
	float n1 = noise2(p * 0.55);
	float n2 = noise2(p * 1.8);
	float grain = mix(n1, n2, 0.35);
	float stain = smoothstep(0.58, 0.88, noise2(p * 0.32 + vec2(7.0, 3.0)));

	vec3 color = mix(base_color.rgb, detail_color.rgb, stain * stain_strength);
	color *= 0.84 + grain * grain_strength;
	color = mix(color, color * vec3(0.72, 0.76, 0.80), moisture * 0.22);

	ALBEDO = color;
	METALLIC = metallic;
	ROUGHNESS = clamp(roughness - moisture * 0.35 - grain * 0.04, 0.05, 1.0);
	SPECULAR = 0.35 + moisture * 0.35;
}
