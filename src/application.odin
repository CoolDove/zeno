package main

import "core:time"
import "core:fmt"
import "core:c"
import "core:slice"
import win32 "core:sys/windows"

import nvg "vendor:nanovg"
import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import nvggl "vendor:nanovg/gl"

import "dgl"

Application :: struct {
    using app_base : ApplicationBase,
    tweener : Tweener,
    canvas : Canvas,
    brush_size : i32,
}

ApplicationBase :: struct {
    vg : ^nvg.Context,
    wnd : ^sdl.Window,

    // This should have be Vec2i, but to reduce the cost of type casting.
    window_size : Vec2,
    frame_id : u64,
    timer : time.Stopwatch,// Frame timer

    gl_ctx : sdl.GLContext,
}

application_init :: proc(app : ^Application) {
    sdl.Init(sdl.INIT_VIDEO)
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3);
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 3);
    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, auto_cast sdl.GLprofile.COMPATIBILITY);
    app_base : ApplicationBase
    app_base.wnd = sdl.CreateWindow("zeno", 500, 30, 600,800, sdl.WindowFlags{.RESIZABLE, .OPENGL})

    app_base.gl_ctx = sdl.GL_CreateContext(app_base.wnd)
    assert(app_base.gl_ctx != nil, fmt.tprintf("Failed to create GLContext for window, because: {}.\n", sdl.GetError()))

    sdl.GL_SetSwapInterval(1)
    sdl.GL_MakeCurrent(app_base.wnd, app_base.gl_ctx)
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    vg := nvggl.Create(nvggl.CreateFlags{.ANTI_ALIAS, .STENCIL_STROKES, .DEBUG})
    victor_regular := nvg.CreateFont(vg, "victor-regular", "./res/victor-regular.ttf")
    unifont := nvg.CreateFont(vg, "unifont", "./res/unifont.ttf")
    nvg.AddFallbackFontId(vg, victor_regular, unifont)
    app_base.vg = vg

    // 
    app.app_base = app_base

    tween_system_init()
    tweener_init(&app.tweener, 4)

    time.stopwatch_start(&timer)

    app.brush_size = 5

    _cursors_init()

    cursor_set(.Default)

}

application_release :: proc(app : ^Application) {
    tweener_release(&app.tweener)
    nvggl.Destroy(app.vg)
    _cursors_release()
    sdl.DestroyWindow(app.wnd)
    sdl.Quit()
}

CursorType :: enum {
    Default, Brush, Dragger,
}

cursor_set :: proc(cursor: CursorType) {
    switch cursor {
    case .Default: fallthrough
    case .Brush:
        sdl.SetCursor(_CURSOR_BRUSH)
    case .Dragger:
        sdl.SetCursor(_CURSOR_DRAGGER)
    }
}

@(private="file")
_CURSOR_BRUSH : ^sdl.Cursor
@(private="file")
_CURSOR_DRAGGER : ^sdl.Cursor

@(private="file")
_cursors_init :: proc() {
    // _CURSOR_BRUSH = _cursor_create_brush_cross()
    _CURSOR_BRUSH = sdl.CreateSystemCursor(.CROSSHAIR)
    _CURSOR_DRAGGER = sdl.CreateSystemCursor(.HAND)
}
@(private="file")
_cursors_release :: proc() {
    sdl.FreeCursor(_CURSOR_BRUSH)
    sdl.FreeCursor(_CURSOR_DRAGGER)
}