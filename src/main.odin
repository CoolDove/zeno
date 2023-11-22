package main

import nvg "vendor:nanovg"
import fts "vendor:fontstash"
import nvggl "vendor:nanovg/gl"
import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import "core:strings"
import "core:c"
import "core:math"
import "core:fmt"
import "core:time"

Record :: struct {
    text : cstring,
}

records : [dynamic]Record

cursor : int
edit_mode : bool

redraw_flag : bool = true

delta_time : f64

timer : time.Stopwatch


//# Visual
the_ypos :f32

app : Application

main :: proc() {
    application_init(&app)
    defer application_release(&app)
    using app

    pic := nvg.CreateImage(vg, "./p1113.png", nvg.ImageFlags{.REPEAT_X, .REPEAT_Y})
    defer nvg.DeleteImage(vg, pic)

    // canvas_init(&app.canvas, 20,20, Color32{200, 80, 10, 255})
    canvas_init(&app.canvas, "./p1113.png")
    defer canvas_release(&app.canvas)

    immediate_init(); defer immediate_release()

    quit : bool
    event : sdl.Event
    for !quit {
        // state machine
        @static dragging := false

        if sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT: 
                quit=true
                continue
            case .WINDOWEVENT:
                redraw_flag = true
                // TODO: in resize event
                w,h : c.int
                sdl.GetWindowSize(wnd, &w,&h)
                app.window_size.x = auto_cast w
                app.window_size.y = auto_cast h
            case .KEYDOWN:   
                if event.key.keysym.sym == .j {
                    cursor = math.min(cursor + 1, len(records)-1)
                    tween(&tweener, &the_ypos, auto_cast (30+cursor*34), 0.12)->set_easing(ease_outcirc)
                } else if event.key.keysym.sym == .k {
                    cursor = math.max(cursor - 1, 0)
                    tween(&tweener, &the_ypos, auto_cast (30+cursor*34), 0.12)->set_easing(ease_outcirc)
                } else if event.key.keysym.sym == .a {
                    append(&records, Record{fmt.caprintf("Hello, Dove! 你好鸽子 -{}", len(records))})
                }
                redraw_flag = true
            case .MOUSEWHEEL:
                if (sdl.GetModState() & sdl.KMOD_LSHIFT) == {} {
                    x,y : c.int
                    sdl.GetMouseState(&x,&y)
                    scale_before := canvas.scale
                    canvas.scale = math.clamp(canvas.scale + 0.1 * cast(f32)event.wheel.y * canvas.scale, 0.01, 5.0)
                    mpos := Vec2{auto_cast x,auto_cast y}
                    dir := mpos - canvas.offset
                    to := (canvas.scale/scale_before) * dir
                    canvas.offset += to
                } else {
                    app.brush_size = math.clamp(event.wheel.y * 2 + app.brush_size, 1, 500)
                }
                redraw_flag = true
            case .MOUSEBUTTONDOWN:
                if event.button.button == sdl.BUTTON_RIGHT {
                    dragging = true
                    cursor_set(.Dragger)
                }
            case .MOUSEBUTTONUP:
                if event.button.button == sdl.BUTTON_RIGHT {
                    dragging = false
                    cursor_set(.Default)
                }
            case .MOUSEMOTION:
                if dragging {
                    relative :Vec2i= {event.motion.xrel, event.motion.yrel}
                    app.canvas.offset += vec_i2f(relative)
                }
                redraw_flag = true
            }
        }

        if redraw_flag {
            gl.ClearColor(0.2,0.2,0.2,1.0)
            gl.Clear(gl.COLOR_BUFFER_BIT)
            gl.Viewport(0,0,auto_cast app.window_size.x,auto_cast app.window_size.y)
            draw(vg)
            redraw_flag = false
            app.frame_id += 1
            sdl.GL_SwapWindow(wnd)
        }

        {// Update control
            update_ms := time.duration_milliseconds(time.stopwatch_duration(app.timer))
            FPS := 60
            delay :int= 1000/FPS - auto_cast update_ms
            if delay >= 0 {
                sdl.Delay(cast(u32)delay)
            }
            if tweener_count(&tweener) > 0 {
                redraw_flag = true
            }
            tweener_update(&tweener, 1000.0/cast(f32)FPS)
            time.stopwatch_reset(&timer)
        }
    }
}

draw :: proc(vg : ^nvg.Context) {
    canvas := &app.canvas
    w, h := app.window_size.x,app.window_size.y
    immediate_begin({0,0, auto_cast w, auto_cast h})
    {
        pos := canvas->cvs2wnd({0,0})
        cw := cast(f32)canvas.width*canvas.scale
        ch := cast(f32)canvas.height*canvas.scale
        immediate_quad(
            pos+{5,5},// {x,y}+canvas.offset+{5,5},
            Vec2{cw, ch}, 
            {0.1,0.1,0.1,0.9})
        immediate_texture(
            pos,//{x,y}+canvas.offset,
            Vec2{cw, ch}, 
            {1,1,1,1}, 
            canvas.texid)
    }
    immediate_end()
    
    nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
    nvg.Save(vg)
    
    draw_nvg_records(vg)
    draw_nvg_cursor(vg)

    nvg.BeginPath(vg)
    nvg.FontSize(vg, 24)

    _textline :: proc(vg: ^nvg.Context, x:f32, y: ^f32, msg: string) {
        nvg.FillColor(vg, {0,0,0,.8})
        nvg.Text(vg, x+1.5, y^+1.5, msg)
        nvg.FillColor(vg, {.2,.8,.1,1.0})
        nvg.Text(vg, x, y^, msg)
        y^ = y^+30
    }
    {
        y :f32= 25
        _textline(vg, 5, &y, fmt.tprintf("FID: {}", app.frame_id))
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
    }
    
    nvg.Restore(vg)
    nvg.EndFrame(vg)
}

draw_nvg_records :: proc(vg : ^nvg.Context) {
    xpos :c.int= 10
    ypos :c.int= 30
    font_size :c.int= 24
    line_height :c.int= 34

    nvg.FontSize(vg, 28)
    for &r, idx in records {
        if cursor != idx {
            gray :f32= 0.8
            nvg.FillColor(vg, {0.2,0.2,0.2,1.0})
            nvg.Text(vg, auto_cast xpos+1, auto_cast ypos+2, auto_cast r.text)
            nvg.FillColor(vg, {gray,gray,gray,1.0})
            nvg.Text(vg, auto_cast xpos, auto_cast ypos, auto_cast r.text)
        } else {
            advance := nvg.TextBounds(vg, auto_cast xpos+1, auto_cast ypos+1, auto_cast r.text)
            {
                nvg.BeginPath(vg)
                nvg.FillColor(vg, {0.4,0.2,1.0,1.0})
                nvg.RoundedRect(vg, auto_cast xpos-5, auto_cast the_ypos-24, advance+10, 30, 4.0)
                nvg.Fill(vg)
            }
            nvg.FillColor(vg, {0.0,1.0,0.3,1.0})
            nvg.Text(vg, auto_cast xpos, auto_cast ypos, auto_cast r.text)
        }
        ypos += line_height
    }

    nvg.BeginPath(vg)
}

draw_nvg_cursor :: proc(vg: ^nvg.Context) {
    x,y : c.int
    mouse_buttons := sdl.GetMouseState(&x,&y)

    nvg.BeginPath(vg)
    nvg.StrokeWidth(vg, 1)
    nvg.StrokeColor(vg, {0,0,0,1})
    nvg.Circle(vg, auto_cast x, auto_cast y, cast(f32)app.brush_size * app.canvas.scale)
    nvg.Stroke(vg)
}