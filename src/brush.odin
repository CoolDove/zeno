package main

import "core:fmt"
import gl "vendor:OpenGL"
import "dgl"

// BrushUniforms :: struct {
//     viewport_size : dgl.UniformLocVec2,
//     dap_info : dgl.UniformLocVec4,
//     brush_color : dgl.UniformLocVec4,
//     main_texture, mixbox_lut : dgl.UniformLocTexture,
// }

// @(private="file")
// _brush_uniforms : BrushUniforms

// dst_tex and target_tex should have the same content.
// paint_dap_on_texture :: proc(target_tex, tex : u32, viewport : Vec2, dap: Dap) {
//     @static quad : dgl.DrawPrimitive
//     @static shader : dgl.ShaderId
//     @static fbo : dgl.FramebufferId
//     if shader == 0 {
//         shader = dgl.shader_load_from_sources(#load("./shaders/brush.vert"), #load("./shaders/brush.frag"), true)
//         quad = dgl.primitive_make_quad_a({1,0,0,0.5})
//         fbo = dgl.framebuffer_create()
//         dgl.uniform_load(&_brush_uniforms, shader)
//         fmt.printf("brush uniforms: {}\n", _brush_uniforms)
//     }

//     dgl.framebuffer_bind(fbo); defer dgl.framebuffer_bind_default()
//     dgl.framebuffer_attach_color(0, target_tex); defer dgl.framebuffer_dettach_color(0)
//     gl.Viewport(0,0, auto_cast viewport.x, auto_cast viewport.y)
    
//     dgl.shader_bind(shader)
//     using dgl, _brush_uniforms
//     uniform_set(viewport_size, viewport)
//     uniform_set(dap_info, Vec4{dap.position.x, dap.position.y, dap.scale, dap.angle})
//     uniform_set(main_texture, tex, 0)
//     uniform_set(mixbox_lut, TEXTURE_MIXBOX_LUT, 1)
//     uniform_set(brush_color, app.brush_color)
//     dgl.primitive_draw(&quad, shader)
// }