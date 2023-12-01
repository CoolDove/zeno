package main

import "core:fmt"
import gl "vendor:OpenGL"

import "dgl"

SHADER_COMPOSE_DEFAULT : dgl.ShaderId
SHADER_COMPOSE_PIGMENT : dgl.ShaderId
@(private="file")
_PigmentComposeUniforms :: struct {
    main_texture, other_texture, mixbox_lut : dgl.UniformLocTexture,
}
@(private="file")
_pigment_compose_uniforms : _PigmentComposeUniforms

// This is stored in canvas.
CanvasComposeData :: struct {
    compose_result : u32,
    compose_above : u32,
    compose_below : u32,
}

ComposeType :: enum {
    Default, Pigment,
}

compose_engine_init :: proc() {
    shader_frag := dgl.shader_preprocess(_SHADER_COMPOSE_PIGMENT_FRAG); defer delete(shader_frag)
    SHADER_COMPOSE_DEFAULT = dgl.blit_make_blit_shader(shader_frag)

    SHADER_COMPOSE_PIGMENT = dgl.blit_make_blit_shader(shader_frag)
    dgl.uniform_load(&_pigment_compose_uniforms, SHADER_COMPOSE_PIGMENT)
}
compose_engine_release :: proc() {
    gl.DeleteProgram(SHADER_COMPOSE_DEFAULT)
    gl.DeleteProgram(SHADER_COMPOSE_PIGMENT)
}

compose_engine_init_canvas :: proc(using canvas: ^Canvas) {
    using compose, dgl
    w, h :int= auto_cast width, auto_cast height
    compose_result = texture_create_empty(w, h)
    compose_above = texture_create_empty(w, h)
    compose_below = texture_create_empty(w, h)
}
compose_engine_release_canvas :: proc(using canvas: ^Canvas) {
    using compose, dgl
    if compose_result != 0 do gl.DeleteTextures(3, &compose_result)
    compose = {}
}

compose_engine_compose_all :: proc(using canvas: ^Canvas) {
}
compose_engine_compose_dirty :: proc(using canvas: ^Canvas) {
}


@(private="file")
_SHADER_COMPOSE_PIGMENT_FRAG :string: `
#version 440 core
out vec4 FragColor;

layout(location = 0) in vec2 _uv;
layout(location = 1) in vec4 _color;

uniform sampler2D main_texture;
uniform sampler2D other_texture;
uniform sampler2D mixbox_lut;

#include "mixbox"

void main() {
    vec4 src = texture(main_texture, _uv);
    vec4 dst = texture(other_texture, _uv);
    FragColor = mixbox_lerp(dst, src, src.a);
}
`