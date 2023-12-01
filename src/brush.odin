package main

import "core:fmt"
import gl "vendor:OpenGL"
import "dgl"

BrushUniforms :: struct {
    viewport_size : dgl.UniformLocVec2,
    dap_info : dgl.UniformLocVec4,
    brush_color : dgl.UniformLocVec4,
    main_texture, mixbox_lut : dgl.UniformLocTexture,
}

@(private="file")
_brush_uniforms : BrushUniforms

// dst_tex and target_tex should have the same content.
paint_dap_on_texture :: proc(target_tex, tex : u32, viewport : Vec2, dap: Dap) {
    @static quad : dgl.DrawPrimitive
    @static shader : dgl.ShaderId
    @static fbo : dgl.FramebufferId
    @static mixbox_lut_tex : u32
    if shader == 0 {
        shader = dgl.shader_load_from_sources(#load("./shaders/brush.vert"), #load("./shaders/brush.frag"), true)
        mixbox_lut_tex = dgl.texture_load_from_mem(#load("../res/mixbox_lut.png", []u8)).id
        quad = dgl.primitive_make_quad_a({1,0,0,0.5})
        fbo = dgl.framebuffer_create()
        dgl.uniform_load(&_brush_uniforms, shader)
        fmt.printf("brush uniforms: {}\n", _brush_uniforms)
    }

    dgl.framebuffer_bind(fbo); defer dgl.framebuffer_bind_default()
    dgl.framebuffer_attach_color(0, target_tex); defer dgl.framebuffer_dettach_color(0)
    gl.Viewport(0,0, auto_cast viewport.x, auto_cast viewport.y)
    
    dgl.shader_bind(shader)
    using dgl, _brush_uniforms
    uniform_set(viewport_size, viewport)
    uniform_set(dap_info, Vec4{dap.position.x, dap.position.y, dap.scale, dap.angle})
    uniform_set(main_texture, tex, 0)
    uniform_set(mixbox_lut, mixbox_lut_tex, 1)
    uniform_set(brush_color, app.brush_color)
    // _shaderv_brush.uniform_viewport_size(viewport_size)
    // _shaderv_brush.uniform_dap_info(dap.position, dap.scale, dap.angle)
    // _shaderv_brush.uniform_textures(tex, mixbox_lut)
    // _shaderv_brush.uniform_color(app.brush_color)
    dgl.primitive_draw(&quad, shader)
}


// @(private="file")
// ShaderVBrush :: struct {
//     uniform_viewport_size : proc(size: Vec2),
//     uniform_dap_info : proc(position: Vec2, scale, rotation : f32),
//     uniform_textures : proc(main_tex, mixlut: u32),
//     uniform_color : proc(color: Vec4),
// }

// @(private="file")
// _shaderv_brush : ShaderVBrush= {
//     uniform_viewport_size = proc(size: Vec2) {
//         gl.Uniform2f(_brush_uniforms.viewport_size, size.x, size.y)
//     },
//     uniform_dap_info = proc(position: Vec2, scale, rotation : f32) {
//         gl.Uniform4f(_brush_uniforms.dap_info, position.x, position.y, scale, rotation)
//     },
//     uniform_textures = proc(main_tex, mixlut: u32) {
//         gl.ActiveTexture(gl.TEXTURE0)
//         gl.BindTexture(gl.TEXTURE_2D, main_tex)
//         gl.ActiveTexture(gl.TEXTURE1)
//         gl.BindTexture(gl.TEXTURE_2D, mixlut)
//         gl.Uniform1i(_brush_uniforms.main_texture, 0)
//         gl.Uniform1i(_brush_uniforms.mixbox_lut, 1)
//     },
//     uniform_color = proc(color : Vec4) {
//         gl.Uniform4f(_brush_uniforms.brush_color, color.r,color.g,color.b,color.a)
//     }
// }