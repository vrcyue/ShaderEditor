#version 310 es
precision highp float;
precision highp int;
precision highp uimage2D;

layout(location = 0) out vec4 fragColor;
layout(r32ui) uniform coherent uimage2D computeTex[3];
layout(r32ui) uniform coherent uimage2D computeTexBack[3];

uniform vec2 resolution;
uniform float time;

uint packColor(vec3 rgb) {
	return packUnorm4x8(vec4(rgb, 1.0));
}

vec3 unpackColor(uint packed) {
	return unpackUnorm4x8(packed).rgb;
}

// Simple wrapping helper to keep indices in-bounds.
ivec2 wrap(ivec2 uv, ivec2 size) {
	return ivec2(
			(uv.x % size.x + size.x) % size.x,
			(uv.y % size.y + size.y) % size.y);
}

void main() {
	ivec2 size = ivec2(resolution);
	ivec2 uv = ivec2(gl_FragCoord.xy);

	// Read last frame (front/back swap is handled by the renderer).
	vec3 prev = unpackColor(imageLoad(computeTexBack[0], uv).r);

	// Fade previous frame slightly.
	vec3 color = prev * 0.96;

	// Add a pulsing ring in the center.
	vec2 p = (vec2(uv) + 0.5) / resolution * 2.0 - 1.0;
	float ring = exp(-12.0 * abs(length(p) - 0.5));
	float twinkle = 0.5 + 0.5 * sin(3.0 * p.x + time * 1.6);
	color += vec3(0.2, 0.8, 1.0) * ring * twinkle * 0.6;

	// Read a neighbor pixel from the previous frame to show imageLoad.
	ivec2 offset = ivec2(sin(time) * 2.0, cos(time * 0.7) * 2.0);
	ivec2 n = wrap(uv + offset, size);
	vec3 neighbor = unpackColor(imageLoad(computeTexBack[0], n).r);
	color = mix(color, neighbor, 0.2);

	// Write the new color for this frame.
	imageStore(computeTex[0], uv, uvec4(packColor(color)));

	// And output to the screen.
	fragColor = vec4(color, 1.0);
}
