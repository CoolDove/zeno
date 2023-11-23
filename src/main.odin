package main

import nvg "vendor:nanovg"
import fts "vendor:fontstash"
import nvggl "vendor:nanovg/gl"
import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import "core:strings"
import "core:c"
import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:time"

Record :: struct {
    text : cstring,
}

FPS :: 60

redraw_flag : bool = true
nodelay_flag : bool = false // If this is true, skip the sync delay for this frame.

timer : time.Stopwatch

app : Application

StrokePoint :: struct {
    pos : Vec2,
    scale : f32,
}
strokes : [dynamic][dynamic]StrokePoint

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

    strokes = make([dynamic][dynamic]StrokePoint); defer {
        for s in strokes do delete(s)
        delete(strokes)
    }

    quit : bool
    event : sdl.Event
    for !quit {
        // states
        @static dragging := false

        if sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT: 
                quit=true
                continue
            case .WINDOWEVENT:
                redraw_flag = true
                // TODO: only in resize event
                w,h : c.int
                sdl.GetWindowSize(wnd, &w,&h)
                app.window_size.x = auto_cast w
                app.window_size.y = auto_cast h
                if paint_is_painting() do paint_end()
            case .KEYDOWN:   
                redraw_flag = true
            case .MOUSEWHEEL:
                if (sdl.GetModState() & sdl.KMOD_LSHIFT) == {} {
                    x,y : c.int
                    sdl.GetMouseState(&x,&y)
                    mpos := Vec2{auto_cast x,auto_cast y}
                    cpos := canvas->wnd2cvs(mpos)
                    scale_before := canvas.scale
                    canvas.scale = math.clamp(canvas.scale + 0.1 * cast(f32)event.wheel.y * canvas.scale, 0.01, 5.0)
                    dir := mpos - canvas->cvs2wnd(cpos)
                    canvas.offset += dir
                } else {
                    app.brush_size = math.clamp(event.wheel.y * 2 + app.brush_size, 1, 500)
                }
                redraw_flag = true
            case .MOUSEBUTTONDOWN:
                _app_update_mouse_position()
                if event.button.button == sdl.BUTTON_RIGHT {
                    dragging = true
                    cursor_set(.Dragger)
                } else if event.button.button == sdl.BUTTON_LEFT {
                    // The paint
                    append(&strokes, make([dynamic]StrokePoint))
                    // append(&strokes[len(strokes)-1], StrokePoint{app.mouse_pos, 1.0}) // Temporary draw

                    paintcurve_clear(&paintcurve)
                    paintcurve_append(&paintcurve, canvas->wnd2cvs(app.mouse_pos), 1.0)
                    paint_begin(&canvas, nil)

                    nodelay_flag = true
                }
            case .MOUSEBUTTONUP:
                _app_update_mouse_position()
                if event.button.button == sdl.BUTTON_RIGHT {
                    dragging = false
                    cursor_set(.Default)
                } else if event.button.button == sdl.BUTTON_LEFT {
                    if paint_is_painting() do paint_end()
                }
            case .MOUSEMOTION:
                _app_update_mouse_position()
                if dragging {
                    relative :Vec2i= {event.motion.xrel, event.motion.yrel}
                    app.canvas.offset += vec_i2f(relative)
                } else if paint_is_painting() {
                    points := app.paintcurve.raw_points
                    last := points[len(points)-1]
                    smooth :f32= 0.8
                    // paintcurve_append(&app.paintcurve, linalg.lerp(last.position, canvas->wnd2cvs(app.mouse_pos), 1-smooth), 1.0)
                    paintcurve_append(&app.paintcurve, canvas->wnd2cvs(app.mouse_pos), 1.0)
                    length := paintcurve_length(&app.paintcurve)
                    for paintcurve_step(&app.paintcurve, 8.0) {
                        p,_ := paintcurve_get(&app.paintcurve)
                        paint_push_dap({p.position, 0, p.pressure})
                        append(&strokes[len(strokes)-1], StrokePoint{p.position, p.pressure * cast(f32)app.brush_size}) // Temporary draw
                    }
                    nodelay_flag = true
                }
                redraw_flag = true
            }
        }

        if redraw_flag {
            /* Flush painting daps */
            paint_draw(-1)
            
            gl.ClearColor(0.2,0.2,0.2,1.0)
            gl.Clear(gl.COLOR_BUFFER_BIT)
            gl.Viewport(0,0,auto_cast app.window_size.x,auto_cast app.window_size.y)
            draw(vg)
            redraw_flag = false
            app.frame_id += 1
            sdl.GL_SwapWindow(wnd)
        }

        {// Update control
            update_ms := cast(int)time.duration_milliseconds(time.stopwatch_duration(app.timer))
            frame_time_target :int= 1000/FPS
            if nodelay_flag {
                if update_ms > frame_time_target {
                    update(1.0/cast(f32)FPS)
                }
                nodelay_flag = false
            } else {
                delay :int= frame_time_target - update_ms
                if delay >= 0 {
                    sdl.Delay(cast(u32)delay)
                }
                update(1.0/cast(f32)FPS)
            }
        }

        profile_clear()
    }
}

update :: proc(delta: f32) {
    if tweener_count(&app.tweener) > 0 {
        redraw_flag = true
    }
    tweener_update(&app.tweener, 1.0/cast(f32)FPS)
    time.stopwatch_reset(&timer)
}

draw :: proc(vg : ^nvg.Context) {
    canvas := &app.canvas
    w, h := app.window_size.x,app.window_size.y

    profile_begin("DrawCanvas")
    immediate_begin({0,0, auto_cast w, auto_cast h})
    {
        pos := canvas->cvs2wnd({0,0})
        cw := cast(f32)canvas.width*canvas.scale
        ch := cast(f32)canvas.height*canvas.scale
        immediate_quad(
            pos+{5,5},
            Vec2{cw, ch}, 
            {0.1,0.1,0.1,0.9})
        immediate_texture(
            pos,
            Vec2{cw, ch}, 
            {1,1,1,1}, 
            canvas.texid)
    }
    immediate_end()
    profile_end()
    
    nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
    nvg.Save(vg)

    profile_begin("DrawStrokes")
    // ## Draw paint strokes
    for s in strokes {
        if len(s) < 2 do continue
        nvg.BeginPath(vg)
        nvg.LineCap(vg, .ROUND)
        nvg.LineJoin(vg, .ROUND)
        nvg.StrokeWidth(vg, s[0].scale * canvas.scale)
        nvg.StrokeColor(vg, {1, .2, .2, 0.8})
        start := canvas->cvs2wnd(s[0].pos)
        nvg.MoveTo(vg, start.x, start.y)
        for i in 1..<len(s) {
            wpos := canvas->cvs2wnd(s[i].pos)
            nvg.StrokeWidth(vg, s[i].scale * canvas.scale)
            nvg.LineTo(vg, wpos.x, wpos.y)
        }
        // FIXME: Dangerous, there might be a situation that you draw only two points, and they're
        //  close for stupid nvg to recognize them as a closed path. Then nvg would delete one point
        //  to make an `index out of range` error which is totally unnecessary.
        nvg.Stroke(vg)


        for p in s {
            nvg.BeginPath(vg)
            wpos := canvas->cvs2wnd(p.pos)
            nvg.FillColor(vg, {0.4, 1.0, 0.2, 1.0})
            nvg.Circle(vg, wpos.x, wpos.y, p.scale * canvas.scale * 0.5)
            nvg.Fill(vg)
        }
        
    }
    profile_end()
    
    draw_nvg_cursor(vg)
    
    nvg.BeginPath(vg)
    nvg.FontSize(vg, 24)

    _textline :: proc(vg: ^nvg.Context, x:f32, y: ^f32, msg: string) {
        nvg.FillColor(vg, {0,0,0,.8})
        nvg.Text(vg, x+1.2, y^+1.2, msg)
        nvg.FillColor(vg, {.2,.8,.1,1.0})
        nvg.Text(vg, x, y^, msg)
        y^ = y^+30
    }
    {
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

        profiles := profile_collect()
        y += 10
        _textline(vg, 5, &y, "profile:")
        for p in profiles {
            _textline(vg, 15, &y, fmt.tprintf("{}: {}ms", p.name, time.duration_milliseconds(p.duration)))
        }
    }
    
    nvg.Restore(vg)
    nvg.EndFrame(vg)
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