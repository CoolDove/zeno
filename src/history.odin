package main

import gl "vendor:OpenGL"

HistoryContext :: struct {
    canvas : ^Canvas,// Which canvas this context is bound to.
    undo, redo : [dynamic]ZenoCommand,
}

ZenoCommand :: union {
    ZmdModifyLayer,
}

ZenoCommandHandler :: struct {
    release : proc(zmd: ^ZenoCommand),
}

ZmdModifyLayer :: struct {
    layer : ^Layer,
    rect : Vec4,
    texture : u32,
}

history_init :: proc(history: ^HistoryContext, canvas: ^Canvas) {
    history.canvas = canvas
    history.undo = make([dynamic]ZenoCommand, 0, 512)
    history.redo = make([dynamic]ZenoCommand, 0, 64)
}
history_release :: proc(using history: ^HistoryContext) {
    delete(undo)
    delete(redo)
}

history_undo :: proc(using history: ^HistoryContext) {
    if len(history.undo) == 0 do return
    command := &history.undo[len(history.undo)-1]
    _zmd_undo(command)
    append(&history.redo, command^)
    pop(&history.undo)
}
history_redo :: proc(using history: ^HistoryContext) {
    if len(history.redo) == 0 do return
    command := &history.redo[len(history.redo)-1]
    _zmd_redo(command)
    append(&history.undo, command^)
    pop(&history.redo)
}

history_push :: proc(using history: ^HistoryContext, zmd : ZenoCommand) {
    append(&history.undo, zmd)
    for &zmd in history.redo do _zmd_release(&zmd)
    clear(&history.redo)
}

// ZenoCommand initializers.
zmd_modify_layer :: proc(layer: ^Layer, rect: Vec4) -> ZenoCommand {
    return {}
}

@(private="file")
_zmd_undo :: proc(zmd: ^ZenoCommand) {
    switch z in zmd {
    case ZmdModifyLayer:
    }
}
@(private="file")
_zmd_redo :: proc(zmd: ^ZenoCommand) {
    switch z in zmd {
    case ZmdModifyLayer:
    }
}
@(private="file")
_zmd_release :: proc(zmd: ^ZenoCommand) {
    switch z in zmd {
    case ZmdModifyLayer:
        gl.DeleteTextures(1, &z.texture)
    }
}
