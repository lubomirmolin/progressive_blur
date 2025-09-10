#version 460 core
#include <flutter/runtime_effect.glsl>

#define MAX_KERNEL_SIZE 255

uniform sampler2D child_texture;   // current pass input
uniform vec2 child_size;

uniform sampler2D blur_texture;    // map texture (sigma map or blend mask)
uniform float blur_sigma;          // base sigma
uniform float blur_direction;      // 0 = horizontal, 1 = vertical
// -1 for negative side (left/up), 0 for symmetric, +1 for positive side (right/down)
uniform float blur_side;
// 0 = modulate sigma by map, 1 = blend between original and blurred by map
uniform float blur_map_mode;
// 0 = intermediate pass, 1 = final pass (where blending happens)
uniform float is_final_pass;

// Original, unblurred image; only sampled in final pass when blending
uniform sampler2D original_texture;

uniform vec4 tint_color;
// Adjusts the response curve of the blur map: 1.0 = linear,
// <1.0 = softer, >1.0 = sharper. Default is 2.0.
uniform float map_exponent;

out vec4 frag_color;

void main() {
  vec2 uv = FlutterFragCoord().xy / child_size;
  
  // Apply response curve to the blur map
  float blur_value = pow(texture(blur_texture, uv).r, max(map_exponent, 0.0001));
  float sigma = (blur_map_mode < 0.5) ? (blur_sigma * blur_value) : blur_sigma;
  vec2 dir = blur_direction == 0.0 ? vec2(1.0, 0.0) : vec2(0.0, 1.0);

  // Base color (used for sigma ~ 0 and tint-only cases)
  vec4 base = texture(child_texture, uv);
  if (sigma < 1e-5) {
    if (blur_map_mode >= 0.5) {
      if (is_final_pass > 0.5) {
        // Blend original with current (already blurred horizontally if any)
        vec2 uv_orig = vec2(uv.x, 1.0 - uv.y);
        vec4 orig = texture(original_texture, uv_orig);
        vec4 blurredTint = mix(base, tint_color, blur_value * tint_color.a);
        frag_color = mix(orig, blurredTint, blur_value);
      } else {
        frag_color = base; // no tinting in intermediate pass
      }
    } else {
      float tint_strength0 = blur_value * tint_color.a;
      frag_color = mix(base, tint_color, tint_strength0);
    }
    return;
  }

  int kernel_radius = int(ceil(3.0 * sigma));
  int kernel_size = 2 * kernel_radius + 1;
  if (kernel_size > MAX_KERNEL_SIZE) {
    kernel_radius = MAX_KERNEL_SIZE / 2;
    kernel_size = MAX_KERNEL_SIZE;
  }

  float total_weight = 0.0;

  vec4 color = vec4(0);

  float side = (blur_map_mode < 0.5) ? blur_side : 0.0; // enforce symmetric in blend mode
  if (side == 0.0) {
    // Symmetric kernel (-r..+r)
    for (int i = 0; i < MAX_KERNEL_SIZE; i++) {
      if (i >= kernel_size) break;
      int v = i - kernel_radius;
      float weight = exp(-float(v * v) / (2.0 * sigma * sigma));
      total_weight += weight;
      vec2 offset = vec2(float(v)) / child_size;
      offset *= dir;
      color += texture(child_texture, uv + offset) * weight;
    }
  } else {
    // One-sided kernel (0..+r) in the chosen direction
    float s = side > 0.0 ? 1.0 : -1.0;
    for (int i = 0; i <= MAX_KERNEL_SIZE; i++) {
      if (i > kernel_radius) break;
      int v = i; // 0..r
      float weight = exp(-float(v * v) / (2.0 * sigma * sigma));
      total_weight += weight;
      vec2 offset = vec2(s * float(v)) / child_size;
      offset *= dir;
      color += texture(child_texture, uv + offset) * weight;
    }
  }

  vec4 blurred = color / total_weight;
  if (blur_map_mode >= 0.5) {
    if (is_final_pass > 0.5) {
      vec2 uv_orig = vec2(uv.x, 1.0 - uv.y);
      vec4 orig = texture(original_texture, uv_orig);
      vec4 blurredTint = mix(blurred, tint_color, blur_value * tint_color.a);
      frag_color = mix(orig, blurredTint, blur_value);
    } else {
      frag_color = blurred; // intermediate pass output
    }
  } else {
    float tint_strength = blur_value * tint_color.a;
    frag_color = mix(blurred, tint_color, tint_strength);
  }
}
