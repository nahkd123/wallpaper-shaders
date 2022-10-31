#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform float battery;
uniform int powerConnected;
uniform sampler2D backbuffer;

#define PI 3.1415926535898
#define FULL vec4(0.5, 1.0, 0.5, 1.0)
#define MID vec4(0.5, 0.7, 1.0, 1.0)
#define CRITICAL vec4(1.0, 0.5, 0.5, 1.0)

float wave(vec2 uv, float flySpeed, float ampSpeed, float ampChange) {
  float waveHeight = sin((uv.x + time * flySpeed) * PI) * (0.05 + sin(time * ampSpeed) * ampChange);
  float yBoundMin = waveHeight - 10.01;
  float yBoundMax = waveHeight + 0.01;
  return (uv.y > yBoundMin && uv.y < yBoundMax)? clamp(0.0, 1.0, 1.0 - (waveHeight - uv.y) / 3.0) : 0.0;
}

vec4 waves(vec2 uv, float batteryLevel) {
  uv.y -= (batteryLevel * 2.0 - 1.0) * 1.5;
  vec4 col = vec4(0);
  vec4 batColL0 = batteryLevel < 0.5?
    mix(CRITICAL, MID, batteryLevel / 0.5) :
    mix(MID, FULL, (batteryLevel - 0.5) / 0.5);
  vec4 batColL1 = powerConnected == 1? FULL : batColL0;
  col += wave(uv, 0.5, 0.6, 0.02) * batColL1;
  col += wave(uv + vec2(0, 0.01 * batteryLevel), 0.53, 0.6, 0.02) * vec4(0.8, 0.9, 0.73, 1) * batColL1 * 0.3;
  col += wave(uv + vec2(0, -0.01 * batteryLevel), 0.6, 0.6, 0.02) * vec4(0.7, 0.6, 0.5, 1) * batColL1 * 0.2;
  return col;
}

void main(void) {
  vec2 uv = (2.0 * gl_FragCoord.xy - resolution) / resolution.x;
  gl_FragColor = texture2D(backbuffer, gl_FragCoord.xy / resolution) * 0.2 + waves(uv, battery) * 0.8;
}
