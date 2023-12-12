package main

import nvg "vendor:nanovg"
import sdl "vendor:sdl2"


ControlState :: enum {
    Default, DebugConfig,
}



@(private="file")
_state : ControlState
@(private="file")
_info : string

control_state_machine_input :: proc(key: sdl.Keysym) {
    switch _state {
    case .Default:
        #partial switch key.sym {
        case .D:
            _state = .DebugConfig
            _info_debug_config()
        }
    case .DebugConfig:
        using app.debug_config
        #partial switch key.sym {
        case .ESCAPE:
            _set_default()
        case .R:
            dirty_region = !dirty_region
            _set_default()
        case .I:
            basic_info = !basic_info
            _set_default()
        case .B:
            brush_buffer = !brush_buffer
            _set_default()
        case .P:
            if paint_history <= 0 do paint_history = 10
            else do paint_history = 0
            _set_default()
        case:
            _state = .Default
            _info_default()
        }
    }
}

control_vg_draw_commands :: proc(vg: ^nvg.Context, pos: Vec2) {
    nvg.BeginPath(vg)
    nvg.FontSize(vg, 26)
    nvg.FillColor(vg, {0,0,0,.8})
    nvg.TextBox(vg, pos.x+1.2, pos.y+1.2, 500, _info)
    nvg.FillColor(vg, {.2,.8,.1,1.0})
    nvg.TextBox(vg, pos.x, pos.y, 500, _info)
}

@(private="file")
_info_debug_config :: proc() {
    _info = 
`
r: dirty region
i: basic info
b: brush buffer
p: paint history
`
}
@(private="file")
_info_default :: proc() {
    _info = ""
}

@(private="file")
_set_default :: proc() {
    _state = .DebugConfig
    _info_default()
}