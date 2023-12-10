package main

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

    brush_texture_left, brush_texture_right : u32,
}

Dap :: struct {
    position : Vec2,
    angle : f32,
    scale : f32,
}

paint_init :: proc() {
    _paint.daps = make_dynamic_array_len_cap([dynamic]Dap, 0, 1024)
}
paint_release :: proc() {
    delete(_paint.daps)
}

paint_begin :: proc(canvas: ^Canvas, layer: ^Layer) {
    // Copy the layer 
    _paint.activate = true
    _paint.canvas = canvas
    _paint.layer = layer
    using _paint

    // brush_texture_left, brush_texture_right = canvas_fetch_brush_texture(canvas)
}
paint_end :: proc() {
    c := _paint.canvas 
    // dgl.blit(c.brush_tex_buffer, c.texid, c.width, c.height)

    _paint.activate = false
    _paint.canvas = nil
    _paint.layer = nil

    _paint.current_dap = 0
    clear(&_paint.daps)
}

paint_push_dap :: proc(dap: Dap) {
    append(&_paint.daps, dap)
}

// Draw n daps, and return how many daps remained, -1 means draw all daps.
paint_draw :: proc(n:i32= -1) -> i32 {
    remained := cast(i32)len(_paint.daps) - _paint.current_dap
    n := min(n, remained)// @Temporary: Draw all the daps
    if n == -1 do n = remained

    for i in 0..<n {
        d := _paint.daps[_paint.current_dap]
        c := _paint.canvas
        using _paint
        // paint_dap_on_texture(c.brush_tex_buffer, brush_texture_left, {auto_cast c.width, auto_cast c.height}, d)
        _paint.brush_texture_left, _paint.brush_texture_right = 
            _paint.brush_texture_right, _paint.brush_texture_left 
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