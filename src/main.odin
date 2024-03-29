package main

import nvg "vendor:nanovg"
import fts "vendor:fontstash"
import nvggl "vendor:nanovg/gl"
import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import "core:strings"
import "core:c"
import "core:c/libc"
import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:log"
import "core:runtime"
import "core:time"
import win32 "core:sys/windows"

import "easytab"
import "dgl"

Record :: struct {
    text : cstring,
}

FPS :: 60

redraw_flag : bool = true
nodelay_flag : bool = false // If this is true, skip the sync delay for this frame.

timer : time.Stopwatch

app : Application

main :: proc() {
    context.logger = log.create_console_logger(); defer log.destroy_console_logger(context.logger)

    application_init(&app)
    defer application_release(&app)
    using app

	// Debug info default
	app.debug_config.basic_info = true


	// Register tools
	register_tool(&tool_brush)
	register_tool(&tool_color_picker)

	select_tool(&tool_color_picker)

    pic := nvg.CreateImage(vg, "./p1113.png", nvg.ImageFlags{.REPEAT_X, .REPEAT_Y})
    defer nvg.DeleteImage(vg, pic)

    // canvas_init(&app.canvas, 20,20, Color32{200, 80, 10, 255})

    canvas_init(&app.canvas, "./p1113.png")
    defer canvas_release(&app.canvas)

    immediate_init(); defer immediate_release()

    quit : bool
    event : sdl.Event
    for !quit {
        // states
        @static dragging := false
        @static adjusting_brush_size := false
        @static adjusting_brush_size_pin : Vec2

        if sdl.PollEvent(&event) {
			// FIXME: Handling tablet check is not correct.
			handling_easytab := app.tablet_info.dirty || auto_cast (app.tablet_info.eztab.Buttons & auto_cast easytab.Buttons.PenTouch)// If true, overlap PointerInputEvent Primary and Motion.
			app.tablet_info.dirty = false
			app.tablet_info.tablet_working = true // handling_easytab && app.pointer_input.pressure > 0

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
                on_key(event.key.keysym)
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
                if event.button.button == sdl.BUTTON_MIDDLE {
					post_pointer_event(&pointer_input, PointerInputEventButton{.Middle, true})
                    // dragging = true
                    // cursor_set(.Dragger)
                } else if event.button.button == sdl.BUTTON_RIGHT {
					post_pointer_event(&pointer_input, PointerInputEventButton{.Right, true})
				} else if !handling_easytab && event.button.button == sdl.BUTTON_LEFT {
					post_pointer_event(&pointer_input, PointerInputEventPrimary{app.mouse_pos, 1.0, true})

                    // if sdl.KeymodFlag.LSHIFT in sdl.GetModState() {
                        // adjusting_brush_size = true
                        // adjusting_brush_size_pin = app.mouse_pos
                    // } else {
                        // // The paint
						// pointer_down(app.mouse_pos, 1.0)
						// nodelay_flag = true
                    // }
                }
            case .MOUSEBUTTONUP:
                _app_update_mouse_position()
                if event.button.button == sdl.BUTTON_MIDDLE {
					post_pointer_event(&pointer_input, PointerInputEventButton{.Middle, false})
                    // dragging = false
                    // cursor_set(.Default)
                } else if event.button.button == sdl.BUTTON_RIGHT {
					post_pointer_event(&pointer_input, PointerInputEventButton{.Right, false})
				} else if !handling_easytab && event.button.button == sdl.BUTTON_LEFT {
					post_pointer_event(&pointer_input, PointerInputEventPrimary{app.mouse_pos, 1.0, false})
                    // if adjusting_brush_size {
                        // adjusting_brush_size = false
                    // } else if paint_is_painting() {
						// pointer_up(app.mouse_pos, 1.0)
                    // }
                }
            case .MOUSEMOTION:
                _app_update_mouse_position()
				if !handling_easytab {
					sdl_mouse_state := sdl.GetMouseState(nil, nil)
					mouse_left_pressing :bool= auto_cast (sdl_mouse_state & transmute(u32)sdl.BUTTON(sdl.BUTTON_LEFT))
					post_pointer_event(&pointer_input, PointerInputEventMotion{app.mouse_pos, 1.0 if mouse_left_pressing else 0.0})

					app.tablet_info.tablet_working = false
					// if dragging {
						// relative :Vec2i= {event.motion.xrel, event.motion.yrel}
						// app.canvas.offset += vec_i2f(relative)
					// } else if adjusting_brush_size {
						// app.brush_size = auto_cast math.max(1, linalg.distance(app.mouse_pos, adjusting_brush_size_pin)/canvas.scale)
					// } else if paint_is_painting() {
						// pointer_update(app.mouse_pos, 1.0)
// 
						// length := paintcurve_length(&app.paintcurve)
						// for paintcurve_step(&app.paintcurve, 0.1 * cast(f32)app.brush_size) {
							// p,_ := paintcurve_get(&app.paintcurve)
							// paint_push_dap({p.position, p.angle, p.pressure * auto_cast app.brush_size})
						// }
						// nodelay_flag = true
					// }
				}
                redraw_flag = true
            }
        }

        if paint_remained() > 0 do redraw_flag = true

        if redraw_flag {
            /* Flush painting daps */
            profile_begin("Paint")
            paint_draw(-1)
			canvas_compose_mark_dirty(&canvas)
            profile_end()
            
            dgl.framebuffer_bind_default()
            gl.ClearColor(0.2,0.2,0.2,1.0)
            gl.Clear(gl.COLOR_BUFFER_BIT)
            gl.Viewport(0,0,auto_cast app.window_size.x,auto_cast app.window_size.y)
            dgl.framebuffer_bind_default()
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

native_wnd_msg_handler :: proc "c" (userdata: rawptr, hWnd: rawptr, message: c.uint, wParam: u64, lParam: i64) {
	context = runtime.default_context()

	before := easytab.EasyTab^
	result := easytab.HandleEvent(
		transmute(win32.HWND)app.sys_wm_info.info.win.window, message,
		transmute(win32.LPARAM)lParam,
		transmute(win32.WPARAM)wParam)
	if result == .Ok {
		using easytab.EasyTab
		redraw_flag = true
		
		// ## Handling easytab
		using app

		touch_old :bool= auto_cast (before.Buttons & transmute(i32)easytab.Buttons.PenTouch)
		touch_now :bool= auto_cast (Buttons & transmute(i32)easytab.Buttons.PenTouch)

		if !touch_old && touch_now {
			post_pointer_event(&pointer_input, PointerInputEventPrimary{vec_i2f(Vec2i{PosX,PosY}), Pressure, true})
		} else if !touch_now && touch_old {
			post_pointer_event(&pointer_input, PointerInputEventPrimary{vec_i2f(Vec2i{PosX,PosY}), Pressure, false})
		}

		if before.Pressure != Pressure || before.PosX != PosX || before.PosY != PosY {
			post_pointer_event(&pointer_input, PointerInputEventMotion{vec_i2f(Vec2i{PosX,PosY}), Pressure})
		}

		app.tablet_info.dirty = true
		app.tablet_info.eztab = before
		app.tablet_info.eztab = easytab.EasyTab^
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

    profile_begin("Compose")
    canvas_compose_all(canvas)
    profile_end()

    profile_begin("DrawCanvas")
    dgl.framebuffer_bind_default()
    immediate_begin({0,0, auto_cast w, auto_cast h})
    {
        pos := canvas->cvs2wnd({0,0})
        cw := cast(f32)canvas.width*canvas.scale
        ch := cast(f32)canvas.height*canvas.scale
        immediate_quad(// Shadow
            pos+{5,5},
            Vec2{cw, ch}, 
            {0.1,0.1,0.1,0.9})
        immediate_texture(
            pos,
            Vec2{cw,ch},
            {1,1,1,1},
            canvas.compose.compose_result)
        if app.debug_config.brush_buffer do  debug_draw_immediate_brush_buffers(canvas)

        debug_draw_immediate_layers(canvas, {app.window_size.x - 110, 10, 100, app.window_size.y})
        if app.debug_config.paint_history > 0 do debug_draw_immediate_history_buffers(&canvas.history, {100, app.window_size.y}, app.debug_config.paint_history)

        debug_draw_color_preview_quad({20, app.window_size.y-60}, {40,40}, app.brush_color)
    }
    immediate_end()
    profile_end()
    
    nvg.BeginFrame(vg, auto_cast w,auto_cast h, 1.0)
    nvg.Save(vg)


    draw_nvg_cursor(vg)

    if app.debug_config.dirty_region do debug_draw_vg_dirty_rect(vg, {1,0,0,1})

    if app.debug_config.basic_info do debug_draw_vg_informations(vg, canvas)

    control_vg_draw_commands(vg, {app.window_size.x-300,50})
    
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

on_key :: proc(key : sdl.Keysym) {
    if key.sym == .c {
        if sdl.KeymodFlag.LSHIFT in key.mod {
            color_switch(true)
        } else {
            color_switch(false)
        }
    } else if key.sym == .n {
        canvas_add_layer(&app.canvas, layer_create_with_color(app.canvas.width, app.canvas.height, {255,255,255,0}))
    } else if key.sym == .j {
        if !paint_is_painting() {
            app.canvas.current_layer = 
                math.clamp(app.canvas.current_layer-1, 0, cast(i32)len(app.canvas.layers)-1)
        }
    } else if key.sym == .k {
        if !paint_is_painting() {
            app.canvas.current_layer = 
                math.clamp(app.canvas.current_layer+1, 0, cast(i32)len(app.canvas.layers)-1)
        }
    } else if key.sym == .z {
        if !paint_is_painting() {
            history_undo(&app.canvas.history)
        }
    } else if key.sym == .y {
        history_redo(&app.canvas.history)
    } else if key.sym == .b {
		select_tool(&tool_brush)
	} else if key.sym == .s {
		select_tool(&tool_color_picker)
	}
    control_state_machine_input(key)
}

color_switch :: proc(alpha: bool) {
    @static color := [6]Vec4 {
        {1,0,0,1},
        {0,1,0,1},
        {.1,.4,.8,1},
        {.9,0.8,0,1},
        {0,0,0,1},
        {1,1,1,1},
    }
    @static current := 0
    if alpha {
        app.brush_color.a = app.brush_color.a + 0.25
        if app.brush_color.a > 1 do app.brush_color.a -= 1
    } else {
        a := app.brush_color.a
        current = (current + 1) % len(color)
        app.brush_color = color[current]
        app.brush_color.a = a
    }
}
