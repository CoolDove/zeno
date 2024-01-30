package main

import "core:log"


tool_brush := ZenoTool{
	name = "Brush",
	vtable = ZenoTool_VTable {_brush_init, _brush_release, _brush_handler},
}

@(private="file")
_brush_handler :: proc(tool: ^ZenoTool, event: ZenoToolEvent) {
	switch e in event {
	case ZenoToolEventPointer:
		switch pe in e.event {
		case PointerInputEventPrimary:
			using app
			if pe.begin {
				paintcurve_clear(&paintcurve)
				paintcurve_append(&paintcurve, canvas->wnd2cvs(pe.position), pe.pressure)
				paint_begin(&canvas, &canvas.layers[canvas.current_layer])
			} else {
				using app
				if paint_is_painting() {
					paintcurve_append(&paintcurve, canvas->wnd2cvs(pe.position), pe.pressure)
					paint_end()
				}
			}
		case PointerInputEventButton:
		case PointerInputEventMotion:
			using app
			if paint_is_painting() {
				paintcurve_append(&app.paintcurve, canvas->wnd2cvs(pe.position), pe.pressure)

				length := paintcurve_length(&app.paintcurve)
				for paintcurve_step(&app.paintcurve, 0.1 * cast(f32)app.brush_size) {
					p,_ := paintcurve_get(&app.paintcurve)
					paint_push_dap({p.position, p.angle, p.pressure * auto_cast app.brush_size})
				}
				nodelay_flag = true
			}
		}
	case ZenoToolEventStateChange:
	}
}
@(private="file")
_brush_init :: proc(tool: ^ZenoTool) {
	log.debugf("Tool initialized: brush")
}
@(private="file")
_brush_release :: proc(tool: ^ZenoTool) {
	log.debugf("Tool released: brush")
}
