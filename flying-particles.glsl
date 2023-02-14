#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

#define PARTICLES 20.0
#define PARTICLE_LIFE 1.7
#define PI 3.1415926535898
#define PARTICLE_RAY_ANGLE (PI / 4.0)

#define FRAGMENT_SIZE (1. / 7.)
#define RED vec4(1.0, 0.8, 0.8, 1.0)
#define YELLOW vec4(1.0, 0.9, 0.76, 1.0)
#define GREEN vec4(0.9, 1.0, 0.8, 1.0)
#define AQUA vec4(0.87, 0.98, 1.0, 1.0)
#define BLUE vec4(0.85, 0.9, 1.0, 1.0)
#define PURPLE vec4(0.86, 0.8, 1.0, 1.0)
#define PINK vec4(0.97, 0.82, 1.0, 1.0)

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform int powerConnected;

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

vec2 randomFlyDir(vec2 v, float rot) {
  float angle = rot + PI * 0.5 + (random(v * 12.149281) - 0.5) * PARTICLE_RAY_ANGLE * (powerConnected == 1? 0.1 : 1.0);
  float d = 0.3 + random(v * 51.39192) * 0.7;
  return vec2(cos(angle), sin(angle)) * d;
}

vec4 renderParticle(float idx, vec2 uv) {
  float tShifted = (time + idx * 0.7) / (PARTICLE_LIFE * (powerConnected == 1? 0.8 : 1.0));
  float cycleProg = fract(tShifted);
  float cycleIdx = tShifted - cycleProg;
  float visiblity = cos(cycleProg * PI - PI / 2.0);

  vec2 dir = randomFlyDir(vec2(idx, cycleIdx), powerConnected == 1? 0.0 : (cycleProg * (random(vec2(cycleIdx)) - 0.5) * 0.5));
  vec2 xPos = vec2((idx / PARTICLES - 0.5) * 2.0 * resolution.x, -resolution.y / 2.0);
  float d = distance(uv, xPos + dir * cycleProg * resolution.y * 1.2);
  float intensity = (1. / d) * max(resolution.x, resolution.y) * 0.001;
  return pastel(idx / PARTICLES, 5.0) * intensity * visiblity;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy - resolution / 2.0;
  float height = resolution.y;
  for (float i = 0.; i <= PARTICLES; i++) {
    gl_FragColor += renderParticle(i, uv);
  }
}
