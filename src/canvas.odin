package main

import gl "vendor:OpenGL"
import "dgl"

Canvas :: struct {
    // Data
    // Some of this will be moved to layer data.
    texid : u32,

    width, height : i32,

    layers : [dynamic]Layer,

    layer_compose : LayerComposeData,

    // Camera
    offset : Vec2,
    scale : f32,
    using coord : ^Coordinate,

    // Brush
    brush_tex_buffer : u32,// Used during painting.
    brush_tex_left : u32,// Used during painting.
    brush_tex_right : u32,// Used during painting.
}

Layer :: struct {
    tex : u32,
    transparency : f32,
    visible : bool,
}

canvas_init :: proc {
    canvas_init_with_color,
    canvas_init_with_file,
}

canvas_init_with_file :: proc(canvas: ^Canvas, filename: string) -> bool {
    tex := dgl.texture_load_by_path(filename, false)
    if tex.id == 0 do return false

    canvas.width = tex.size.x
    canvas.height = tex.size.y
    canvas.texid = tex.id

    canvas.scale = 1
    canvas.coord = &canvas_coord

    _canvas_init_brush_texture(canvas)
    return true
}
canvas_init_with_color :: proc(canvas: ^Canvas, width,height: i32, color : Color32) {
    data := make_slice([]byte, 4 * width * height); defer delete(data)
    for i in 0..<(width * height) {
        for c in 0..<4 do data[cast(int)i*4+c] = color[c]
    }
    canvas.width, canvas.height = width, height
    canvas.texid = dgl.texture_create_with_color(cast(int)width, cast(int)height, color)

    canvas.scale = 1
    canvas.coord = &canvas_coord
    _canvas_init_brush_texture(canvas)
}

@(private="file")
_canvas_init_brush_texture :: proc(using canvas: ^Canvas) {
    brush_tex_buffer = dgl.texture_create_empty(auto_cast canvas.width, auto_cast canvas.height)
    brush_tex_left = dgl.texture_create_empty(auto_cast canvas.width, auto_cast canvas.height)
    brush_tex_right = dgl.texture_create_empty(auto_cast canvas.width, auto_cast canvas.height)
    // brush_tex_right = dgl.texture_create_with_color(
    //     auto_cast canvas.width, auto_cast canvas.height, 
    //     [4]u8{255,255,255,255}, false)
}

canvas_release :: proc(using canvas: ^Canvas) {
    gl.DeleteTextures(1, &texid)
    gl.DeleteTextures(1, &brush_tex_buffer)
    gl.DeleteTextures(1, &brush_tex_left)
    gl.DeleteTextures(1, &brush_tex_right)
    canvas^= {}
}

canvas_fetch_brush_texture :: proc(using canvas: ^Canvas) -> (u32, u32) {
    dgl.blit(texid, brush_tex_buffer, width, height)
    dgl.blit(texid, brush_tex_left, width, height)
    dgl.blit(texid, brush_tex_right, width, height)
    return brush_tex_left, brush_tex_right
}