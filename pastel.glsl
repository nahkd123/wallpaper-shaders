// WARNING: Heavy shader ahead!
// I highly recommend setting shader resolution to
// 1/2 on low-end phones to ensure your phone is not
// lagging on main or lock screen.

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform int frame;

#define OCTAVES 6
#define FRAGMENT_SIZE (1. / 7.)
#define RED vec4(1.0, 0.8, 0.8, 1.0)
#define YELLOW vec4(1.0, 0.9, 0.76, 1.0)
#define GREEN vec4(0.9, 1.0, 0.8, 1.0)
#define AQUA vec4(0.87, 0.98, 1.0, 1.0)
#define BLUE vec4(0.85, 0.9, 1.0, 1.0)
#define PURPLE vec4(0.86, 0.8, 1.0, 1.0)
#define PINK vec4(0.97, 0.82, 1.0, 1.0)

vec4 pastel(float p, float light) {
  p = clamp(p, 0.0, 1.0);
  light = clamp(light, 0.0, 1.0);
  vec4 base = p < (1. / 7.)? mix(AQUA, PINK, p / FRAGMENT_SIZE) :
  p < (2. / 7.)? mix(PINK, BLUE, (p - (1. / 7.)) / FRAGMENT_SIZE) :
  p < (3. / 7.)? mix(BLUE, RED, (p - (2. / 7.)) / FRAGMENT_SIZE) :
  p < (4. / 7.)? mix(RED, YELLOW, (p - (3. / 7.)) / FRAGMENT_SIZE) :
  p < (5. / 7.)? mix(YELLOW, PURPLE, (p - (4. / 7.)) / FRAGMENT_SIZE) :
  p < (6. / 7.)? mix(PURPLE, GREEN, (p - (5. / 7.)) / FRAGMENT_SIZE) :
  mix(GREEN, AQUA, (p - (6. / 7.)) / FRAGMENT_SIZE);
  return base * clamp(vec4(pow(light, 0.9), pow(light, 1.1), pow(light, 1.2), 1.0), vec4(0), vec4(1));
}

float random(vec2 v) {
  return fract(sin(dot(v.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// https://shadertoy.com/view/4dS3Wd
float noise(vec2 uv) {
  vec2 i = floor(uv);
  vec2 f = fract(uv);

  float a = random(i);
  float b = random(i + vec2(1, 0));
  float c = random(i + vec2(0, 1));
  float d = random(i + vec2(1, 1));
  vec2 u = f * f * (3. - 2. * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 uv, float freq, float amp, int oct) {
  float sum = 0.0;
  for (int i = 0; i < oct; i++) {
    sum += amp * noise(uv);
    uv *= 2.0;
    amp *= 0.8;
  }
  return sum;
}

vec4 image(vec2 uv) {
  uv += vec2(2);
  float brightness = fbm((uv + vec2(time * 0.1)) * 10.0 + vec2(fbm((uv + vec2(time * 0.13)) * 10.0, 1.0, 1.0, 5)), 1.0, 0.4, 6);
  float col = fbm((uv + vec2(time * 0.11)) * brightness, 1.0, 0.5, 4);
  return pastel(col, 0.5 + brightness * 0.4);
}

// performance improvement: render 50% first, 50% after
// flickering might occured
bool interleaves() {
  float x = mod(gl_FragCoord.x, 1.0);
  float y = mod(gl_FragCoord.y, 1.0);
  float f = mod(float(frame), 2.0);
  return x >= f && x <= f + 1.0 && y >= f && y <= f + 1.0;
}

void main(void) {
  vec2 uv = (2.0 * gl_FragCoord.xy - resolution) / resolution.x;
  bool noRender = frame > 0 && random((gl_FragCoord.xy / resolution) * time) > 0.2;
  if (noRender) {
    gl_FragColor = texture2D(backbuffer, gl_FragCoord.xy / resolution);
    return;
  }
  gl_FragColor = image(uv);
}
