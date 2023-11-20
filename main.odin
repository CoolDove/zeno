package main

// import rl "vendor:raylib"
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

app_time : f64
delta_time : f64

tweener : Tweener

timer : time.Stopwatch


//# Visual
the_ypos :f32

app : Application

main :: proc() {
    application_init(&app)
    defer application_release(&app)
    using app

    victor_regular := nvg.CreateFont(vg, "victor-regular", "./victor-regular.ttf")
    unifont := nvg.CreateFont(vg, "unifont", "./unifont.ttf")
    nvg.AddFallbackFontId(vg, victor_regular, unifont)

    pic := nvg.CreateImage(vg, "./p1113.png", nvg.ImageFlags{.REPEAT_X, .REPEAT_Y})
    defer nvg.DeleteImage(vg, pic)

    time.stopwatch_start(&timer)
    tween_system_init()
    tweener_init(&tweener, 16); defer tweener_release(&tweener)

    quit : bool
    event : sdl.Event
    for !quit {
        if sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT: 
                quit=true
                continue
            case .KEYDOWN:   
                fmt.printf("key down: {}\n", event.key.keysym)
                if event.key.keysym.sym == .j {
                    cursor = math.min(cursor + 1, len(records)-1)
                    tween(&tweener, &the_ypos, auto_cast (30+cursor*34), 0.12)->set_easing(ease_outcirc)
                } else if event.key.keysym.sym == .k {
                    cursor = math.max(cursor - 1, 0)
                    tween(&tweener, &the_ypos, auto_cast (30+cursor*34), 0.12)->set_easing(ease_outcirc)
                } else if event.key.keysym.sym == .a {
                    append(&records, Record{fmt.caprintf("Hello, Dove! -{}", len(records))})
                }
                redraw_flag = true
            }
        }

        if time.duration_seconds(time.stopwatch_duration(timer)) >= 0.016 {
            if tweener_count(&tweener) > 0 {
                redraw_flag = true
            }
            tweener_update(&tweener, 0.016)
            time.stopwatch_reset(&timer)
            time.stopwatch_start(&timer)
        }

        if redraw_flag {
            @static frame_id : i64 = 0
            gl.Clear(gl.COLOR_BUFFER_BIT)
            w,h : c.int
            sdl.GetWindowSize(wnd, &w,&h)
            nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
            nvg.Save(vg)
            
            nvg.BeginPath(vg)
            nvg.Circle(vg, 150,150, 300)
            nvg.FillPaint(vg, nvg.ImagePattern(0,0, 600, 200, 0, pic, 1.0))
            nvg.Fill(vg)

            draw(vg, &pic)

            nvg.BeginPath(vg)
            nvg.FillColor(vg, {.8,.6,0,0.9})
            nvg.FontSize(vg, 24)
            nvg.Text(vg, 5,25, fmt.tprintf("FID: {}", frame_id))
            
            nvg.Restore(vg)
            nvg.EndFrame(vg)
            redraw_flag = false
            sdl.GL_SwapWindow(wnd)

            frame_id += 1
        }
    }
}

draw :: proc(vg : ^nvg.Context, bg: ^int) {
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