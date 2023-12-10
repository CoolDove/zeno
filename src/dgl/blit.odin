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

CustomBlitter :: struct {
    prepare : proc(shader : ShaderId, src, dst: u32, w,h: i32),
    shader : ShaderId,
}

// If you want to set some custom uniforms, you should manually bind the shader
//  you're going to use before this process. And remember texture slot 0 has 
//  been used.
blit_with_shader :: proc(shader : ShaderId, main_texture_loc : i32, src, dst: u32, w,h: i32) {
    if !_blit_is_initialized() do _blit_init()
    rem_fbo := framebuffer_current(); defer framebuffer_bind(rem_fbo)
    rem_shader := shader_current(); defer shader_bind(rem_shader)
    rem_viewport := state_get_viewport(); defer state_set_viewport(rem_viewport)
    framebuffer_bind(_blit_fbo)
    framebuffer_attach_color(0, dst)

    gl.Viewport(0,0, w,h)
    shader_bind(shader)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, src)
    gl.Uniform1i(main_texture_loc, 0)

    blit_draw_unit_quad(shader)
}
blit :: proc(src, dst: u32, w,h: i32) {// With default blit shader.
    blit_with_shader(_blit_shader,_SHADER_LOC_MAIN_TEXTURE, src,dst, w,h)
}
blit_make_blit_shader :: proc(fragment_source : string) -> ShaderId {
    return shader_load_from_sources(_BLITTER_VERT, fragment_source)
}

blit_draw_unit_quad :: #force_inline proc(shader: ShaderId) {
    if !_blit_is_initialized() do _blit_init()
    primitive_draw(&_blit_quad, shader)
}

blit_clear :: proc(texture: u32, color: Vec4) {
    if !_blit_is_initialized() do _blit_init()
    fbo := framebuffer_current(); defer framebuffer_bind(fbo)
    framebuffer_bind(_blit_fbo)
    framebuffer_attach_color(0, texture)
    gl.ClearColor(color.r, color.g, color.b, color.a)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}

@(private="file")
_blit_is_initialized :: #force_inline proc() -> bool {
    return _blit_shader != 0
}
@(private="file")
_blit_init :: proc() {
    _blit_shader = blit_make_blit_shader(_BLITTER_FRAG)
    _SHADER_LOC_MAIN_TEXTURE = gl.GetUniformLocation(_blit_shader, "main_texture")
    _blit_quad = primitive_make_quad_a({1,1,1,1})
    _blit_fbo = framebuffer_create()
    append(&release_handler, proc() {
        gl.DeleteProgram(_blit_shader)
        primitive_delete(&_blit_quad)
        framebuffer_destroy(_blit_fbo)
    })
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