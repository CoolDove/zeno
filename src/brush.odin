package main

import "core:fmt"
import gl "vendor:OpenGL"
import "dgl"

// dst_tex and target_tex should have the same content.
paint_dap_on_texture :: proc(target_tex, tex : u32, viewport_size : Vec2, dap: Dap) {
    @static quad : dgl.DrawPrimitive
    @static shader : dgl.ShaderId
    @static fbo : dgl.FramebufferId
    if shader == 0 {
        fmt.printf("Initialize")
        shader = dgl.shader_load_from_sources(#load("./shaders/brush.vert"), #load("./shaders/brush.frag"))
        quad = dgl.primitive_make_quad_a({1,0,0,0.5})
        fbo = dgl.framebuffer_create()
        _shaderv_brush_init(shader)
    }

    dgl.framebuffer_bind(fbo); defer dgl.framebuffer_bind_default()
    dgl.framebuffer_attach_color(0, target_tex); defer dgl.framebuffer_dettach_color(0)
    gl.Viewport(0,0, auto_cast viewport_size.x, auto_cast viewport_size.y)
    
    dgl.shader_bind(shader)
    _shaderv_brush.uniform_viewport_size(viewport_size)
    _shaderv_brush.uniform_dap_info(dap.position, dap.scale, dap.angle)
    _shaderv_brush.uniform_textures(tex)
    dgl.primitive_draw(&quad, shader)
}

@(private="file")
_SHADER_LOC_VIEWPORT_SIZE : i32
@(private="file")
_SHADER_LOC_DAP_INFO : i32
@(private="file")
_SHADER_LOC_MAIN_TEXTURE : i32
// @(private="file") _SHADER_LOC_DST_TEXTURE : i32

@(private="file")
_shaderv_brush_init :: proc(shader: u32) {
    _SHADER_LOC_VIEWPORT_SIZE = gl.GetUniformLocation(shader, "viewport_size")
    _SHADER_LOC_DAP_INFO = gl.GetUniformLocation(shader, "dap_info")
    _SHADER_LOC_MAIN_TEXTURE = gl.GetUniformLocation(shader, "main_texture")
    // _SHADER_LOC_DST_TEXTURE = gl.GetUniformLocation(shader, "dst_texture")
}

@(private="file")
ShaderVBrush :: struct {
    uniform_viewport_size : proc(size: Vec2),
    uniform_dap_info : proc(position: Vec2, scale, rotation : f32),
    uniform_textures : proc(main_tex: u32),
}

@(private="file")
_shaderv_brush : ShaderVBrush= {
    uniform_viewport_size = proc(size: Vec2) {
        gl.Uniform2f(_SHADER_LOC_VIEWPORT_SIZE, size.x, size.y)
    },
    uniform_dap_info = proc(position: Vec2, scale, rotation : f32) {
        gl.Uniform4f(_SHADER_LOC_DAP_INFO, position.x, position.y, scale, rotation)
    },
    uniform_textures = proc(main_tex: u32) {
        gl.ActiveTexture(gl.TEXTURE0)
        gl.BindTexture(gl.TEXTURE_2D, main_tex)
        // gl.ActiveTexture(gl.TEXTURE1)
        // gl.BindTexture(gl.TEXTURE_2D, dst)
        gl.Uniform1i(_SHADER_LOC_MAIN_TEXTURE, 0)
        // gl.Uniform1i(_SHADER_LOC_SRC_TEXTURE, 1)
    }
}