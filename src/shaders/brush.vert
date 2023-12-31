#version 440 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec4 color;
layout (location = 2) in vec2 uv;

layout(location = 0) out vec2 _uv;
layout(location = 1) out vec4 _color;

uniform vec2 viewport_size;
uniform vec4 dap_info;// xy: position, z: scale, w: angle

void main()
{
    vec2 p = vec2(position.x, position.y);
    float angle = dap_info.w;
    float ca = cos(angle);
    float sa = sin(angle);
    p = p - vec2(0.5, 0.5);
    p = vec2(p.x * ca + p.y * sa, p.y * ca - p.x * sa);
    p = p + vec2(0.5, 0.5);
    p = (p-vec2(0.5,0.5)) * vec2(2,2);

    p = p * dap_info.z + vec2(dap_info.x, dap_info.y);
    p = p / viewport_size;
    p = p * 2 - 1;

    gl_Position = vec4(p.x, p.y, 0, 1.0);
	_uv = uv;
    _color = color;
}