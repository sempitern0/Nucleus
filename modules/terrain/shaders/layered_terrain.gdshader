shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.24, 0.38, 0.18, 1.0);
uniform float height_min = -20.0;
uniform float height_max = 50.0;
uniform bool use_triplanar = false;
uniform int debug_view = 0;
uniform float debug_height_bands = 6.0;
uniform float debug_grid_scale = 10.0;

uniform bool layer0_enabled = false;
uniform bool layer0_use_texture = false;
uniform sampler2D layer0_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 layer0_tint : source_color = vec4(1.0);
uniform float layer0_uv_scale = 0.08;
uniform vec2 layer0_height_range = vec2(0.0, 1.0);
uniform vec2 layer0_slope_range = vec2(0.0, 1.0);
uniform float layer0_softness = 0.08;
uniform float layer0_roughness = 0.9;
uniform float layer0_metallic = 0.0;

uniform bool layer1_enabled = false;
uniform bool layer1_use_texture = false;
uniform sampler2D layer1_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 layer1_tint : source_color = vec4(1.0);
uniform float layer1_uv_scale = 0.08;
uniform vec2 layer1_height_range = vec2(0.0, 1.0);
uniform vec2 layer1_slope_range = vec2(0.0, 1.0);
uniform float layer1_softness = 0.08;
uniform float layer1_roughness = 0.9;
uniform float layer1_metallic = 0.0;

uniform bool layer2_enabled = false;
uniform bool layer2_use_texture = false;
uniform sampler2D layer2_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 layer2_tint : source_color = vec4(1.0);
uniform float layer2_uv_scale = 0.08;
uniform vec2 layer2_height_range = vec2(0.0, 1.0);
uniform vec2 layer2_slope_range = vec2(0.0, 1.0);
uniform float layer2_softness = 0.08;
uniform float layer2_roughness = 0.9;
uniform float layer2_metallic = 0.0;

uniform bool layer3_enabled = false;
uniform bool layer3_use_texture = false;
uniform sampler2D layer3_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform vec4 layer3_tint : source_color = vec4(1.0);
uniform float layer3_uv_scale = 0.08;
uniform vec2 layer3_height_range = vec2(0.0, 1.0);
uniform vec2 layer3_slope_range = vec2(0.0, 1.0);
uniform float layer3_softness = 0.08;
uniform float layer3_roughness = 0.9;
uniform float layer3_metallic = 0.0;

varying vec3 world_position;
varying vec3 world_normal;
varying float terrain_height;

float range_weight(float value, vec2 limits, float softness) {
	float low = smoothstep(limits.x - softness, limits.x + softness, value);
	float high = 1.0 - smoothstep(limits.y - softness, limits.y + softness, value);
	return max(low * high, 0.0);
}

vec3 sample_projected(
	sampler2D texture_source,
	vec3 position,
	vec3 normal_abs,
	float scale,
	bool triplanar
) {
	if (!triplanar) {
		return texture(texture_source, position.xz * scale).rgb;
	}

	vec3 weights = pow(normal_abs, vec3(4.0));
	weights /= max(weights.x + weights.y + weights.z, 0.0001);
	vec3 x_color = texture(texture_source, position.zy * scale).rgb;
	vec3 y_color = texture(texture_source, position.xz * scale).rgb;
	vec3 z_color = texture(texture_source, position.xy * scale).rgb;
	return x_color * weights.x + y_color * weights.y + z_color * weights.z;
}

vec3 layer_color(
	sampler2D texture_source,
	bool use_texture,
	vec4 tint,
	vec3 position,
	vec3 normal_abs,
	float scale
) {
	vec3 color = vec3(1.0);
	if (use_texture) {
		color = sample_projected(
			texture_source,
			position,
			normal_abs,
			scale,
			use_triplanar
		);
	}
	return color * tint.rgb;
}

vec3 height_band_color(float normalized_height) {
	float bands = max(debug_height_bands, 2.0);
	float band = floor(clamp(normalized_height, 0.0, 0.9999) * bands);
	float value = band / max(bands - 1.0, 1.0);
	vec3 phase = vec3(0.00, 0.33, 0.67);
	return 0.55 + 0.45 * cos(6.283185 * (phase + value));
}

vec3 world_grid_color(vec3 position) {
	float scale = max(debug_grid_scale, 0.1);
	vec2 cell = floor(position.xz / scale);
	float checker = mod(cell.x + cell.y, 2.0);
	vec3 dark = vec3(0.08, 0.10, 0.12);
	vec3 light = vec3(0.70, 0.74, 0.80);
	return mix(dark, light, checker);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(mat3(MODEL_MATRIX) * NORMAL);
	terrain_height = VERTEX.y;
}

void fragment() {
	float normalized_height = clamp(
		(terrain_height - height_min) / max(height_max - height_min, 0.0001),
		0.0,
		1.0
	);
	float slope = 1.0 - clamp(abs(world_normal.y), 0.0, 1.0);
	vec3 normal_abs = abs(world_normal);

	float w0 = layer0_enabled ? range_weight(
		normalized_height,
		layer0_height_range,
		layer0_softness
	) * range_weight(slope, layer0_slope_range, layer0_softness) : 0.0;
	float w1 = layer1_enabled ? range_weight(
		normalized_height,
		layer1_height_range,
		layer1_softness
	) * range_weight(slope, layer1_slope_range, layer1_softness) : 0.0;
	float w2 = layer2_enabled ? range_weight(
		normalized_height,
		layer2_height_range,
		layer2_softness
	) * range_weight(slope, layer2_slope_range, layer2_softness) : 0.0;
	float w3 = layer3_enabled ? range_weight(
		normalized_height,
		layer3_height_range,
		layer3_softness
	) * range_weight(slope, layer3_slope_range, layer3_softness) : 0.0;

	float total = w0 + w1 + w2 + w3;
	vec3 color = base_color.rgb;
	float roughness = 1.0;
	float metallic = 0.0;

	if (total > 0.0001) {
		w0 /= total;
		w1 /= total;
		w2 /= total;
		w3 /= total;
	}

	if (debug_view == 1) {
		color = height_band_color(normalized_height);
	} else if (debug_view == 2) {
		color = mix(
			vec3(0.08, 0.72, 0.22),
			vec3(0.96, 0.12, 0.05),
			slope
		);
	} else if (debug_view == 3) {
		color = world_normal * 0.5 + 0.5;
	} else if (debug_view == 4) {
		if (total > 0.0001) {
			color = (
				vec3(0.92, 0.72, 0.20) * w0
				+ vec3(0.18, 0.76, 0.22) * w1
				+ vec3(0.48, 0.50, 0.54) * w2
				+ vec3(0.88, 0.94, 1.00) * w3
			);
		} else {
			color = vec3(1.0, 0.0, 1.0);
		}
	} else if (debug_view == 5) {
		color = world_grid_color(world_position);
	} else if (total > 0.0001) {
		color = vec3(0.0);
		roughness = 0.0;
		metallic = 0.0;

		if (w0 > 0.0) {
			color += layer_color(
				layer0_albedo,
				layer0_use_texture,
				layer0_tint,
				world_position,
				normal_abs,
				layer0_uv_scale
			) * w0;
			roughness += layer0_roughness * w0;
			metallic += layer0_metallic * w0;
		}
		if (w1 > 0.0) {
			color += layer_color(
				layer1_albedo,
				layer1_use_texture,
				layer1_tint,
				world_position,
				normal_abs,
				layer1_uv_scale
			) * w1;
			roughness += layer1_roughness * w1;
			metallic += layer1_metallic * w1;
		}
		if (w2 > 0.0) {
			color += layer_color(
				layer2_albedo,
				layer2_use_texture,
				layer2_tint,
				world_position,
				normal_abs,
				layer2_uv_scale
			) * w2;
			roughness += layer2_roughness * w2;
			metallic += layer2_metallic * w2;
		}
		if (w3 > 0.0) {
			color += layer_color(
				layer3_albedo,
				layer3_use_texture,
				layer3_tint,
				world_position,
				normal_abs,
				layer3_uv_scale
			) * w3;
			roughness += layer3_roughness * w3;
			metallic += layer3_metallic * w3;
		}
	}

	ALBEDO = color;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}
