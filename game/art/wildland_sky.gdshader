// A distant atmosphere, not a weather simulation. Cloud shapes stay coherent
// across frames; there are no TIME-driven radiance updates or world geometry.
shader_type sky;
uniform vec4 sky_top : source_color = vec4(0.27, 0.42, 0.60, 1.0);
uniform vec4 sky_horizon : source_color = vec4(0.66, 0.71, 0.70, 1.0);
uniform vec4 cloud_colour : source_color = vec4(0.83, 0.83, 0.78, 1.0);
uniform vec4 ground_colour : source_color = vec4(0.20, 0.23, 0.18, 1.0);
uniform float cloud_coverage = 0.61;
uniform float cloud_opacity = 0.40;
uniform float cloud_scale = 7.6;

float hash_cloud(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float cloud_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash_cloud(i), hash_cloud(i + vec2(1,0)), f.x),
		mix(hash_cloud(i + vec2(0,1)), hash_cloud(i + vec2(1,1)), f.x), f.y);
}

void sky() {
	float elevation = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 colour = mix(sky_horizon.rgb, sky_top.rgb, pow(elevation, 0.56));
	if (EYEDIR.y < 0.0) {
		colour = mix(sky_horizon.rgb, ground_colour.rgb, smoothstep(0.0, 0.36, -EYEDIR.y));
	}
	// A simple sky gradient is sufficient for diffuse ambient/reflection
	// lighting; only the visible sky pays for the coherent cloud shapes.
	if (!AT_CUBEMAP_PASS && EYEDIR.y > 0.015) {
		vec2 plane = EYEDIR.xz / (EYEDIR.y + 0.24) * cloud_scale;
		plane = mat2(vec2(0.92,0.38),vec2(-0.38,0.92)) * plane;
		float broad = cloud_noise(plane);
		float detail = cloud_noise(plane * 2.13 + vec2(7.4,19.3));
		float lace = cloud_noise(plane * 4.27 + vec2(31.2,8.1));
		float cover = smoothstep(cloud_coverage - 0.08, cloud_coverage + 0.13, broad * 0.48 + detail * 0.34 + lace * 0.18);
		float fade = smoothstep(0.08, 0.30, EYEDIR.y);
		vec3 cloud = cloud_colour.rgb * (0.88 + detail * 0.12);
		colour = mix(colour, cloud, cover * fade * cloud_opacity);
	}
	COLOR = colour;
}
