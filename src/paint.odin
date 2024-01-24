package main

import "core:math/linalg"
import "core:math"
import "core:log"
import "core:fmt"
import gl "vendor:OpenGL"
import "dgl"

// @(private="file")
_paint : Paint

Paint :: struct {
    canvas : ^Canvas,
    layer : ^Layer,
    brush : u32,

    current_dap : i32,
    daps : [dynamic]Dap,
    activate : bool,
    dirty_rect : Vec4,

    brush_texture : u32,

    // Cold
    using engine : PaintEngine,
}

PaintEngine :: struct {
    paint_fbo : dgl.FramebufferId,

    brush_quad : dgl.DrawPrimitive,

    brush_shader_default : dgl.ShaderId,
    uniforms_brush_shader_default : BrushUniforms,
}

Dap :: struct {
    position : Vec2,
    angle : f32,
    scale : f32,
}

paint_init :: proc() {
    _paint.daps = make_dynamic_array_len_cap([dynamic]Dap, 0, 1024)

    _paint.paint_fbo = dgl.framebuffer_create()
    _paint.brush_quad = dgl.primitive_make_quad_a({1,0,0,0.5})

    { // Brush shader default
        _paint.brush_shader_default = dgl.shader_load_from_sources(
            #load("./shaders/brush.vert"), 
            #load("./shaders/brush.frag"), true)
        dgl.uniform_load(&_paint.uniforms_brush_shader_default, _paint.brush_shader_default)
    }
    _paint.dirty_rect = {}
}
paint_release :: proc() {
    dgl.shader_destroy(_paint.brush_shader_default)

    dgl.primitive_delete(&_paint.brush_quad)
    
    dgl.framebuffer_destroy(_paint.paint_fbo)
    delete(_paint.daps)
}

paint_begin :: proc(canvas: ^Canvas, layer: ^Layer) {
    // Copy the layer 
    _paint.activate = true
    _paint.canvas = canvas
    _paint.layer = layer
    _paint.dirty_rect = {}
    using _paint

    brush_texture = canvas.compose.compose_brush
    dgl.blit_clear(brush_texture, {1,1,1,0}, canvas.width, canvas.height)
}
paint_end :: proc() {
    if len(_paint.daps) == 0 {
        log.warn("Paint: No daps painted, invalid paint.")
    } else {
        c := _paint.canvas 
        w,h := c.width, c.height

        r := _paint.dirty_rect
        r.x = math.max(0, r.x)
        r.y = math.max(0, r.y)
        r.z = math.min(r.z, cast(f32)w-r.x)
        r.w = math.min(r.w, cast(f32)h-r.y)
        history_push(&_paint.canvas.history, zmd_modify_layer(_paint.layer, r))

        gl.Disable(gl.BLEND); defer gl.Enable(gl.BLEND)
        current_layer := &c.layers[c.current_layer]
        dgl.blit(current_layer.tex, c.buffer_left, w,h)
        compose_pigment(c.compose.compose_brush, c.buffer_left, current_layer.tex, w,h)
        dgl.blit_clear(c.compose.compose_brush, {1,1,1,0}, w,h)
    }

    _paint.activate = false
    _paint.canvas = nil
    _paint.layer = nil

    _paint.current_dap = 0
    clear(&_paint.daps)
}

paint_push_dap :: proc(dap: Dap) {
    append(&_paint.daps, dap)

    r := &_paint.dirty_rect
    u := dap.scale * 2.4 + 4
    min := dap.position - 0.5*{u,u}
    max := min + {u,u}
    if r.z == 0 {
        r^= {min.x,min.y, u,u}
    } else {
        if min.x < r.x {
            r.z += r.x-min.x
            r.x = min.x
        }
        if min.y < r.y {
            r.w += r.y-min.y
            r.y = min.y
        }
        if max.x > r.x+r.z do r.z = math.max(max.x - r.x, r.z)
        if max.y > r.y+r.w do r.w = math.max(max.y - r.y, r.w)
    }
}

// Draw n daps, and return how many daps remained, n==-1 means draw all daps.
paint_draw :: proc(n:i32= -1) -> i32 {
    remained := cast(i32)len(_paint.daps) - _paint.current_dap
    n := min(n, remained)// @Temporary: Draw all the daps
    if n == -1 do n = remained

    if n <= 0 do return 0

    // Blend settings
    rem_blend := dgl.state_get_blend_ex(); defer dgl.state_set_blend(rem_blend)
    dgl.state_set_blend(dgl.GlStateBlendEx{
        enable = true,
        src_rgb = gl.ONE,
        dst_rgb = gl.ZERO,
        src_alpha = gl.SRC_ALPHA,
        dst_alpha = gl.ZERO,
        equation_rgb = gl.FUNC_ADD,
        equation_alpha = gl.MAX,
    })

    using _paint
    // Draw daps
    dgl.framebuffer_bind(paint_fbo); defer dgl.framebuffer_bind_default()
    dgl.framebuffer_attach_color(0, brush_texture); defer dgl.framebuffer_dettach_color(0)

    rem_vp := dgl.state_get_viewport(); defer dgl.state_set_viewport(rem_vp)
    gl.Viewport(0,0,canvas.width, canvas.height)

    dgl.shader_bind(_paint.brush_shader_default)
    uniform := &_paint.uniforms_brush_shader_default
    for i in 0..<n {
        d := daps[_paint.current_dap]
        using _paint

        using dgl
        uniform_set(uniform.viewport_size, Vec2{auto_cast canvas.width, auto_cast canvas.height})
        uniform_set(uniform.dap_info, Vec4{d.position.x, d.position.y, d.scale, d.angle})
        uniform_set(uniform.brush_color, app.brush_color)

        dgl.primitive_draw(&_paint.brush_quad, _paint.brush_shader_default)
        _paint.current_dap += 1
    }
    return paint_remained()
}

// How many daps need to be drawn.
paint_count :: proc() -> int {
    return len(_paint.daps)
}

paint_is_painting :: proc() -> bool {
    return _paint.activate
}
paint_remained :: #force_inline proc() -> i32 {
    return cast(i32)len(_paint.daps) - _paint.current_dap
}


// Brush
BrushUniforms :: struct {
    viewport_size : dgl.UniformLocVec2,
    dap_info : dgl.UniformLocVec4,
    brush_color : dgl.UniformLocVec4,
}

@(private="file")
_brush_uniforms : BrushUniforms
