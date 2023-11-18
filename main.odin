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

Record :: struct {
    text : cstring,
}

records : [dynamic]Record

cursor : int
edit_mode : bool

main :: proc() {
    sdl.Init(sdl.INIT_VIDEO)
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3);
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3);
    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, auto_cast sdl.GLprofile.COMPATIBILITY);
    wnd := sdl.CreateWindow("topo", 60,10, 600,800, sdl.WindowFlags{.RESIZABLE, .OPENGL})

    gl_context := sdl.GL_CreateContext(wnd)
    assert(gl_context != nil, fmt.tprintf("Failed to create GLContext for window, because: {}.\n", sdl.GetError()))

    sdl.GL_MakeCurrent(wnd, gl_context)
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    vg := nvggl.Create(nvggl.CreateFlags{.ANTI_ALIAS, .STENCIL_STROKES, .DEBUG})
    defer nvggl.Destroy(vg)

    victor_regular := nvg.CreateFont(vg, "victor-regular", "./victor-regular.ttf")
    unifont := nvg.CreateFont(vg, "unifont", "./unifont.ttf")
    nvg.AddFallbackFontId(vg, victor_regular, unifont)

    quit : bool
    event : sdl.Event
    for !quit {
        if sdl.WaitEvent(&event) {
            #partial switch event.type {
            case .QUIT: 
                quit=true
                continue
            case .KEYDOWN:   
                fmt.printf("key down: {}\n", event.key.keysym)
                if event.key.keysym.sym == .j {
                    cursor = math.min(cursor + 1, len(records)-1)
                } else if event.key.keysym.sym == .k {
                    cursor = math.max(cursor - 1, 0)
                } else if event.key.keysym.sym == .a {
                    append(&records, Record{fmt.caprintf("Hello, Dove! -{}", len(records))})
                }
            }
        }
        
        gl.Clear(gl.COLOR_BUFFER_BIT)
        w,h : c.int
        sdl.GetWindowSize(wnd, &w,&h)
        nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
        nvg.Save(vg)

        draw(vg)

        // nvg.FillColor(vg, {.2,.8,.2, 1.0})

        nvg.Restore(vg)
        nvg.EndFrame(vg)
        sdl.GL_SwapWindow(wnd)
    }

    sdl.DestroyWindow(wnd)
    sdl.Quit()
}

draw :: proc(vg : ^nvg.Context) {
    xpos :c.int= 10
    ypos :c.int= 30
    font_size :c.int= 24
    line_height :c.int= 34

    nvg.FontSize(vg, 28)
    for &r, idx in records {
        if cursor != idx {
            nvg.FillColor(vg, {0.8,0.8,0.8,1.0})
            nvg.Text(vg, auto_cast xpos, auto_cast ypos, auto_cast r.text)
        } else {
            {
                nvg.BeginPath(vg)
                nvg.FillColor(vg, {0.4,0.4,0.4,1.0})
                nvg.Rect(vg, auto_cast (xpos-5), auto_cast (ypos)-24, 300, 30)
                nvg.Fill(vg)
            }
            nvg.FillColor(vg, {0.9,0.1,1.0,1.0})
            nvg.Text(vg, auto_cast xpos+1, auto_cast ypos+1, auto_cast r.text)
            nvg.FillColor(vg, {1.0,1.0,1.0,1.0})
            length := nvg.Text(vg, auto_cast xpos, auto_cast ypos, auto_cast r.text)

        }
        ypos += line_height
    }
}