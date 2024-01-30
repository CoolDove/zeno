package main


import "core:runtime"
import "core:log"

import gl "vendor:OpenGL"
import "dgl"

Canvas :: struct {
    width, height : i32,

    current_layer : i32,
    layers : [dynamic]Layer,

    compose : CanvasComposeData,
	_compose_dirty : bool,
    dirty_region : Vec4,// x,y(left-top) w,h

    history: HistoryContext,

	// buffer
	_image_buffer : []u8,
	_image_buffer_dirty : bool,

    // Camera
    offset : Vec2,

    scale : f32,
    using coord : ^Coordinate,

    // Buffers, left & right & spike is just random-meaningless naming.
    buffer_left : u32,// Used during composing.
    buffer_right : u32,// Used during composing.
    buffer_spike : u32,// Used during composing.
}

Layer :: struct {
    canvas: ^Canvas,
    tex : u32,
    opacity : f32,
    visible : bool,
    compose_type : ComposeType,
}

canvas_init :: proc {
    canvas_init_with_color,
    canvas_init_with_file,
}

canvas_init_with_file :: proc(canvas: ^Canvas, filename: string) -> bool {
    tex := dgl.texture_load_by_path(filename, false)
    if tex.id == 0 do return false
    canvas_add_layer(canvas, layer_create_with_texture(tex.id))
    _canvas_init(canvas, tex.size.x, tex.size.y)
    return true
}
canvas_init_with_color :: proc(canvas: ^Canvas, width,height: i32, color : Color32) {
    data := make_slice([]byte, 4 * width * height); defer delete(data)
    for i in 0..<(width * height) {
        for c in 0..<4 do data[cast(int)i*4+c] = color[c]
    }
    canvas_add_layer(canvas, layer_create_with_color(width,height, color))
    _canvas_init(canvas, width,height)
}

@(private="file")
_canvas_init :: proc(canvas: ^Canvas, width,height: i32) {
    canvas.width = width
    canvas.height = height
    canvas.scale = 1
    canvas.coord = &canvas_coord
    w,h :i32= auto_cast canvas.width, auto_cast canvas.height
    canvas.buffer_left = dgl.texture_create_empty(w,h)
    canvas.buffer_right = dgl.texture_create_empty(w,h)
    canvas.buffer_spike = dgl.texture_create_empty(w,h)
    compose_engine_init_canvas(canvas)
    compose_engine_compose_all(canvas)
    history_init(&canvas.history, canvas)

	canvas._image_buffer = make([]u8, width*height*4)
	canvas_image_buffer_mark_dirty(canvas)
}

canvas_release :: proc(using canvas: ^Canvas) {
	delete(_image_buffer)
    history_release(&canvas.history)
    compose_engine_release_canvas(canvas)
    for &l in layers do layer_destroy(&l)
    gl.DeleteTextures(1, &buffer_left)
    gl.DeleteTextures(1, &buffer_right)
    gl.DeleteTextures(1, &buffer_spike)
    canvas^= {}
}

canvas_get_image_buffer_to :: proc(using canvas: ^Canvas, data: rawptr) {
	size := cast(int)(width * height * 4)
	gl.BindTexture(gl.TEXTURE_2D, compose.compose_result)
	gl.GetTexImage(gl.TEXTURE_2D, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
}
canvas_get_image_buffer :: proc(using canvas: ^Canvas) -> []u8 {
	if _image_buffer_dirty {
		size := cast(int)(width * height * 4)
		if len(_image_buffer) == size {
			delete(_image_buffer)
			_image_buffer = make([]u8, size)
		}
		gl.BindTexture(gl.TEXTURE_2D, compose.compose_result)
		gl.GetTexImage(gl.TEXTURE_2D, 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(_image_buffer))
		ptr := cast(^runtime.Raw_Slice)&_image_buffer
		ptr.len = size

		_image_buffer_dirty = false
	}
	return _image_buffer
}
canvas_image_buffer_mark_dirty :: proc(using canvas: ^Canvas) {
	_image_buffer_dirty = true
}

canvas_compose_all :: proc(using canvas: ^Canvas) {
	if _compose_dirty {
		compose_engine_compose_all(canvas)
		_compose_dirty = false
	}
}
canvas_compose_mark_dirty :: proc(using canvas: ^Canvas) {
	_compose_dirty = true
}

// These buffers are used in compose engine.
canvas_get_clean_buffers :: proc(using canvas: ^Canvas, color: Vec4) -> (u32, u32, u32) {
    dgl.blit_clear(buffer_left, color, width,height)
    dgl.blit_clear(buffer_right, color, width,height)
    dgl.blit_clear(buffer_spike, color, width,height)
    return buffer_left, buffer_right, buffer_spike
}

// Canvas layer controlling
canvas_add_layer :: proc(using canvas: ^Canvas, layer : Layer) {
    append(&layers, layer)
    layers[len(layers)-1].canvas = canvas
}

// Layer impl
layer_create :: proc() -> Layer {
    return {}
}
layer_create_with_color :: proc(width, height : i32, color: Color32) -> (Layer, bool) #optional_ok {
    layer : Layer; _layer_default(&layer)
    layer.tex = dgl.texture_create_with_color(auto_cast width, auto_cast height, color)
    return layer, false
}
layer_create_with_texture :: proc(texture: u32) -> (Layer, bool) #optional_ok {
    layer : Layer; _layer_default(&layer)
    layer.tex = texture
    return layer, false
}
layer_destroy :: proc(using layer: ^Layer) {
    gl.DeleteTextures(1, &layer.tex)
    layer.tex = 0
}

@(private="file")
_layer_default :: proc(using layer: ^Layer) {
    layer.tex = 0
    layer.opacity = 1.0
    layer.visible = true
    layer.compose_type = .Default
}
