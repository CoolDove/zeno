package main

@(private="file")
_paint : Paint

Paint :: struct {
    canvas : ^Canvas,
    layer : ^Layer,
    brush : u32,
    daps : [dynamic]Dap,
    activate : bool,
}

Dap :: struct {
    position : Vec2,
    angle : f32,
    scale : f32,
}

paint_begin :: proc(canvas: ^Canvas, layer: ^Layer) {
    // Copy the layer 
    _paint.activate = true
    _paint.canvas = canvas
    _paint.layer = layer
}
paint_end :: proc() {
    _paint.activate = false
    _paint.canvas = nil
    _paint.layer = nil
    clear(&_paint.daps)
}

paint_push_dap :: proc(dap: Dap) {
    append(&_paint.daps, dap)
}

// Draw n daps, and return how many daps remained, -1 means draw all daps.
paint_draw :: proc(n:int= -1) -> int {
    if len(_paint.daps) == 0 do return 0
    // n := max(n, len(_paint.daps))
    n := len(_paint.daps)// @Temporary: Draw all the daps
    for i in 0..<n {
        d := _paint.daps[i]
        c := _paint.canvas
        paint_dap_on_texture(c.texid, {auto_cast c.width, auto_cast c.height}, d)
    }
    clear(&_paint.daps)
    return 0
}

// How many daps need to be drawn.
paint_count :: proc() -> int {
    return len(_paint.daps)
}

paint_is_painting :: proc() -> bool {
    return _paint.activate
}