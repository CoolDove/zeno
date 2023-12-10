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
        canvas.compose.compose_brush)
    // immediate_texture(
    //     {10+150+10, app.window_size.y - 210},
    //     Vec2{150, 200}, 
    //     {1,1,1,1}, 
    //     canvas.texid)
    // immediate_texture(
    //     {10+150+10+150+20, app.window_size.y - 210},
    //     Vec2{150, 200}, 
    //     {1,1,1,1}, 
    //     _paint.brush_texture_left)
    // immediate_texture(
    //     {10+150+10+150+20+150+10, app.window_size.y - 210},
    //     Vec2{150, 200}, 
    //     {1,1,1,1}, 
    //     _paint.brush_texture_right)
}

debug_draw_immediate_layers :: proc(vg : ^nvg.Context, canvas: ^Canvas, rect: Vec4) {
    cw,ch :f32= auto_cast canvas.width, auto_cast canvas.height
    x,y := rect.x,rect.y
    w,h := rect.z,rect.w

    unit_h :f32= 60.0
    preview_w :f32= unit_h
    preview_h :f32= unit_h
    if canvas.height > canvas.width do preview_w = (cw/ch) * preview_h
    else do preview_h = (ch/cw) * preview_w

    #reverse for l,idx in canvas.layers {
        pdh :f32= 3 //padding half
        is_current := idx == auto_cast canvas.current_layer
        immediate_quad({ x-pdh, y-pdh }, { w+2*pdh, unit_h+2*pdh }, {1,1,1,1} if is_current else {.4,.4,.4,1})
        immediate_texture({x,y}, {preview_w,preview_h}, {1,1,1,1}, l.tex)
        y += unit_h + 8.0
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

debug_draw_vg_informations :: proc(vg : ^nvg.Context, canvas: ^Canvas) {
    nvg.FontSize(vg, 24)
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

debug_draw_vg_dirty_rect :: proc(vg: ^nvg.Context, color: Vec4) {

    if !paint_is_painting() do return

    r := _paint.dirty_rect
    c := _paint.canvas

    _debug_draw_canvas_rect(vg, c, r.x,r.y, r.z,r.w, color)
    // color :Vec4= {1,0,0,1}
    // x,y := r.x,r.y
    // w,h := r.z,r.w
    // point_on_canvas(vg, c, {x,y}, 5, color)
    // point_on_canvas(vg, c, {x+w,y}, 5, color)
    // point_on_canvas(vg, c, {x,y+h}, 5, color)
    // point_on_canvas(vg, c, {x+w,y+h}, 5, color)
}

point_on_canvas :: proc(vg: ^nvg.Context, c: ^Canvas, pos: Vec2, r: f32, color: Vec4) {
    pos := c->cvs2wnd(pos)
    nvg.BeginPath(vg)
    nvg.Circle(vg, pos.x,pos.y, r)
    nvg.FillColor(vg, auto_cast color)
    nvg.Fill(vg)
}


_debug_draw_canvas_rect :: proc(vg: ^nvg.Context, c: ^Canvas, x,y,w,h: f32, color: Vec4) {
    min :Vec2= {x, y}
    max :Vec2= min+{w,h}

    pa := min
    pb :Vec2= {x+w,y}
    pc := max
    pd :Vec2= {x,y+h}

    pa = c->cvs2wnd(pa)
    pb = c->cvs2wnd(pb)
    pc = c->cvs2wnd(pc)
    pd = c->cvs2wnd(pd)

    if pb.x-pa.x > 5 && pc.y-pa.y > 5 {
        nvg.BeginPath(vg)
        nvg.MoveTo(vg, pa.x,pa.y)
        nvg.LineTo(vg, pb.x,pb.y)
        nvg.LineTo(vg, pc.x,pc.y)
        nvg.LineTo(vg, pd.x,pd.y)
        nvg.LineTo(vg, pa.x,pa.y)
        nvg.StrokeColor(vg, auto_cast color)
        nvg.Stroke(vg)
    }
}