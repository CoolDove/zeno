package main

import sdl "vendor:sdl2"
import nvg "vendor:nanovg"
import "core:fmt"
import "core:time"

debug_draw_immediate_brush_buffers :: proc(canvas: ^Canvas) {
    // Debug
    immediate_texture(
        {10, app.window_size.y - 210},
        Vec2{150, 200}, 
        {1,1,1,1}, 
        canvas.texid)
    immediate_texture(
        {10+150+10, app.window_size.y - 210},
        Vec2{150, 200}, 
        {1,1,1,1}, 
        canvas.texid)
    immediate_texture(
        {10+150+10+150+20, app.window_size.y - 210},
        Vec2{150, 200}, 
        {1,1,1,1}, 
        _paint.brush_texture_left)
    immediate_texture(
        {10+150+10+150+20+150+10, app.window_size.y - 210},
        Vec2{150, 200}, 
        {1,1,1,1}, 
        _paint.brush_texture_right)
}

debug_draw_vg_informations :: proc(vg : ^nvg.Context, canvas: ^Canvas) {
    _textline :: proc(vg: ^nvg.Context, x:f32, y: ^f32, msg: string) {
        nvg.FillColor(vg, {0,0,0,.8})
        nvg.Text(vg, x+1.2, y^+1.2, msg)
        nvg.FillColor(vg, {.2,.8,.1,1.0})
        nvg.Text(vg, x, y^, msg)
        y^ = y^+30
    }
    {
        profile_begin("DrawTexts")
        y :f32= 25
        _textline(vg, 5, &y, fmt.tprintf("FID: {}", app.frame_id))
        _textline(vg, 5, &y, fmt.tprintf("No delay flag: {}", nodelay_flag))
        y += 10
        _textline(vg, 5, &y, fmt.tprintf("brush size: {}", app.brush_size))
        y += 10
        _textline(vg, 5, &y, "canvas:")
        _textline(vg, 10, &y, fmt.tprintf("scale: {}", app.canvas.scale))
        _textline(vg, 10, &y, fmt.tprintf("offset: {}", canvas.offset))
        y += 10
        _textline(vg, 5, &y, "mouse:")
        mouse_cvs : Vec2i
        sdl.GetMouseState(&mouse_cvs.x, &mouse_cvs.y)
        _textline(vg, 10, &y, fmt.tprintf("wnd: {}", vec_i2f(mouse_cvs)))
        _textline(vg, 10, &y, fmt.tprintf("cvs: {}", canvas->wnd2cvs(vec_i2f(mouse_cvs))))
        profile_end()

        profiles := profile_collect()
        y += 10
        _textline(vg, 5, &y, "profile:")
        for p in profiles {
            _textline(vg, 15, &y, fmt.tprintf("{}: {}ms", p.name, time.duration_milliseconds(p.duration)))
        }
    }
}

debug_draw_color_preview_quad :: proc(pos, size: Vec2, color: Vec4) {
    hs := 0.5 * size
    ca := Vec4{.4,.4,.4,1.0}
    cb := Vec4{.8,.8,.8,1.0}

    immediate_quad(pos-{2,2}, size+{4,4}, {.1,.1,.1,1.0})

    immediate_quad(pos, hs, ca)
    immediate_quad(pos+{hs.x,0}, hs, cb)
    immediate_quad(pos+{0,hs.y}, hs, cb)
    immediate_quad(pos+hs, hs, ca)

    immediate_quad(pos, size, color)
    c := color
    c.a = 1.0
    immediate_quad(pos+hs*0.5, hs, c)
}