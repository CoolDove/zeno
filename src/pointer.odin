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

post_pointer_event :: proc(input: ^PointerInput, event: PointerInputEvent) {
	switch e in event {
	case PointerInputEventPrimary:
		input.position = e.position
		input.pressure = e.pressure
		if !e.begin do input.pressure = 0
	case PointerInputEventButton:
		if e.button == .Middle do input.btn_middle = e.press_down
		if e.button == .Right do input.btn_right = e.press_down
	case PointerInputEventMotion:
		input.position = e.position
		input.pressure = e.pressure
	}
	post_tool_event(ZenoToolEventPointer{input, event})
}
