#include FRAME_UNIFORMS
#include DRAW_UNIFORMS
#include STANDARD_VERTEX_INPUT
#include STANDARD_VERTEX_OUTPUT
#include STANDARD_VERTEX_SHADER

// our custom material uniforms
@group(1) @binding(0) var src: texture_2d<f32>;
@group(1) @binding(1) var<storage> max_samples: array<f32>;
@group(1) @binding(2) var<storage> min_samples: array<f32>;
@group(1) @binding(3) var<uniform> playhead: f32;
@group(1) @binding(4) var<uniform> playhead_width: f32;
@group(1) @binding(5) var<storage> rms_samples: array<f32>;
@group(1) @binding(6) var<uniform> scrolled: i32;

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

fn scrolledX(uv_x: f32, dim_x: u32) -> i32 {
  if (scrolled == 0) { return i32(uv_x * f32(dim_x)); }

  // return i32(uv_x * f32(dim_x));
  let scroll = playhead / f32(dim_x);
  let x = fract(uv_x + scroll);
  return i32(x * f32(dim_x));
}


fn alive(coords: vec2i, dim: vec2u, uv: vec2f) -> vec4f {
  // how to handle two position modes:
  // - fixed buffer - always treat [0] as the first position in the buffer
  // - scrolling buffer - the playhead is always at the end (relative)

  let x = scrolledX(uv.x, dim.x);

  let pos_max = (0.5 + max_samples[x] * 0.5) * f32(dim.y);
  let pos_min = (0.5 + min_samples[x] * 0.5) * f32(dim.y);
  let pos_rms = (0.5 + rms_samples[x] * 0.5) * f32(dim.y);

  // this works
  // let on_waveform : bool = coords.y < pos_max && coords.y > i32(dim.y) - pos_max ;
  // let on_waveform : bool = coords.y < pos_min && coords.y > pos_min ;
  // let on_waveform : bool = coords.y < pos_max && coords.y > pos_min ;

  // let on_rms : bool = coords.y < pos_rms && coords.y > i32(dim.y) - pos_rms;
  // let on_rms : bool = coords.y < pos_rms;

  let y = f32(coords.y);

  let on_waveform = y < pos_max && y > pos_min;
  let on_rms = y < pos_rms && y > f32(dim.y) - pos_rms;

  let w : f32 = playhead_width;

  if (on_rms) {
    return rmsColor();
  }

  if (on_waveform) {
    return waveformColor();
  }

  // Playhead highlight (also UV based)
  let px = uv.x * f32(dim.x);
  if (abs(px - playhead) <= playhead_width * 0.5 && scrolled == 0) {
    // return playheadColor();
  }


  // if (new_x >= playhead && new_x <= playhead + playhead_width) {
  //   return playheadColor();
  // }

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
  return alive(coords, dim, in.v_uv);
}
