package main

import "core:fmt"
import gl "vendor:OpenGL"

import "dgl"

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
    x,y := rect.x,rect.y
    w,h := rect.z,rect.w
    buffer := dgl.texture_create_empty(cast(i32)w,cast(i32)h)

    canvas := layer.canvas
    cw,ch := cast(f32)canvas.width, cast(f32)canvas.height

    dgl.texture_copy(layer.tex, buffer, vec_f2i(Vec2{x,y}), {0,0}, cast(i32)w,cast(i32)h)

    zmd : ZmdModifyLayer
    zmd.layer = layer
    zmd.texture = buffer
    zmd.rect = rect

    return zmd
}

@(private="file")
_zmd_undo :: proc(zmd: ^ZenoCommand) {
    switch z in zmd {
    case ZmdModifyLayer:
        x,y :i32= cast(i32)z.rect.x, cast(i32)z.rect.y
        w,h :i32= cast(i32)z.rect.z, cast(i32)z.rect.w
        buffer := dgl.texture_create_empty(w,h)
        c := z.layer.canvas
        dgl.texture_copy(z.layer.tex, buffer, Vec2i{x,y}, {0,0}, w,h)
        dgl.texture_copy(z.texture, z.layer.tex, {0,0}, Vec2i{x,y}, w,h)
        gl.DeleteTextures(1, &z.texture)
        z.texture = buffer
    }
}
@(private="file")
_zmd_redo :: proc(zmd: ^ZenoCommand) {
    switch z in zmd {
    case ZmdModifyLayer:
        x,y :i32= cast(i32)z.rect.x, cast(i32)z.rect.y
        w,h :i32= cast(i32)z.rect.z, cast(i32)z.rect.w
        buffer := dgl.texture_create_empty(w,h)
        c := z.layer.canvas
        dgl.texture_copy(z.layer.tex, buffer, Vec2i{x,y}, {0,0}, w,h)
        dgl.texture_copy(z.texture, z.layer.tex, {0,0}, Vec2i{x,y}, w,h)
        gl.DeleteTextures(1, &z.texture)
        z.texture = buffer
    }
}
@(private="file")
_zmd_release :: proc(zmd: ^ZenoCommand) {
    switch z in zmd {
    case ZmdModifyLayer:
        gl.DeleteTextures(1, &z.texture)
    }
}
