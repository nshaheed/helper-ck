#include FRAME_UNIFORMS
#include DRAW_UNIFORMS
#include STANDARD_VERTEX_INPUT
#include STANDARD_VERTEX_OUTPUT
#include STANDARD_VERTEX_SHADER

// our custom material uniforms
@group(1) @binding(0) var src: texture_2d<f32>;
@group(1) @binding(1) var<storage> max_samples: array<f32>;
@group(1) @binding(2) var<storage> min_samples: array<f32>;
@group(1) @binding(3) var<uniform> playhead: i32;
@group(1) @binding(4) var<uniform> playhead_width: i32;
@group(1) @binding(5) var<storage> rms_samples: array<f32>;

fn onWaveform(coords: vec2i, dim: vec2u) -> bool {
  return i32((0.5 + max_samples[coords.x] * 0.5) * f32(dim.y)) == coords.y;
}

fn waveformColor() -> vec4f {
  return vec4f(0.5, 0.5, 0.5, 1.0); // green
}

fn rmsColor() -> vec4f {
  return vec4f(0.25, 0.25, 0.95, 1.0); // green
}

fn playheadColor() -> vec4f {
  return vec4f(1.0, 1.0, 1.0, 0.5);
}

fn backgroundColor() -> vec4f {
  return vec4f(0.0, 0.0, 0.0, 1.0); // black
}


fn alive(coords: vec2i, dim: vec2u) -> vec4f {
  // these should all be > 50% height
  let pos_max : i32 = i32((0.5 + max_samples[coords.x] * 0.5) * f32(dim.y));
  // these  should all be < 50% height
  let pos_min : i32 = i32((0.5 + min_samples[coords.x] * 0.5) * f32(dim.y));
  let pos_rms : i32 = i32((0.5 + rms_samples[coords.x] * 0.5) * f32(dim.y));

  // this works
  // let on_waveform : bool = coords.y < pos_max && coords.y > i32(dim.y) - pos_max ;
  // let on_waveform : bool = coords.y < pos_min && coords.y > pos_min ;
  let on_waveform : bool = coords.y < pos_max && coords.y > pos_min ;

  let on_rms : bool = coords.y < pos_rms && coords.y > i32(dim.y) - pos_rms;
  // let on_rms : bool = coords.y < pos_rms;

  if (on_rms) {
    return rmsColor();
  }

  if (on_waveform) {
    return waveformColor();
  }

  if (coords.x >= playhead && coords.x <= playhead + playhead_width) {
    return playheadColor();
  }

  let v = textureLoad(src, coords, 0);
  if (v.r < 0.5) {
    return backgroundColor();
  }
  return vec4f(1.0);
}

@fragment
fn fs_main(in : VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4f
{
  let dim : vec2u = textureDimensions(src);

  let coords = vec2i(in.v_uv * vec2f(dim));
  return alive(coords, dim);
  // var cell = vec4f(f32(alive(coords, dim)));

  // return vec4f(cell); // render current generation
}
