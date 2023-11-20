package main

// import rl "vendor:raylib"
import nvg "vendor:nanovg"
import fts "vendor:fontstash"
import nvggl "vendor:nanovg/gl"
import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import sttf "vendor:sdl2/ttf"
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

main :: proc() {
    sdl.Init(sdl.INIT_VIDEO)
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3);
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3);
    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, auto_cast sdl.GLprofile.COMPATIBILITY);
    wnd := sdl.CreateWindow("topo", 500, 30, 600,800, sdl.WindowFlags{.RESIZABLE, .OPENGL})

    gl_context := sdl.GL_CreateContext(wnd)
    assert(gl_context != nil, fmt.tprintf("Failed to create GLContext for window, because: {}.\n", sdl.GetError()))

    sdl.GL_SetSwapInterval(1)
    sdl.GL_MakeCurrent(wnd, gl_context)
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    vg := nvggl.Create(nvggl.CreateFlags{.ANTI_ALIAS, .STENCIL_STROKES, .DEBUG})
    defer nvggl.Destroy(vg)

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
            gl.Clear(gl.COLOR_BUFFER_BIT)
            w,h : c.int
            sdl.GetWindowSize(wnd, &w,&h)
            nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
            nvg.Save(vg)

            draw(vg, &pic)

            nvg.Restore(vg)
            nvg.EndFrame(vg)
            redraw_flag = false
            fmt.printf("redraw\n")
            sdl.GL_SwapWindow(wnd)
        }
    }

    sdl.DestroyWindow(wnd)
    sdl.Quit()
}

draw :: proc(vg : ^nvg.Context, bg: ^int) {
    xpos :c.int= 10
    ypos :c.int= 30
    font_size :c.int= 24
    line_height :c.int= 34

    nvg.FontSize(vg, 28)
    // nvg.TextAlignHorizontal(vg, .CENTER)
    for &r, idx in records {
        if cursor != idx {
            gray :f32= 0.5
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
            nvg.FillColor(vg, {1.0,1.0,1.0,1.0})
            nvg.Text(vg, auto_cast xpos, auto_cast ypos, auto_cast r.text)
        }
        ypos += line_height
    }

    nvg.BeginPath(vg)
    
}