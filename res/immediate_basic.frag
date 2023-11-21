#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform sampler2D main_texture;

void main() { 
    vec4 c = texture(main_texture, _uv);
    FragColor = c * _color;
}
