#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform vec4 brush_color;

void main() {
    vec4 src = brush_color;
    float alpha = 1 - clamp(distance(_uv, vec2(0.5,0.5)) * 2, 0,1);
    alpha = smoothstep(0.0,0.1, alpha);
    src.a *= alpha;
    FragColor = src;
}