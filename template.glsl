#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform float time;
uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;

void main(void) {
  vec2 uv = (2.0 * gl_FragCoord.xy - resolution) / resolution.x;
  gl_FragColor = vec4(uv, 0.0, 1.0);
}
