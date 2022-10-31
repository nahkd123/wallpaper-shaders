#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform vec2 offset;

#define FRAGMENT_SIZE (1. / 7.)
#define PI 3.1415926535898
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
  vec4 base = p < (1. / 7.)? mix(RED, YELLOW, p / FRAGMENT_SIZE) :
  p < (2. / 7.)? mix(YELLOW, GREEN, (p - (1. / 7.)) / FRAGMENT_SIZE) :
  p < (3. / 7.)? mix(GREEN, AQUA, (p - (2. / 7.)) / FRAGMENT_SIZE) :
  p < (4. / 7.)? mix(AQUA, BLUE, (p - (3. / 7.)) / FRAGMENT_SIZE) :
  p < (5. / 7.)? mix(BLUE, PURPLE, (p - (4. / 7.)) / FRAGMENT_SIZE) :
  p < (6. / 7.)? mix(PURPLE, PINK, (p - (5. / 7.)) / FRAGMENT_SIZE) :
  mix(PINK, RED, (p - (6. / 7.)) / FRAGMENT_SIZE);
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

float rodMask(vec2 uv, vec2 dir, float radius) {
  float d = dot(uv, vec2(-dir.y, dir.x));
  return d > -radius && d < radius? 1.0 : 0.0;
}

float rodMaskCapped(vec2 uv, vec2 dir, float thickness, float forward) {
  return rodMask(uv, dir, thickness) * rodMask(uv, vec2(-dir.y, dir.x), forward);
}

vec4 grid(vec2 uv, float size) {
  return vec4((mod(uv, size) / size) * 2.0 - vec2(1), floor(uv / size));
}

vec2 rotateUV(vec2 uv, float angle) {
  return vec2(uv.x * cos(angle) - uv.y * sin(angle), uv.x * sin(angle) + uv.y * cos(angle));
}

float gridCircleMask(vec2 uv) {
  return distance(uv, vec2(0)) < 1.0? 1.0 : 0.0;
}

float gridCornerMask(vec2 uv) {
  return 1.0 - gridCircleMask(((uv - vec2(1, 1)) * 0.5));
}

float gridSquareMask(vec2 uv) {
  return uv.x > -0.8 && uv.x < 0.8 && uv.y > -0.8 && uv.y < 0.8? 1.0 : 0.0;
}

float gridDiamondMask(vec2 uv) {
  return gridSquareMask(rotateUV(uv * 0.8 / 0.6, PI / 4.0));
}

float gridCrossMask(vec2 uv) {
  return clamp(
    rodMaskCapped(uv, normalize(vec2(1, 1)), 0.2, 0.8) +
    rodMaskCapped(uv, normalize(vec2(1, -1)), 0.2, 0.8), 0.0, 1.0);
}

float gridPlusMask(vec2 uv) {
  return gridCrossMask(rotateUV(uv, PI / 4.0));
}

vec4 blend(vec4 curr, vec4 col) {
  return curr * (1.0 - col.w) + col * col.w;
}

float gridMask(vec2 gridUV, float rand) {
  float mask =
    rand < 0.15? gridCircleMask(gridUV * 1.34) :
    rand < 0.3? gridSquareMask(gridUV * 1.2) :
    rand < 0.45? gridDiamondMask(gridUV * 1.1) :
    rand < 0.6? gridCrossMask(gridUV * 1.2) :
    rand < 0.75? gridPlusMask(gridUV * 1.1) :
    gridCornerMask(gridUV * 1.27);
  return mask * gridSquareMask(gridUV);
}

vec4 image(vec2 uv) {
  uv += vec2(time / 28.0, -time / 36.0);

  vec4 gridInf = grid(uv, 0.5);
  vec2 gridUV = gridInf.xy;
  vec2 gridPos = gridInf.zw;

  float rand = random(gridPos);
  float rand2 = random(gridPos + vec2(12, 34));
  float rand3 = random(gridPos + vec2(-12, 32));
  float rotation =
    rand2 < 0.25? 0.0 :
    rand2 < 0.5? (PI / 2.0) :
    rand2 < 0.75? PI :
    ((3.0 * PI) / 2.0);
  gridUV = rotateUV(gridUV, rotation);
  vec4 objCol = pastel(mod(time / 10.0 + rand3, 1.0), 1.0);
  vec4 objColDark = pastel(mod(time / 10.0 + rand3, 1.0), 0.78);

  vec4 col = objColDark;
  col = blend(col, objCol * gridMask(gridUV, rand));
  return col;
}

void main(void) {
  vec2 uv = (2.0 * gl_FragCoord.xy - resolution) / resolution.x;
  gl_FragColor = image(uv + offset);
}
