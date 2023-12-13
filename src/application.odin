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
    brush_color : Vec4,
    paintcurve : PaintCurve,

    debug_config : DebugConfig,
}

ApplicationBase :: struct {
    vg : ^nvg.Context,
    wnd : ^sdl.Window,

    // This should have be Vec2i, but to reduce the cost of type casting.
    window_size : Vec2,
    mouse_pos : Vec2,

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
    app_base.wnd = sdl.CreateWindow("zeno", sdl.WINDOWPOS_CENTERED, sdl.WINDOWPOS_CENTERED, 800,600, sdl.WindowFlags{.RESIZABLE, .OPENGL})

    app_base.gl_ctx = sdl.GL_CreateContext(app_base.wnd)
    assert(app_base.gl_ctx != nil, fmt.tprintf("Failed to create GLContext for window, because: {}.\n", sdl.GetError()))

    sdl.GL_SetSwapInterval(1)
    sdl.GL_MakeCurrent(app_base.wnd, app_base.gl_ctx)
    gl.load_up_to(4, 3, sdl.gl_set_proc_address)

    dgl.init()

    vg := nvggl.Create(nvggl.CreateFlags{.ANTI_ALIAS, .STENCIL_STROKES, .DEBUG})
    victor_regular := nvg.CreateFontMem(vg, "victor-regular", #load("../res/victor-regular.ttf", []u8), false)
    // unifont := nvg.CreateFontMem(vg, "unifont", #load("../res/unifont.ttf", []u8), false)
    nvg.AddFallbackFontId(vg, victor_regular, victor_regular)
    app_base.vg = vg

    // 
    app.app_base = app_base

    tween_system_init()
    tweener_init(&app.tweener, 4)

    profile_init()

    time.stopwatch_start(&timer)

    _cursors_init()
    cursor_set(.Default)

    /* Application */
    // Load some shader libraries, systems would create shaders depending on these shader libs.
    dgl.shader_preprocess_add_lib("mixbox", #load("./shaders/libs/mixbox.glsl", string))

    app.brush_size = 5
    app.brush_color = {1,1,0,1}
    paint_init()
    paintcurve_init(&app.paintcurve)
    compose_engine_init()
}

application_release :: proc(app : ^Application) {
    /* Application */
    compose_engine_release()
    paint_release()
    paintcurve_release(&app.paintcurve)

    /* Base */
    tweener_release(&app.tweener)
    profile_release()

    nvggl.Destroy(app.vg)

    dgl.release()
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
    _CURSOR_DRAGGER = sdl.CreateSystemCursor(.SIZEALL)
}
@(private="file")
_cursors_release :: proc() {
    sdl.FreeCursor(_CURSOR_BRUSH)
    sdl.FreeCursor(_CURSOR_DRAGGER)
}

_app_update_mouse_position :: proc() {
    x,y : c.int
    sdl.GetMouseState(&x,&y)
    app.mouse_pos = Vec2{auto_cast x,auto_cast y}
}



// #Debug Config

DebugConfig :: struct {
    dirty_region, basic_info, brush_buffer : bool,
    paint_history : i32,
}
