package main

// import rl "vendor:raylib"
import sdl "vendor:sdl2"
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
    wnd := sdl.CreateWindow("topo", 60,10, 600,800, sdl.WindowFlags{.RESIZABLE})
    renderer := sdl.CreateRenderer(wnd, -1, sdl.RENDERER_ACCELERATED)

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
        sdl.SetRenderDrawColor(renderer, 200, 20,20, 255)
        sdl.RenderClear(renderer)
        draw(renderer)

        sdl.RenderPresent(renderer)
    }

    sdl.DestroyWindow(wnd)
    sdl.Quit()
}

draw :: proc(renderer: ^sdl.Renderer) {
    xpos :c.int= 10
    ypos :c.int= 30
    font_size :c.int= 24
    line_height :c.int= 30

    rect : sdl.Rect
    rect.x = xpos
    rect.y = ypos
    rect.w = 60
    rect.h = 24
    for &r, idx in records {
        rect.y = ypos
        if cursor != idx {
            sdl.SetRenderDrawColor(renderer, 198, 240, 20, 200)
            sdl.RenderDrawRect(renderer, &rect)
        } else {
            sdl.SetRenderDrawColor(renderer, 10, 20, 128, 200)
            sdl.RenderDrawRect(renderer, &rect)
        }
        ypos += line_height
    }
}