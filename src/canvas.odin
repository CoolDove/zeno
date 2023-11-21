package main

import gl "vendor:OpenGL"
import "dgl"

Canvas :: struct {
    // Data
    texid : u32,
    width, height : i32,

    // Camera
    offset : Vec2,
    scale : f32,
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
    return true
}

canvas_init_with_color :: proc(canvas: ^Canvas, width,height: i32, color : Color32) {
    data := make_slice([]byte, 4 * width * height); defer delete(data)
    for i in 0..<(width * height) {
        for c in 0..<4 do data[cast(int)i*4+c] = color[c]
    }
    canvas.width, canvas.height = width, height
    canvas.texid = dgl.texture_create_with_color(cast(int)width, cast(int)height, color)
}
canvas_release :: proc(using canvas: ^Canvas) {
    gl.DeleteTextures(1, &texid)
    canvas^= {}
}