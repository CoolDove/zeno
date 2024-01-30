package main

import "core:os"
import "core:log"
import "core:slice"
import "core:runtime"

tool_color_picker := ZenoTool{
	name = "Color Picker",
	vtable = ZenoTool_VTable {_color_picker_init, _color_picker_release, _color_picker_handler},
}

@(private="file")
_color_picker_handler :: proc(tool: ^ZenoTool, event: ZenoToolEvent) {
	switch e in event {
	case ZenoToolEventPointer:
		switch pe in e.event {
		case PointerInputEventPrimary:
			app.brush_color = color_u2f(_color_picker_pick(pe.position))
		case PointerInputEventButton:
		case PointerInputEventMotion:
			if pe.pressure > 0.0 {
				app.brush_color = color_u2f(_color_picker_pick(pe.position))
			}
		}
	case ZenoToolEventStateChange:
	}
}

@(private="file")
_color_picker_init :: proc(tool: ^ZenoTool) {
	log.debugf("Tool initialized: color picker")
}
@(private="file")
_color_picker_release :: proc(tool: ^ZenoTool) {
	log.debugf("Tool released: color picker")
}

@(private="file")
_color_picker_pick :: proc(pos: Vec2) -> Color32 {
	buffer := canvas_get_image_buffer(&app.canvas)
	pixels := transmute([]Color32)runtime.Raw_Slice {
		data = raw_data(buffer),
		len = len(buffer)/4,
	}
	cvs := vec_f2i(app.canvas->wnd2cvs(pos))
	return pixels[cvs.x+cvs.y*app.canvas.width]
}
