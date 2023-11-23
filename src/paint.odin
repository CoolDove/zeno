package main

@(private="file")
_paint : Paint

Paint :: struct {
    canvas : ^Canvas,
    layer : ^Layer,
    brush : u32,
    daps : [dynamic]Dap,
}

Dap :: struct {
    position : Vec2,
    angle : f32,
    scale : f32,
}

paint_begin :: proc(canvas: ^Canvas, layer: ^Layer, brush : u32/*place holder*/) {
    // Copy the layer 
}
paint_end :: proc() {
}

paint_push_dap :: proc(dap: Dap) {
    append(&_paint.daps, dap)
}

// Draw n daps, and return how many daps remained.
paint_draw :: proc(n: int) -> int {
    return 0
}

// How many daps need to be drawn.
paint_count :: proc() -> int {
    return len(_paint.daps)
}

paint_is_painting :: proc() -> bool {
    return false
}