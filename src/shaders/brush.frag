#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform vec4 brush_color;
uniform sampler2D main_texture;
uniform sampler2D mixbox_lut;

#include "mixbox"

void main() {
    vec4 src = brush_color;
    vec4 dst = texture(main_texture, _uv);
    float outa = src.a + dst.a * (1 - src.a);
    FragColor = mixbox_lerp(dst, src, src.a);
    FragColor.a = outa;
}