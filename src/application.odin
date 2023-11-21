package main

import nvg "vendor:nanovg"
import sdl "vendor:sdl2"
import gl "vendor:OpenGL"
import nvggl "vendor:nanovg/gl"

import "core:time"
import "core:fmt"

Application :: struct {
    using app_base : ApplicationBase,
    tweener : Tweener,
    canvas : Canvas,
}

ApplicationBase :: struct {
    vg : ^nvg.Context,
    wnd : ^sdl.Window,

    window_size : Vec2i,
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
    app_base.wnd = sdl.CreateWindow("topo", 500, 30, 600,800, sdl.WindowFlags{.RESIZABLE, .OPENGL})

    app_base.gl_ctx = sdl.GL_CreateContext(app_base.wnd)
    assert(app_base.gl_ctx != nil, fmt.tprintf("Failed to create GLContext for window, because: {}.\n", sdl.GetError()))

    sdl.GL_SetSwapInterval(1)
    sdl.GL_MakeCurrent(app_base.wnd, app_base.gl_ctx)
    gl.load_up_to(3, 3, sdl.gl_set_proc_address)

    vg := nvggl.Create(nvggl.CreateFlags{.ANTI_ALIAS, .STENCIL_STROKES, .DEBUG})
    victor_regular := nvg.CreateFont(vg, "victor-regular", "./victor-regular.ttf")
    unifont := nvg.CreateFont(vg, "unifont", "./unifont.ttf")
    nvg.AddFallbackFontId(vg, victor_regular, unifont)
    app_base.vg = vg

    // 
    app.app_base = app_base

    tween_system_init()
    tweener_init(&app.tweener, 4)

    time.stopwatch_start(&timer)
}

application_release :: proc(app : ^Application) {
    tweener_release(&app.tweener)
    nvggl.Destroy(app.vg)
    sdl.DestroyWindow(app.wnd)
    sdl.Quit()
}