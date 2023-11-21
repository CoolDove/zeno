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

    // canvas_init(&app.canvas, 320,320, Color32{200, 80, 10, 255})
    canvas_init(&app.canvas, "./p1113.png")
    defer canvas_release(&app.canvas)

    immediate_init(); defer immediate_release()

    quit : bool
    event : sdl.Event
    for !quit {
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
                app.window_size.x = w
                app.window_size.y = h
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
            }
        }

        if redraw_flag {
            gl.Clear(gl.COLOR_BUFFER_BIT)
            gl.Viewport(0,0,app.window_size.x,app.window_size.y)
            draw(vg)
            redraw_flag = false
            app.frame_id += 1
            sdl.GL_SwapWindow(wnd)
        }

        {// Update control
            update_ms := time.duration_milliseconds(time.stopwatch_duration(app.timer))
            delay :int= 1000/60 - auto_cast update_ms
            if delay >= 0 {
                sdl.Delay(cast(u32)delay)
            }
            if tweener_count(&tweener) > 0 {
                redraw_flag = true
            }
            tweener_update(&tweener, 0.016)
            time.stopwatch_reset(&timer)
        }
    }
}

draw :: proc(vg : ^nvg.Context) {
    canvas := &app.canvas
    w, h := app.window_size.x,app.window_size.y
    immediate_begin({0,0,w,h})
    immediate_texture({10,10}, vec_i2f(Vec2i{canvas.width, canvas.height}), {1,1,1,1}, canvas.texid)
    immediate_end()
    
    nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
    nvg.Save(vg)
    
    draw_nvg_records(vg)
    // draw_canvas(vg, app.canvas, 30,30, 1.0)

    nvg.BeginPath(vg)
    nvg.FillColor(vg, {.8,.6,0,0.9})
    nvg.FontSize(vg, 24)
    nvg.Text(vg, 5,25, fmt.tprintf("FID: {}", app.frame_id))
    
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