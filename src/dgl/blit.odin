package dgl

import gl "vendor:OpenGL"


@(private="file")
_blit_fbo : FramebufferId
@(private="file")
_blit_shader : ShaderId
@(private="file")
_SHADER_LOC_MAIN_TEXTURE : i32
@(private="file")
_blit_quad : DrawPrimitive

blit :: proc(src, dst: u32, w,h: i32) {
    if _blit_shader == 0 {
        _blit_shader = shader_load_from_sources(_BLITTER_VERT, _BLITTER_FRAG)
        _SHADER_LOC_MAIN_TEXTURE = gl.GetUniformLocation(_blit_shader, "main_texture")
        _blit_quad = primitive_make_quad_a({1,1,1,1})
        _blit_fbo = framebuffer_create()
        append(&release_handler, proc() {
            gl.DeleteProgram(_blit_shader)
            primitive_delete(&_blit_quad)
            framebuffer_destroy(_blit_fbo)
        })
    }

    framebuffer_bind(_blit_fbo)
    framebuffer_attach_color(0, dst)

    gl.Viewport(0,0, w,h)
    shader_bind(_blit_shader)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, src)
    gl.Uniform1i(_SHADER_LOC_MAIN_TEXTURE, 0)

    primitive_draw(&_blit_quad, _blit_shader)
}

blit_clear :: proc(texture: u32, color: Vec4) {
    framebuffer_bind(_blit_fbo)
    framebuffer_attach_color(0, texture)
    gl.ClearColor(color.r, color.g, color.b, color.a)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}

@(private="file")
_BLITTER_VERT :string: `
#version 440 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec4 color;
layout (location = 2) in vec2 uv;

layout(location = 0) out vec2 _uv;
layout(location = 1) out vec4 _color;


void main()
{
    vec2 p = vec2(position.x, position.y);
    p = p * 2 - 1;

    gl_Position = vec4(p.x, p.y, 0, 1.0);
	_uv = uv;
    _uv.y = 1 - _uv.y;
    _color = color;
}
`

@(private="file")
_BLITTER_FRAG :string: `
#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform sampler2D main_texture;

void main() {
    vec4 c = texture(main_texture, _uv);
    FragColor = c;
}
`