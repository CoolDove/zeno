#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform sampler2D main_texture;
// uniform sampler2D dst_texture;

void main() {
    vec4 src = _color;
    vec4 dst = texture(main_texture, _uv);

    float outa = src.a + dst.a * (1 - src.a);
    vec3 col = (src.rgb * src.a + dst.rgb * dst.a * (1 - src.a)) / outa;

    FragColor = vec4(col, outa);
    // FragColor = src * 0.5 + dst * 0.5
}
