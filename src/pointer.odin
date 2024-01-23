package main

import win32 "core:sys/windows"
import "core:c/libc"
import "core:log"

import "easytab"

PointerButton :: enum {
	Middle, Right,
}

PointerInput :: struct {
	position : Vec2, // position in the window
	pressure : f32,
	btn_middle, btn_right : bool,
}

PointerInputEvent :: union {
	PointerInputEventPrimary,
	PointerInputEventButton,
	PointerInputEventMotion,
}

PointerInputEventPrimary :: struct {
	position : Vec2,
	pressure : f32,
	begin : bool, // true: begin, false: end
}
PointerInputEventButton :: struct {
	button : PointerButton,
	press_down : bool, // true: press, false: release
}
PointerInputEventMotion :: struct {
	position : Vec2,
	pressure : f32,
}

pointer_event :: proc(input: ^PointerInput, event: PointerInputEvent) {
	switch e in event {
	case PointerInputEventPrimary:
		// log.debugf("pointer: {} [{}], {}", e.position, e.pressure, "Begin" if e.begin else "End")
		input.position = e.position
		input.pressure = e.pressure
		if !e.begin do input.pressure = 0

		using app
		if e.begin {
			paintcurve_clear(&paintcurve)
			paintcurve_append(&paintcurve, canvas->wnd2cvs(input.position), input.pressure)
			paint_begin(&canvas, &canvas.layers[canvas.current_layer])
		} else {
			using app
			if paint_is_painting() {
				paintcurve_append(&paintcurve, canvas->wnd2cvs(input.position), input.pressure)
				paint_end()
			}
		}
	case PointerInputEventButton:
		// log.debugf("pointer button: {} {}", e.button, "Down" if e.press_down else "Up")
		if e.button == .Middle do input.btn_middle = e.press_down
		if e.button == .Right do input.btn_right = e.press_down
	case PointerInputEventMotion:
		// log.debugf("pointer motion: {} - [{}]", e.position, e.pressure)
		input.position = e.position
		input.pressure = e.pressure

		using app
		if paint_is_painting() {
			paintcurve_append(&app.paintcurve, canvas->wnd2cvs(input.position), input.pressure)

			length := paintcurve_length(&app.paintcurve)
			for paintcurve_step(&app.paintcurve, 0.1 * cast(f32)app.brush_size) {
				p,_ := paintcurve_get(&app.paintcurve)
				paint_push_dap({p.position, p.angle, p.pressure * auto_cast app.brush_size})
			}
			nodelay_flag = true
		}
	}
}

// pointer_down :: proc (position: Vec2, pressure: f32) {
	// using app
    // paintcurve_clear(&paintcurve)
    // paintcurve_append(&paintcurve, canvas->wnd2cvs(position), pressure)
    // paint_begin(&canvas, &canvas.layers[canvas.current_layer])
// }
// 
// pointer_up :: proc (position: Vec2, pressure: f32) {
	// using app
	// paintcurve_append(&paintcurve, canvas->wnd2cvs(position), pressure)
	// paint_end()
// }
// 
// pointer_motion :: proc (position: Vec2, pressure: f32) {
	// using app
	// points := app.paintcurve.raw_points
	// last := points[len(points)-1]
// 
	// // pressure :f32= 0.0
	// // if easytab.EasyTab.Buttons & auto_cast easytab.Buttons.PenTouch != 0 {
		// // pressure = easytab.EasyTab.Pressure
	// // }
// 
	// paintcurve_append(&app.paintcurve, canvas->wnd2cvs(position), pressure)
// }
