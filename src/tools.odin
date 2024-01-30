package main

import "core:log"

ZenoTool :: struct {
	using vtable : ZenoTool_VTable,
	name : string,
	data : rawptr,
}

// `init` is called when this tool is registered to the application.
// `release` is called when this application releases.
ZenoTool_VTable :: struct {
	init, release : proc(tool: ^ZenoTool),
	handler : proc(tool: ^ZenoTool, event: ZenoToolEvent),
}

ZenoToolEvent :: union {
	ZenoToolEventStateChange,
	ZenoToolEventPointer,
}

ZenoToolEventStateChange :: enum {
	Enter, // When this tool is activated.
	Exit, // When this tool is deactivated.
	CanvasChange, // When you switch canvas with this tool choosing.
}
ZenoToolEventPointer :: struct {
	input : ^PointerInput,
	event : PointerInputEvent,
}

register_tool :: proc(tool: ^ZenoTool) {
	append(&app.tools, tool)
	tool->init()
}
select_tool :: proc(tool: ^ZenoTool) {
	if app.tool != nil do post_tool_event(ZenoToolEventStateChange.Exit)
	if tool != nil {
		app.tool = tool
		post_tool_event(ZenoToolEventStateChange.Enter)
		log.debugf("Select tool: {}", tool.name)
	}
}

post_tool_event :: proc(event: ZenoToolEvent) {
	if app.tool != nil {
		app.tool->handler(event)
	} else {
		log.warnf("No tool selected to handled event: {}.", event)
	}
}
