package main

import gl "vendor:OpenGL"
import nvg "vendor:nanovg"

Canvas :: struct {
    imgid : int,
    width, height : int,
}

canvas_init :: proc(vg: ^nvg.Context, canvas: ^Canvas, width,height: int, color : [4]u8) {
    // canvas.imgid = texture_create_with_color(width, height, color, false)
    data := make_slice([]byte, 4 * width * height); defer delete(data)
    for i in 0..<(width * height) {
        if (i*3)%2==0 do continue
        for c in 0..<4 do data[i*4+c] = color[c]
    }
    canvas.imgid = nvg.CreateImageRGBA(vg, auto_cast width, auto_cast height, {}, data)
    canvas.width, canvas.height = width, height
}
canvas_release :: proc(vg: ^nvg.Context, canvas: ^Canvas) {
    nvg.DeleteImage(vg, canvas.imgid)
    // gl.DeleteTextures(1, &canvas.imgid)
}

texture_create_with_color :: proc(width, height : int, color : [4]u8, gen_mipmap := false) -> u32 {
    tex : u32
    gl.GenTextures(1, &tex)
    gl.BindTexture(gl.TEXTURE_2D, tex)

    target :u32= gl.TEXTURE_2D
    gl.TexParameteri(target, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(target, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(target, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(target, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    data := make([dynamic][4]u8, 0, width * height)
    for i := 0; i < width * height; i += 1 {
        append(&data, color)
    }

    gl.TexImage2D(target, 0, gl.RGBA, cast(i32)width, cast(i32)height, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(data))
    if gen_mipmap do gl.GenerateMipmap(target)
    return tex
}

